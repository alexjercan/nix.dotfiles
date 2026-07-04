# Retro: Squash-merge task branches in flow

- TASK: 20260704-105059
- BRANCH: squash-merge (kept on branch for the user to squash-merge, not merged)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260704-105059/{TASK,REVIEW}.md`. Process notes only.

## What went well

- Resolved the one real fork up front. "Single commit for the whole feature"
  had two readings (one commit per task vs one per multi-task goal) that lead
  to different flow designs; asked the user before planning instead of guessing
  and reworking. That is the "ask at the cheapest moment" rule paying off.
- Verified git's actual `--squash` semantics in a scratch repo before writing
  the instructions - staged-not-committed, no merge parent, `branch -D` still
  works. Carried the standing retro lesson ("ground truth beats reasoning")
  into a docs task where it is easy to skip because "it's just words".
- Grepped the whole repo for `--no-ff` / merge-strategy references first, so
  the change had a known blast radius (one file) rather than leaving a stale
  contradiction somewhere.
- Scoped the second file honestly: only `flow` merges, so `work` got a
  consistency note phrased conditionally ("when `/flow` merges") rather than a
  fake behavior change, keeping standalone `/work` correct.

## What went wrong

- Nothing broke. The only finding was a NIT (two sentence-initial "Then"s),
  fixed in the same round. Root cause was just prose flow in a rewritten
  paragraph, not a process gap.

## What to improve next time

- For a self-referential edit to the agent's own workflow skills, a quick
  end-to-end mental (or scratch-repo) dry-run of the new instructions is worth
  it - it is what surfaced that `--squash` records no merge parent, which
  became a useful defensive note in the skill rather than a future surprise.

## Action items

- [x] Confirmed no other repo reference to the old merge strategy (grep clean).
- [ ] Watch the first real `/flow` run under the new step 5: confirm the agent
      writes one clean squash-commit message rather than shipping git's
      pre-filled concatenation. If it slips, tighten the wording.
