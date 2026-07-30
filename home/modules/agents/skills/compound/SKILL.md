---
name: compound
description: Write a task retro after its review is APPROVEd and fold the lessons into the ledger. Use for `/compound` before landing.
---

# Compound - Retro After the Cycle

The retro is about the PROCESS, not the change. TASK.md already records what
changed and why; the retro records how the working went and what to do
differently. Each cycle should leave the process a little better than it found
it - that is the compounding.

## Workflow

1. **Check the cycle is done.** The latest REVIEW.md round says APPROVE and
   `tatr check <id>` is clean. Under `flow` the task is in COMPOUNDING, which
   `tatr flow` only grants on an APPROVE. Resolve its findings before
   reflecting. If the cycle is not done, say so and stop, unless the user
   explicitly wants a retro on unfinished work.

2. **Gather the evidence.** Do not reflect from memory alone. Re-read TASK.md
   (the plan as executed, the close-out), REVIEW.md (every finding escaped
   implementation; every round cost a cycle), and the branch's git log (rework,
   reverts and fix-ups are signals).

3. **Reflect honestly** with specifics, not platitudes:
   - What went well - practices worth repeating on purpose.
   - What went wrong, and its ROOT CAUSE. "R1.1 happened because the
     middleware was written before reading how server state is shared", not
     "should have been more careful".
   - What to improve, phrased as something a future session can act on.

4. **Write the retro.**

   ```bash
   tatr scaffold <id> RETRO
   ```

   Fill `tasks/<id>/RETRO.md`. Blameless but specific: name the decision that
   failed and why it seemed right at the time. Three sharp observations beat a
   page of filler, and a smooth cycle deserves a short retro that says so.

5. **Update the ledger.** Append or bump each generalizable lesson - slug, one
   sentence, occurrence count, task IDs. Two lines is the cap; if the addition
   needs more you are writing a variant, so sharpen the sentence instead.
   Counts stay BARE - `(x3)`, never `(x3, note)` - until a lifecycle event
   annotates them. When a lesson is really a rule for one skill, say so in the
   entry (`-> work skill`) at any count. Format and search order: the lessons
   skill's `ledger.md`.

6. **Promotion is the user's call.** A lesson reaching three occurrences moves
   to the ledger's `## Pending promotions` section. Do NOT self-promote it
   into a tool, template, AGENTS.md or skill. Propose, with the promotion
   order tool > template/format > skill prose - prose warns, tools prevent -
   and let the user decide. Follow-up code work becomes a new tatr task;
   one-off observations stay in the retro.

7. **Commit.** On the feature branch, from inside its worktree, when the work
   has not landed yet, so the retro travels with the task and the squash folds
   it into the same commit. Otherwise on the default branch in the main
   checkout - and there, check `git branch --show-current` first, since
   parallel sessions move the shared checkout's HEAD.

## Guidelines

- Do not restate the diff or duplicate TASK.md's close-out. Each file has a
  lane: TASK.md is what changed and the evidence rig, REVIEW.md is findings,
  RETRO.md is process, a seeding spike's `## Fix record` is a few lines of
  family status pointing at the task, and the ledger is reusable learning.
  Writing the same prose three times is the main cost of the documentation
  habit.
- Look for patterns in the ledger, not just in this cycle. A lesson appearing
  for the third time is a rule waiting for a home.

## Output

The new and bumped lesson slugs and any follow-up task IDs - 100 words or
fewer. `tatr flow <id>` then moves COMPOUNDING -> DONE.
