# Review: make round-1 review unconditionally out-of-context and survive a gate overshoot in afk

- TASK: 20260803-002416
- BRANCH: feature/afk-gate-overshoot

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R1.1 (MINOR) home/modules/agents/skills/review/rounds.md:72 - the
  narrowed `- REVIEWER:` field leaves `SKILL.md` step 5 with no legal value.
  Step 5 still says later rounds keep the out-of-context default "unless an
  exception is recorded", but `in-session (<why>)` is now reserved for a
  runtime that cannot start a second context - which is not an exception a
  later round gets to elect. Either reword step 5 to name that same runtime
  condition, or give the field an explicit later-round clause.
  - Response:
- [ ] R1.2 (MINOR) home/modules/scripts/afk-test.sh:689 - `gen_sprout_work`,
  `gen_review_to_done` and `gen_land` duplicate the invocation blocks
  `gen_work_to_land` (line 166) still carries inline; the close-out calls them
  "factored out", but that function is untouched, so each fixture shape now
  exists twice. Two of the three have a single caller. Have `gen_work_to_land`
  call `gen_sprout_work $((b + 1)) "$id"`, `gen_review_to_done $((b + 3))
  "$id"` and `gen_land $((b + 4))`, deleting its three duplicated heredocs.
  - Response:
- [ ] R1.3 (NIT) home/modules/scripts/afk-test.sh:728 - `gen_land` hardcodes
  `sprouts/repo/feature/thing` because its heredoc is quoted, while its two
  siblings interpolate `$WT_REL`. Unquote the heredoc and use `$WT_REL` like
  the others, or say in the comment why this one cannot.
  - Response:

Verified. Every DoD proof run in the worktree: `afk-test.sh` 19 passed / 0
failed; the PROTOCOL `sed`/`grep` matches; the `review/` hatch grep returns
nothing; `grep -n request review/SKILL.md` hits line 18; `check.sh` clean at
152 flow-family description words; `nix flake check` all checks passed; `tatr
check` silent. Base redness re-derived independently on `master`: the hatch
grep finds 3 matches (2 `SKILL.md`, 1 `rounds.md`) and the PROTOCOL grep finds
0, both as the DoD claims.

Load-bearing claim re-derived by mutation. Reverting `lifecycle_gate`'s
`activity)` arm to `require_activity` fails exactly two tests -
`test_gate_resume_may_overshoot` ("a work done gate that overshoots completes
the run", "the overshoot is not called a failed approval", "the branch landed")
and `test_failure_paths` ("the expected activity is named"). The new tests
assert behaviour, not coverage, and the tree was restored clean afterwards.

Read the code. `activity_rank` fails on the empty string and on any unranked
word, so `require_activity_at_least` still dies on an unreadable cursor rather
than passing it; the precondition keeps `require_activity`, as the Steps
require. `lifecycle_gate` has exactly one `activity` postcondition caller
(WORK_DONE), and the PLAN_READY arm is `gate PLAN` - so the second half of
`test_gate_resume_may_overshoot` is a pin, which its own comment and the Notes
both say. `flow/gates.md` "Continue or stop" already told the session to
transition, commit records and stop; the new `PROTOCOL` sentence restates it in
afk's own voice without contradicting it.

Doc sweep. `grep -rn 'in-context|out-of-context|in-session|round 1'` across
`home/modules/agents/skills/` outside `review/` returns nothing, so no other
skill quoted the deleted fresh-session clause. `lanes.md:31` and
`work/review-feedback.md:27` reference `- REVIEWER:` only as a field name and
stay correct.

Every ticked Step matches the diff. The one deviation - the overshoot case
living in its own `test_gate_resume_may_overshoot` rather than inside
`test_failure_paths` - is recorded in the close-out with its reason, and
`test_failure_paths` did keep and tighten the ineffective-approval case as the
Step asked.

No pending `manual:` proofs.

Inspection commands:

```bash
cd "$(sprout show feature/afk-gate-overshoot)"
bash home/modules/scripts/afk-test.sh
bash home/modules/agents/skills/check.sh
nix flake check
git diff master...HEAD
```
