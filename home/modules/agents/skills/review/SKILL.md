---
name: review
description: Critique a feature branch against its tatr task and drive rounds to a verdict. Use for `/review` or when a branch is ready for critique.
---

# Review - Critique the Work Like a Real PR Review

The reviewer's job is judgment, not politeness - and not patching. The
reviewer writes findings; `work` writes fixes.

## Workflow

1. **Locate the work.** Diff the branch against the default branch
   (`git diff <default>...<branch>`) and read the task
   (`tatr context <id> --phase review`). TASK.md's Story, Steps and Definition
   of Done are the spec the diff is judged against. Run the checks inside the
   worktree: `cd "$(sprout show <feature>)"`.

2. **Round 1 comes from out of context by default.** On any substantive
   branch the round-1 findings are produced by a reviewer that has NOT seen
   the implementing session - a fresh subagent, a fresh-agent code-review
   pass, or a separate session. Substantive is judged by consequence, not file
   type: a docs-only diff defining process or behavior is substantive; only
   typo-level fixes are trivial.

   The reviewer's prompt carries the task ID, the branch and worktree path,
   the review dimensions, and the record format - never the implementing
   conversation or its summaries, which carry exactly the assumptions that
   must not leak. The out-of-context reviewer RETURNS findings; the in-session
   pass runs the check suite itself, re-derives at least one load-bearing
   claim before adopting the findings, then writes and commits the round.

   An in-session-only round is fine on a trivial diff and is an exception on a
   substantive one. Either way `- REVIEWER:` records which it was, and why.

3. **Review the dimensions.** Do not trust the implementer's summary;
   verify every claim yourself.

4. **Write the findings** into `tasks/<id>/REVIEW.md`. Every finding gets a
   severity, a `file:line` and a concrete suggested change.

5. **Issue the verdict.** `REQUEST_CHANGES` if any BLOCKER or MAJOR finding is
   open, `APPROVE` otherwise; open MINOR and NIT findings are the
   implementer's discretion. Alongside the verdict, list the task's open
   `manual:` DoD items as pending USER checks - APPROVE does not resolve them,
   and an APPROVE with manual items open is normal, not a contradiction. On
   APPROVE the review cycle ends; merging and pushing are the user's call, or
   the orchestrator's.

6. **Re-review rounds.** Verify each Response against the new diff and tick a
   finding only when you confirmed it is resolved. Keep the out-of-context
   default. Accept convincing pushback; do not relitigate settled findings.
   Add new findings only for problems the new changes introduced. A finding
   still disputed after three rounds goes to the user.

## Guidelines

- Be specific and actionable: "rename X to Y", not "naming could be better". A
  finding the implementer cannot act on is noise.
- Do not invent nits to look thorough. A clean diff deserves a short round and
  an APPROVE.
- Review the diff, not the repository. Pre-existing problems become new tatr
  tasks, not blockers on this branch.
- Severity reflects impact, not effort to fix.
- The out-of-context default exists because a shared session inherits the
  implementer's assumptions along with the context, and "review skeptically"
  nudges do not remove them. That blind spot applies to the supplement too:
  re-derive rather than adopt wholesale.
- Commit REVIEW.md on the feature branch after each round.

## Output

Findings first, most severe first, then the verdict and the pending `manual:`
items. Beyond the findings themselves, 150 words or fewer, and no narrative
that duplicates them. `tatr flow <id>` moves
REVIEWING -> COMPOUNDING on an APPROVE and refuses it otherwise.

## Load on demand

Read one ONLY when its condition holds. Never preload them.

- judging a diff on correctness, spec, tests, design, docs, honesty -> `dimensions.md`
- writing a round, a finding, a severity or a verdict -> `rounds.md`
- the diff touches auth, secrets, migrations, concurrency, a public API, shared infrastructure or a broad contract -> `lanes.md`
