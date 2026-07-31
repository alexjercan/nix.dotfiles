#!/usr/bin/env bash
# Negative tests for check.sh: `bash check.sh --self-test`.
#
# A conformance gate that cannot fail proves nothing. Each case copies the
# skills tree to a scratch dir, breaks ONE thing, and asserts that check.sh
# reports THAT rule and exits non-zero. A rule with no case here is unproven.
set -uo pipefail

selftest_root="$1"
failures=0
cases=0
proven=()

# Runs check.sh over a sabotaged copy and asserts the expected rule fires.
# $1 = case name, $2 = expected rule slug, $3.. = shell to run inside the copy.
expect_rule() {
  local name="$1" rule="$2"; shift 2
  local tmp out status
  cases=$((cases + 1))
  tmp="$(mktemp -d)"
  cp -r "$selftest_root/." "$tmp/"
  ( cd "$tmp" && eval "$*" ) || {
    printf 'self-test %s: SABOTAGE FAILED to apply\n' "$name" >&2
    failures=$((failures + 1)); rm -rf "$tmp"; return
  }
  out="$(bash "$tmp/check.sh" 2>&1)"; status=$?
  rm -rf "$tmp"
  if [ "$status" -eq 0 ]; then
    printf 'self-test %s: check.sh PASSED a tree that should fail (%s)\n' "$name" "$rule" >&2
    failures=$((failures + 1)); return
  fi
  case "$out" in
    *"$rule"*) proven+=("$rule") ;;
    *) printf 'self-test %s: expected rule %s, got:\n%s\n' "$name" "$rule" "$out" >&2
       failures=$((failures + 1)) ;;
  esac
}

expect_rule descriptions-total descriptions-total-budget \
  "sed -i 's|^description: Drive one goal|description: $(printf 'padding %.0s' $(seq 60))Drive one goal|' flow/SKILL.md"

expect_rule router-body router-body-budget \
  "printf '%s\n' \$(printf 'filler %.0s' \$(seq 400)) >> flow/SKILL.md"

expect_rule phase-body phase-body-budget \
  "printf '%s\n' \$(printf 'filler %.0s' \$(seq 900)) >> work/SKILL.md"

expect_rule reference-size reference-budget \
  "printf '%s\n' \$(printf 'filler %.0s' \$(seq 1100)) >> work/bug.md"

expect_rule typographic typographic-character \
  "printf 'an em dash \342\200\224 here\n' >> work/bug.md"

expect_rule bad-name bad-frontmatter \
  "sed -i 's/^name: work$/name: wrok/' work/SKILL.md"

expect_rule broken-pointer broken-reference \
  "sed -i 's|-> \`bug.md\`|-> \`nosuchfile.md\`|' work/SKILL.md"

expect_rule orphan-reference unreachable-reference \
  "cp work/bug.md work/orphan.md"

expect_rule nested-reference reference-too-deep \
  "printf 'deeper detail -> \`verify.md\`\n' >> work/bug.md"

expect_rule implicit-disabled bad-invocation-policy \
  "sed -i '3a disable-model-invocation: true' work/SKILL.md"

expect_rule explicit-enabled bad-invocation-policy \
  "sed -i '/^disable-model-invocation: true$/d' sprout/SKILL.md"

expect_rule missing-codex-metadata missing-openai-metadata \
  "rm -f review/agents/openai.yaml"

expect_rule incomplete-codex-metadata bad-openai-metadata \
  "sed -i '/default_prompt/d' review/agents/openai.yaml"

expect_rule copied-paragraph duplicated-paragraph \
  "printf '\n' >> work/bug.md; sed -n '/^The reviewer.s job is judgment/,/^\$/p' review/SKILL.md >> work/bug.md"

expect_rule disclosure-leak leaks-on-unrelated-branch \
  "sed -i 's|- the task is a bug, crash, regression or falsification -> \`bug.md\`|- the review returned a verdict, or the task is a bug -> \`bug.md\`|' work/SKILL.md"

expect_rule disclosure-unguarded not-loadable \
  "sed -i '/-> \`verify.md\`/d' work/SKILL.md; rm -f work/verify.md"

expect_rule invocation-trigger description-misses-trigger \
  "sed -i 's|^description: Research a fuzzy question|description: Research a question|' spike/SKILL.md"

# 140 filler words INSIDE the Output section: enough to blow the 150-word
# contract budget without also blowing the 800-word body budget, so the case
# proves this rule rather than piggybacking on another.
expect_rule output-contract-size output-contract-budget \
  "sed -i \"/^## Output\$/a \$(printf 'filler %.0s' \$(seq 140))\" work/SKILL.md"

expect_rule output-contract-missing missing-output-contract \
  "sed -i 's|^## Output\$|## Reporting|' work/SKILL.md"

expect_rule output-limit-missing missing-output-limit \
  "sed -i 's|150 words or|lots of words or|' work/SKILL.md"

expect_rule output-element-missing missing-output-element \
  "sed -i 's|^Worktree path, branch, task ID, one-line summary, proof results|A summary|' work/SKILL.md"

expect_rule description-size description-budget \
  "sed -i 's|^description: Research a fuzzy question|description: Research one single solitary particular fuzzy uncertain undecided open unresolved question|' spike/SKILL.md"

expect_rule missing-directory missing-skill \
  "rm -rf spike"

expect_rule no-frontmatter bad-frontmatter \
  "sed -i '1d' work/SKILL.md"

expect_rule no-description bad-frontmatter \
  "sed -i '/^description: /d' work/SKILL.md"

expect_rule unlisted-skill unclassified-skill \
  "mkdir -p newskill/agents; cp work/SKILL.md newskill/SKILL.md; sed -i 's/^name: work$/name: newskill/' newskill/SKILL.md; cp work/agents/openai.yaml newskill/agents/openai.yaml"

expect_rule fixture-wrong-skill bad-fixture \
  "sed -i 's/^skill: work$/skill: nosuchskill/' fixtures/disclosure/work-on-a-bug.fixture"

expect_rule fixture-vacuous-forbid bad-fixture \
  "sed -i 's/^forbids: review-feedback.md$/forbids: nosuchref.md/' fixtures/disclosure/work-on-a-bug.fixture"

expect_rule fixture-bad-invocation bad-fixture \
  "sed -i 's/^invocation: implicit$/invocation: sometimes/' fixtures/invocation/work.fixture"

# These two sabotage the TREE only. An earlier version also edited check.sh to
# steer which rule fired; a case that mutates the gate proves less than one that
# does not, and it dragged in unrelated findings.
expect_rule policy-mismatch wrong-policy \
  "sed -i 's/^invocation: explicit\$/invocation: implicit/' fixtures/invocation/sprout.fixture"

expect_rule codex-unreachable codex-parity \
  "rm -f spike/agents/openai.yaml"

expect_rule wrapped-condition empty-pointer-condition \
  "perl -0pi -e 's|- running the check suite and the doc-surface sweep -> \`verify.md\`|- running the check suite and the doc-surface sweep\n  -> \`verify.md\`|' work/SKILL.md"

# Reword a pointer's condition so it no longer names the branch its fixture
# declares. The pointer still exists and still resolves; only the CONDITION
# stops matching, which is the whole thing the disclosure fixtures assert.
expect_rule empty-tree no-skills-found \
  "rm -rf compound flow lessons plan review spike sprout today work"

expect_rule reworded-condition condition-misses-branch \
  "sed -i 's|- the task is a bug, crash, regression or falsification -> |- when things go sideways -> |' work/SKILL.md"

expect_rule uncovered-reference no-disclosure-fixture \
  "rm -f fixtures/disclosure/work-on-a-bug.fixture"

# Content fixtures assert that a reference actually STATES its rule, which no
# budget or pointer check can see: a `prototype.md` that resolves, loads on the
# right branch and fits its budget can still have lost the storage order it
# exists to carry. Each of these deletes one required element of a real rule.
expect_rule content-element-dropped missing-content-element \
  "sed -i 's/limitations/gaps/g' spike/prototype.md"

expect_rule content-element-forbidden forbidden-content-element \
  "sed -i '/^## Retained evidence\$/a A throwaway sketch is fine here.' spike/prototype.md"

expect_rule content-file-missing bad-fixture \
  "sed -i 's/^file: prototype.md\$/file: nosuchref.md/' fixtures/content/retained_prototype_smoke.fixture"

expect_rule content-section-missing bad-fixture \
  "sed -i 's/^## Retained evidence\$/## Evidence we keep/' spike/prototype.md"

# ONE exit decision, after everything is computed. An earlier version put the
# case gate first and then bumped `failures` from the undeclared-rule block
# below it, where nothing ever read it again - so that half of the check could
# report a problem and still exit 0.

# The declared rule inventory. Two rules are selected at runtime, so a static
# scan of `fail` calls cannot see them, which is why check.sh declares the set
# and this asserts the declaration is complete rather than re-deriving it.
emitted="$(bash "$selftest_root/check.sh" --rules | sort -u)"

# Join backslash continuations first: several `fail` calls wrap, and matching
# line by line under-counts what the source can emit.
literal="$(cat "$selftest_root/check.sh" "$selftest_root/fixtures/run.sh" |
           sed -e ':a' -e '/\\$/{N;s/\\\n[[:space:]]*/ /;ta}' |
           grep -ohE '(^|[^_[:alnum:]])fail ("[^"]*"|[^ ]+) [a-z][a-z0-9-]*' |
           awk '{print $NF}' | sort -u)"
undeclared="$(comm -23 <(printf '%s\n' "$literal") <(printf '%s\n' "$emitted"))"

covered="$(printf '%s\n' "${proven[@]-}" | sort -u)"
uncovered="$(comm -23 <(printf '%s\n' "$emitted") <(printf '%s\n' "$covered"))"

n_emitted="$(printf '%s\n' "$emitted" | grep -c .)"
n_covered="$(printf '%s\n' "$covered" | grep -c .)"

printf 'skills self-test: %d sabotage case(s), %d of %d rules covered\n' \
  "$cases" "$n_covered" "$n_emitted"

status=0
if [ "$failures" -gt 0 ]; then
  printf '\nself-test: %d of %d case(s) failed\n' "$failures" "$cases" >&2
  status=1
fi
if [ -n "$undeclared" ]; then
  printf 'rules emitted by the source but missing from check.sh RULES:\n%s\n' \
    "$undeclared" >&2
  status=1
fi
if [ -n "$uncovered" ]; then
  printf 'uncovered rules (no sabotage case proves these can fail):\n%s\n' \
    "$uncovered" >&2
  status=1
fi
exit "$status"
