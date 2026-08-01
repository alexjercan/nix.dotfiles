#!/usr/bin/env bash
# Skill-suite conformance gate.
#
# Enforces what tatr cannot see. tatr owns the TASK/SPIKE/DECISION/REVIEW/RETRO
# record schemas; this owns the SKILL texts themselves - their context budgets,
# their conditional-reference graph, and their invocation policy.
#
#   bash home/modules/agents/skills/check.sh
#
# Deliberately STRUCTURAL and cheap: every rule here is a property of the files
# a static read can settle in a second. It does not assert that a reference
# still STATES the rule it exists to carry - that was the fixture suite, and it
# cost more to iterate on than it caught. Whether a skill's prose says the
# right thing is a review question now, not a gate question.
#
# Findings print as "<scope>: <rule>: <detail>". Exit 0 clean, 1 with findings.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The flow family. `today` ships from this directory too but is a tool skill,
# not part of the flow cycle, so it pays no share of the description budget.
# These are CLASSIFICATION lists only - the set of skills to check is read off
# disk below, so a directory nobody remembered to list is still checked, and is
# reported as unclassified rather than silently skipped.
FLOW_FAMILY=(flow plan work review spike compound sprout)
TOOL_SKILLS=(today)

# Budgets, in words. Categories came from task 20260730-142052; compact caps
# tightened in task 20260731-133122.
BUDGET_DESCRIPTIONS_TOTAL=200   # every flow-family description, summed
BUDGET_DESCRIPTION_EACH=30      # one description
BUDGET_ROUTER_BODY=300          # flow/SKILL.md body
BUDGET_PHASE_BODY=400           # every other SKILL.md body
BUDGET_REFERENCE=600            # one conditional reference
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
IMPLICIT=(flow plan work review spike compound today)

# Every rule this gate can report. Declared rather than grepped, because two of
# them (`router-body-budget`, `phase-body-budget`) are chosen at runtime and no
# static scan can see them.
RULES=(
  no-skills-found unclassified-skill missing-skill bad-frontmatter
  typographic-character
  description-budget descriptions-total-budget
  router-body-budget phase-body-budget reference-budget output-contract-budget
  broken-reference unreachable-reference empty-pointer-condition
  reference-too-deep
  bad-invocation-policy missing-openai-metadata bad-openai-metadata
  duplicated-paragraph
  missing-output-contract stale-rule-inventory
  direct-state-edit
)

if [ "${1-}" = --rules ]; then printf '%s\n' "${RULES[@]}"; exit 0; fi

# An unknown flag must not print `skills: clean` and exit 0, which reads
# exactly like a passing run.
if [ "$#" -gt 0 ]; then
  printf 'unknown argument: %s (expected --rules)\n' "$1" >&2
  exit 2
fi

findings=0
fail() { printf '%s: %s: %s\n' "$1" "$2" "$3" >&2; findings=$((findings + 1)); }

# --- helpers ----------------------------------------------------------------

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
# Every directory holding a SKILL.md is a skill, whether or not anyone listed
# it.
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
# A MISSING section counts zero words, so the budget alone would wave it
# through - silence reading as compliance is the one failure a budget check
# cannot catch on its own.
#
# Scoped to the PHASES `flow` dispatches. `sprout` sits in the flow family for
# its budgets but is a worktree CLI, not a phase: it returns nothing to the
# orchestrator, so it owes no handoff contract.
for skill in "${FLOW_FAMILY[@]}"; do
  [ "$skill" = sprout ] && continue
  f="$root/$skill/SKILL.md"
  [ -f "$f" ] || continue
  if ! grep -qx '## Output' "$f"; then
    fail "$skill/SKILL.md" missing-output-contract "no '## Output' section"
    continue
  fi
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

# --- 8. direct state edits --------------------------------------------------
# `tatr flow` is the only writer of a task's lifecycle markers. Prose telling
# the agent to type one in by hand reintroduces exactly the drift that
# transactional command exists to remove. The content fixtures enumerate FILES,
# so an imperative added to a file no fixture names is invisible to them; this
# rule quantifies over the family, which is what the criterion actually claims.
#
# Scoped to a CLAUSE, not a file and not a line. A marker named in one clause
# and an edit verb in another is description followed by a separate
# instruction, and file-wide matching would flag every reference that explains
# what the markers mean. Clause boundaries are sentence punctuation, the
# semicolon, a blank line, and the start of a heading or list item - markdown
# bullets and headings carry no terminal punctuation, so splitting on `. `
# alone collapses a whole block into one pseudo-clause and reports the wrong
# text. Lines are joined before splitting, because a marker and its verb
# landing on either side of a line break is the realistic shape, not the
# exception (`line-breaks-are-load-bearing`).
#
# A clause is a violation when it names a marker AND an edit verb, is NOT
# attributed to the tool, is NOT a prohibition, and shows AGENCY - an
# imperative-initial verb, or an explicit by-hand phrase. Agency is what
# separates "Set FLOW STEP: DONE yourself" from "`tatr flow` writes FLOW STEP".
# Location words like "in TASK.md" are NOT agency: they say where the marker
# lives, not who typed it.
#
# One awk pass rather than a tr/sed/grep chain: it is the difference between
# ~1.1s and ~0.1s over the tree, and it avoids `sed 's/x/\n/'`, whose newline
# replacement is a GNU extension that silently yields a literal `n` on BSD -
# which would turn this rule into a whole-file matcher instead of an error.
#
# A bare `STATUS:` is deliberately NOT a marker - DECISION.md and SPIKE.md both
# carry their own `- STATUS:` field, and flagging those would make the rule
# unusable. Only the flow lifecycle's own values count.

direct_state_edit_hits() {
  awk '
    BEGIN {
      EV = "(set|sets|write|writes|writing|change|changes|edit|edits|editing|type|types|put|puts|mark|marks|flip|flips|update|updates|add|adds|append|appends|record|records|replace|replaces|insert|inserts|bump|bumps|overwrite|overwrites|fill|fills|toggle|toggles|correct|corrects)"
      # The BARE form is the imperative one. "sets FLOW STEP" is a third
      # person describing the tool; "set FLOW STEP" is an order to the reader,
      # and that inflection is the whole difference between the two.
      EVB = "(set|write|change|edit|type|put|mark|flip|update|add|append|record|replace|insert|bump|overwrite|fill|toggle|correct)"
      MARKER = "(flow step|plan status|status: *(open|in_progress|closed))"
      HAND = "(by hand|hand-edit|yourself|manually)"
    }
    function judge(s,   t) {
      sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
      if (s == "") return
      t = " " tolower(s) " "
      gsub(/`/, "", t)
      if (t !~ MARKER) return
      if (t !~ "[^a-z]" EV "[^a-z]") return
      # Attributed to the tool: `tatr <verb>` as the clause subject, or named
      # as the instrument. Anchoring matters - a bare `tatr` anywhere would
      # exempt "If `tatr flow` is unavailable, set FLOW STEP by hand", which is
      # the single likeliest real violation.
      if (t ~ "(^ |, )tatr [a-z-]+( [^ ]+){0,5} " EV "[^a-z]") return
      if (t ~ "(with|via|using|through) tatr [a-z-]+") return
      # A negated edit verb forbids the edit rather than ordering it.
      if (t ~ "(do not|does not|never|dont|cannot|not) ([a-z-]+ ){0,3}" EV "[^a-z]") return
      # Agency: an imperative bare verb at the head of the clause or chained
      # onto one, or an explicit by-hand phrase. "directly" counts only
      # adjacent to the verb - at a distance it times the action rather than
      # naming who performed it.
      if (t ~ "(^ |, |and |then |or )" EVB "[^a-z]" || t ~ HAND ||
          t ~ EV "[a-z]* ([a-z]+ ){0,2}directly")
        print s
    }
    function flush() { judge(seg); seg = "" }
    {
      line = $0
      if (line ~ /^[ \t]*$/) { flush(); next }
      if (line ~ /^[ \t]*(#+[ \t]|[-*][ \t]|[0-9]+\.[ \t])/) flush()
      sub(/^[ \t]*(#+[ \t]+|[-*][ \t]+|[0-9]+\.[ \t]+)/, "", line)
      sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
      seg = (seg == "" ? line : seg " " line)
      while (match(seg, /[.!?;] /)) {
        judge(substr(seg, 1, RSTART))
        seg = substr(seg, RSTART + RLENGTH)
      }
    }
    END { flush() }
  ' "$1"
}

for skill in "${FLOW_FAMILY[@]}"; do
  [ -d "$root/$skill" ] || continue
  while IFS= read -r f; do
    rel="${f#"$root"/}"
    # An unreadable file must not read as a clean one. The old form wrapped the
    # whole pipeline in `|| true`, so a missing file produced no hits and
    # passed silently.
    if [ ! -r "$f" ]; then
      fail "$rel" direct-state-edit "not readable, so the rule cannot clear it"
      continue
    fi
    # Not head-truncated: the count is reported, so a file with several
    # offending clauses cannot read as a single slip.
    hits="$(direct_state_edit_hits "$f")"
    [ -n "$hits" ] || continue
    n="$(printf '%s\n' "$hits" | grep -c .)"
    fail "$rel" direct-state-edit \
      "$n clause(s) order a lifecycle marker written by hand, first: $(printf '%s' "$hits" | head -1 | cut -c1-100)"
  done < <(find "$root/$skill" -name '*.md' | sort)
done

# --- 9. the rule inventory is honest ---------------------------------------
# `RULES` and `--rules` claim to be the complete set this gate can report.
# Without the removed self-test, nothing checked that claim, and a stale
# inventory is worse than none: a rule deleted from the code but left in the
# list reads as coverage that no longer exists.
#
# This is a SPELLING check, not a falsifiability one - it proves each declared
# slug still appears in a reporting call, not that anything can trip it. The
# two budget rules chosen at runtime are the documented exceptions.
#
# Comment lines are stripped first, and the messages below deliberately avoid
# the words the extractor matches on - otherwise this rule reads its own
# finding text as a rule name and reports a slug nobody declared.
RUNTIME_SELECTED=(router-body-budget phase-body-budget)
emitted="$(grep -v '^[[:space:]]*#' "$0" |
  sed -e ':a' -e '/\\$/{N;s/\\\n[[:space:]]*/ /;ta}' |
  grep -ohE '(^|[^_[:alnum:]])fail ("[^"]*"|[^ ]+) [a-z][a-z0-9-]*' |
  awk '{print $NF}' | sort -u)"
for rule in "${RULES[@]}"; do
  skip=no
  for r in "${RUNTIME_SELECTED[@]}"; do [ "$r" = "$rule" ] && skip=yes; done
  [ "$skip" = yes ] && continue
  printf '%s\n' "$emitted" | grep -qx "$rule" ||
    fail check.sh stale-rule-inventory "$rule is declared in RULES but nothing reports it"
done
while IFS= read -r rule; do
  [ -n "$rule" ] || continue
  found=no
  for r in "${RULES[@]}"; do [ "$r" = "$rule" ] && found=yes; done
  [ "$found" = yes ] ||
    fail check.sh stale-rule-inventory "$rule is reported but missing from RULES"
done <<< "$emitted"

if [ "$findings" -gt 0 ]; then
  printf '\n%d finding(s)\n' "$findings" >&2
  exit 1
fi
printf 'skills: clean (%d skills, %d rules, %d flow-family description words)\n' \
  "${#ALL_SKILLS[@]}" "${#RULES[@]}" "$desc_total"
