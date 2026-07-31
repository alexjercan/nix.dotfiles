#!/usr/bin/env bash
# Skill-suite conformance gate.
#
# Enforces what tatr cannot see. tatr owns the TASK/SPIKE/DECISION/REVIEW/RETRO
# record schemas; this owns the SKILL texts themselves - their context budgets,
# their conditional-reference graph, their invocation policy, and their declared
# output contracts.
#
#   bash home/modules/agents/skills/check.sh
#
# Findings print as "<scope>: <rule>: <detail>". Exit 0 clean, 1 with findings.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# `--self-test` proves the gate can fail: it sabotages one rule at a time in a
# scratch copy and asserts check.sh reports it. A gate nothing can trip is not
# a gate.
if [ "${1-}" = --self-test ]; then
  exec bash "$root/fixtures/selftest.sh" "$root"
fi

# The flow family. `today` ships from this directory too but is a tool skill,
# not part of the flow cycle, so it pays no share of the description budget.
# These are CLASSIFICATION lists only - the set of skills to check is read off
# disk below, so a directory nobody remembered to list is still checked, and is
# reported as unclassified rather than silently skipped.
FLOW_FAMILY=(flow plan work review spike compound lessons sprout)
TOOL_SKILLS=(today)

# Budgets, in words. Sourced from tasks/20260730-142052/SPIKE.md, the budget
# table under `## Recommendation`.
BUDGET_DESCRIPTIONS_TOTAL=200   # every flow-family description, summed
BUDGET_DESCRIPTION_EACH=30      # one description
BUDGET_ROUTER_BODY=500          # flow/SKILL.md body
BUDGET_PHASE_BODY=800           # every other SKILL.md body
BUDGET_REFERENCE=1000           # one conditional reference
BUDGET_OUTPUT_CONTRACT=150      # a phase's `## Output` contract, which is also
                                # its handoff back to the orchestrator

# Skills that must stay model-invocable: `flow` dispatches them by name, or they
# must fire implicitly on a matching request. Everything else is explicit-only
# and declares `disable-model-invocation: true`.
#
# Claude Code honours that key (it appears in the shipped binary). Whether codex
# honours it is UNVERIFIED - its binary is packed and the key is not greppable -
# so what this check really enforces is that the policy is declared ONCE, in the
# SKILL.md both tools read, rather than diverging into two places. If codex turns
# out to ignore it, the fix is one frontmatter key, not two policies.
IMPLICIT=(flow plan work review spike compound lessons today)

# Every rule this gate can report. Declared rather than grepped, because two of
# them (`router-body-budget`, `phase-body-budget`) are chosen at runtime and no
# static scan can see them. `--self-test` checks BOTH directions: that every
# literal slug in this file is declared here, and that every declared slug has
# a sabotage case proving it can fire.
RULES=(
  no-skills-found unclassified-skill missing-skill bad-frontmatter
  typographic-character
  description-budget descriptions-total-budget
  router-body-budget phase-body-budget reference-budget output-contract-budget
  broken-reference unreachable-reference empty-pointer-condition
  no-disclosure-fixture reference-too-deep
  bad-invocation-policy missing-openai-metadata bad-openai-metadata
  duplicated-paragraph
  not-loadable condition-misses-branch leaks-on-unrelated-branch bad-fixture
  wrong-policy description-misses-trigger codex-parity
  missing-output-contract missing-output-limit missing-output-element
  missing-content-element forbidden-content-element
)

if [ "${1-}" = --rules ]; then printf '%s\n' "${RULES[@]}"; exit 0; fi

# `--fixture <name>` runs ONE fixture case and nothing else, so a task's
# Definition of Done can name a single criterion as a runnable proof. The bare
# gate prints only findings, so a passing case is invisible to it and could
# never back a per-criterion `cmd:`.
fixture_filter=
if [ "${1-}" = --fixture ]; then
  if [ "$#" -ne 2 ] || [ -z "${2-}" ]; then
    printf '%s\n' 'usage: check.sh --fixture <case-name>' >&2
    exit 2
  fi
  fixture_filter="$2"
  set --
fi

# A typo like `--selftest` must not print `skills: clean` and exit 0, which
# reads exactly like a passing self-test.
if [ "$#" -gt 0 ]; then
  printf 'unknown argument: %s (expected --self-test, --rules or --fixture)\n' "$1" >&2
  exit 2
fi

findings=0
fail() { printf '%s: %s: %s\n' "$1" "$2" "$3" >&2; findings=$((findings + 1)); }

# --- helpers ----------------------------------------------------------------
# Defined before the `--fixture` dispatch below, because the fixture runner
# calls into them and that path skips the rest of the gate.

# Body = everything after the closing --- of the frontmatter block.
body_of() { awk 'NR==1&&$0=="---"{fm=1;next} fm==1&&$0=="---"{fm=2;next} fm==2' "$1"; }
frontmatter_of() { awk 'NR==1&&$0=="---"{fm=1;next} fm==1&&$0=="---"{exit} fm==1' "$1"; }
count_words() { wc -w < "$1" | tr -d ' '; }
count_words_str() { printf '%s' "$1" | wc -w | tr -d ' '; }
fm_value() { frontmatter_of "$1" | sed -n "s/^$2: *//p" | head -1; }

# A conditional reference is an ARROW POINTER: some condition text, then `->`,
# then a backticked lowercase `<name>.md` on the same line. A bare mention of
# another skill's file (e.g. "flow's `epic.md`") is prose, not a pointer, and
# deliberately does not count - that is what keeps cross-skill vocabulary legal
# while still proving every LOADABLE branch is guarded by a stated condition.
pointer_lines() { grep -nE -- '->[^`]*`[a-z][a-z0-9-]*\.md`' "$1" 2>/dev/null; }
pointer_targets() {
  pointer_lines "$1" | grep -oE '`[a-z][a-z0-9-]*\.md`' | tr -d '`' | sort -u
}
# The condition guarding a pointer: everything on its line before the arrow.
pointer_condition() {
  pointer_lines "$1" | grep -F "\`$2\`" | sed 's/^[0-9]*://; s/->.*//' |
    tr 'A-Z' 'a-z' | tr -s ' '
}
# The body of one `## <heading>` section, up to the next `## `. A leading step
# number is stripped before comparing, so `## 5. Route the result` is found by
# `Route the result` and renumbering a workflow does not silently orphan a
# fixture that named the step by its title.
# Headings inside a fenced block belong to an ILLUSTRATION, not to the file's
# own structure. Without the fence flag a content case can be satisfied by the
# template a reference happens to show rather than by the rule it states.
section_of() {
  awk -v want="$2" '
    /^```/ { fence = !fence; if (s) print; next }
    !fence && /^## / {
      h = substr($0, 4); sub(/^[0-9]+\. */, "", h); s = (h == want); next
    }
    s
  ' "$1"
}

# A single named case runs the fixture harness alone: the surrounding rule
# sections would report findings that have nothing to do with the criterion
# being proved, and a proof that goes red for an unrelated reason is not a
# proof of anything.
if [ -n "$fixture_filter" ]; then
  if [ ! -f "$root/fixtures/run.sh" ]; then
    printf 'no fixture runner at %s\n' "$root/fixtures/run.sh" >&2
    exit 2
  fi
  # shellcheck source=fixtures/run.sh
  . "$root/fixtures/run.sh"
  run_fixtures "$fixture_filter"
  if [ "$fixtures_matched" -eq 0 ]; then
    printf 'no fixture case named %s under %s\n' "$fixture_filter" "$root/fixtures" >&2
    exit 2
  fi
  if [ "$findings" -gt 0 ]; then
    printf '\nfixture %s: %d finding(s)\n' "$fixture_filter" "$findings" >&2
    exit 1
  fi
  printf 'fixture %s: ok (%d case(s))\n' "$fixture_filter" "$fixtures_matched"
  exit 0
fi

# Every directory holding a SKILL.md is a skill, whether or not anyone listed
# it. `fixtures/` has no SKILL.md and is correctly not one.
ALL_SKILLS=()
while IFS= read -r f; do
  ALL_SKILLS+=("$(basename "$(dirname "$f")")")
done < <(find "$root" -mindepth 2 -maxdepth 2 -name SKILL.md | sort)
[ "${#ALL_SKILLS[@]}" -gt 0 ] || fail skills no-skills-found "no */SKILL.md under $root"

# A skill in neither classification list has no budget and no invocation
# policy, so it would be checked against nothing. That is the drift a
# hardcoded set hid.
for skill in "${ALL_SKILLS[@]}"; do
  classified=no
  for s in "${FLOW_FAMILY[@]}" "${TOOL_SKILLS[@]}"; do
    [ "$s" = "$skill" ] && classified=yes
  done
  [ "$classified" = yes ] || fail "$skill" unclassified-skill \
    "in neither FLOW_FAMILY nor TOOL_SKILLS in check.sh"
done

# A classification entry with no directory is a stale list, not a missing skill.
for s in "${FLOW_FAMILY[@]}" "${TOOL_SKILLS[@]}"; do
  [ -d "$root/$s" ] || fail "$s" missing-skill "listed in check.sh but has no directory"
done

# --- 1. frontmatter ---------------------------------------------------------

for skill in "${ALL_SKILLS[@]}"; do
  f="$root/$skill/SKILL.md"
  scope="$skill/SKILL.md"
  if [ ! -f "$f" ]; then fail "$scope" missing-skill "no SKILL.md"; continue; fi
  head -1 "$f" | grep -qx -- '---' || fail "$scope" bad-frontmatter "does not start with ---"
  name="$(fm_value "$f" name)"
  desc="$(fm_value "$f" description)"
  [ "$name" = "$skill" ] || fail "$scope" bad-frontmatter "name is '$name', expected '$skill'"
  [ -n "$desc" ] || fail "$scope" bad-frontmatter "no description"
done

# --- 2. typographic characters ----------------------------------------------
# The global AGENTS.md writing rule: plain programmer syntax only - `-`, `--`,
# `...`, `->`, straight quotes. This targets the SUBSTITUTED glyphs, not every
# non-ASCII byte: a skill may legitimately quote real data that contains one
# (today/SKILL.md shows a habit named with an emoji), and flagging that would
# push the rule into rewriting the CLI's own output.
TYPOGRAPHIC='\xe2\x80\x93|\xe2\x80\x94|\xe2\x80\x98|\xe2\x80\x99|\xe2\x80\x9c|\xe2\x80\x9d|\xe2\x80\xa6|\xe2\x86\x90|\xe2\x86\x92|\xe2\x87\x92|\xe2\x80\xa2|\xc2\xa0|\xc3\x97'

while IFS= read -r f; do
  rel="${f#"$root"/}"
  # No `if` around this: a pipeline ending in `head` always exits 0, so the
  # emptiness of the capture is the only real test.
  line="$(LC_ALL=C grep -nP "$TYPOGRAPHIC" "$f" 2>/dev/null | head -1)"
  [ -n "$line" ] && fail "$rel" typographic-character \
    "en/em dash, smart quote, ellipsis, arrow, bullet, nbsp or times sign at line ${line%%:*}"
done < <(find "$root" \( -name '*.md' -o -name '*.sh' -o -name '*.yaml' \) | sort)

# --- 3. word budgets --------------------------------------------------------

desc_total=0
for skill in "${FLOW_FAMILY[@]}"; do
  f="$root/$skill/SKILL.md"
  [ -f "$f" ] || continue
  n="$(count_words_str "$(fm_value "$f" description)")"
  desc_total=$((desc_total + n))
  [ "$n" -le "$BUDGET_DESCRIPTION_EACH" ] ||
    fail "$skill/SKILL.md" description-budget "$n words > $BUDGET_DESCRIPTION_EACH"
done
[ "$desc_total" -le "$BUDGET_DESCRIPTIONS_TOTAL" ] ||
  fail "flow-family" descriptions-total-budget "$desc_total words > $BUDGET_DESCRIPTIONS_TOTAL"

for skill in "${ALL_SKILLS[@]}"; do
  f="$root/$skill/SKILL.md"
  [ -f "$f" ] || continue
  tmp="$(mktemp)"; body_of "$f" > "$tmp"; n="$(count_words "$tmp")"; rm -f "$tmp"
  if [ "$skill" = flow ]; then limit=$BUDGET_ROUTER_BODY; rule=router-body-budget
  else limit=$BUDGET_PHASE_BODY; rule=phase-body-budget; fi
  [ "$n" -le "$limit" ] || fail "$skill/SKILL.md" "$rule" "$n body words > $limit"
done

while IFS= read -r f; do
  rel="${f#"$root"/}"
  n="$(count_words "$f")"
  [ "$n" -le "$BUDGET_REFERENCE" ] || fail "$rel" reference-budget "$n words > $BUDGET_REFERENCE"
done < <(find "$root" -mindepth 2 -maxdepth 2 -name '*.md' ! -name SKILL.md | sort)

# The `## Output` section is BOTH the user-facing report contract and the
# handoff a phase returns to `flow`, so one budget covers both. A contract
# longer than the report it governs is not a contract.
for skill in "${FLOW_FAMILY[@]}"; do
  f="$root/$skill/SKILL.md"
  [ -f "$f" ] || continue
  n="$(awk '/^## Output$/{o=1;next} /^## /{o=0} o' "$f" | wc -w | tr -d ' ')"
  [ "$n" -le "$BUDGET_OUTPUT_CONTRACT" ] ||
    fail "$skill/SKILL.md" output-contract-budget "$n words > $BUDGET_OUTPUT_CONTRACT"
done

# --- 4. reference graph: resolvable, reachable, one level deep --------------

for skill in "${ALL_SKILLS[@]}"; do
  d="$root/$skill"
  [ -d "$d" ] || continue

  reachable=""
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    if [ -f "$d/$ref" ]; then reachable="$reachable $ref"
    else fail "$skill/SKILL.md" broken-reference "-> $ref does not exist"; fi
  done < <(pointer_targets "$d/SKILL.md")

  # A reference file with no pointer to it is deployed and never read.
  while IFS= read -r f; do
    b="$(basename "$f")"
    case " $reachable " in *" $b "*) ;; *)
      fail "$skill/$b" unreachable-reference "no conditional pointer from SKILL.md" ;;
    esac
  done < <(find "$d" -maxdepth 1 -name '*.md' ! -name SKILL.md | sort)

  # A pointer whose condition text is empty - usually because it wrapped onto
  # the previous line - states no condition at all, so nothing distinguishes
  # its branch from any other.
  for ref in $reachable; do
    cond="$(pointer_condition "$d/SKILL.md" "$ref" | tr -d '[:space:]-')"
    [ -n "$cond" ] || fail "$skill/SKILL.md" empty-pointer-condition \
      "-> $ref has no condition text before the arrow"
  done

  # Every reachable reference needs a disclosure fixture naming it, or the
  # condition checks above are only as good as whoever remembered to write one.
  # Scoped to THIS skill: reference basenames are generic (`proofs.md`,
  # `bug.md`, `rounds.md`), so a global bag of names would let one skill's
  # fixture vouch for another skill's file - and a falsely-covered reference
  # then also escapes condition-misses-branch and leaks-on-unrelated-branch,
  # which is the entire guarantee this rule exists to provide.
  skill_loads="$(awk -v s="$skill" '
      /^skill: /  { k = $2 }
      /^loads: /  { if (k == s) { sub(/^loads: */, ""); print } }
    ' "$root"/fixtures/disclosure/*.fixture 2>/dev/null | tr ' ' '\n' | sort -u)"
  for ref in $reachable; do
    covered=no
    while IFS= read -r loaded; do
      [ "$loaded" = "$ref" ] && covered=yes
    done <<< "$skill_loads"
    [ "$covered" = yes ] || fail "$skill/$ref" no-disclosure-fixture \
      "no fixtures/disclosure case for $skill names it in loads:"
  done

  # One level deep: a reference may not point at another file to load.
  for ref in $reachable; do
    while IFS= read -r nested; do
      [ -n "$nested" ] || continue
      [ "$nested" = "$ref" ] && continue
      [ -f "$d/$nested" ] &&
        fail "$skill/$ref" reference-too-deep "-> $nested; references are one level deep"
    done < <(pointer_targets "$d/$ref")
  done
done

# --- 5. invocation policy ---------------------------------------------------

for skill in "${ALL_SKILLS[@]}"; do
  f="$root/$skill/SKILL.md"
  [ -f "$f" ] || continue
  disabled="$(fm_value "$f" disable-model-invocation)"
  want_implicit=no
  for s in "${IMPLICIT[@]}"; do [ "$s" = "$skill" ] && want_implicit=yes; done
  if [ "$want_implicit" = yes ] && [ "$disabled" = true ]; then
    fail "$skill/SKILL.md" bad-invocation-policy \
      "must stay model-invocable but sets disable-model-invocation"
  fi
  if [ "$want_implicit" = no ] && [ "$disabled" != true ]; then
    fail "$skill/SKILL.md" bad-invocation-policy \
      "explicit-only skill must set 'disable-model-invocation: true'"
  fi
done

# --- 6. codex metadata ------------------------------------------------------

for skill in "${ALL_SKILLS[@]}"; do
  y="$root/$skill/agents/openai.yaml"
  [ -f "$y" ] || { fail "$skill" missing-openai-metadata "no agents/openai.yaml"; continue; }
  for key in display_name short_description default_prompt; do
    grep -q "^  $key:" "$y" || fail "$skill/agents/openai.yaml" bad-openai-metadata "no $key"
  done
done

# --- 7. duplicated paragraphs ----------------------------------------------
# A rule owned by a tool or by one skill must not be restated in another. Any
# prose paragraph of 12+ words appearing verbatim in two files is drift.

paragraphs="$(mktemp)"
while IFS= read -r f; do
  rel="${f#"$root"/}"
  awk -v rel="$rel" '
    /^```/ { fence = !fence; next }
    fence { next }
    NF == 0 { if (p != "") print rel "\t" p; p = ""; next }
    {
      line = $0
      sub(/^[ \t]*([-*]|[0-9]+\.)[ \t]+/, "", line)
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      p = (p == "" ? line : p " " line)
    }
    END { if (p != "") print rel "\t" p }
  ' "$f"
done < <(find "$root" -name '*.md' | sort) |
  awk -F'\t' '{ if (split($2, w, " ") >= 12) print }' |
  sort -t"$(printf '\t')" -k2 > "$paragraphs"

while IFS= read -r dup; do
  [ -n "$dup" ] && fail "${dup%%|*}" duplicated-paragraph "${dup#*|}"
done < <(awk -F'\t' '
  $2 == prev && $1 != prevfile { print prevfile " and " $1 "|" substr($2, 1, 70) }
  { prev = $2; prevfile = $1 }
' "$paragraphs")
rm -f "$paragraphs"

# --- 8. fixtures ------------------------------------------------------------

if [ -f "$root/fixtures/run.sh" ]; then
  # shellcheck source=fixtures/run.sh
  . "$root/fixtures/run.sh"
  run_fixtures
fi

if [ "$findings" -gt 0 ]; then
  printf '\n%d finding(s)\n' "$findings" >&2
  exit 1
fi
printf 'skills: clean (%d skills, %d flow-family description words)\n' \
  "${#ALL_SKILLS[@]}" "$desc_total"
