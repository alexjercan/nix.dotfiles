---
name: compound
description: Run a retrospective after a tatr task is CLOSED and its review is APPROVEd, and record the lessons in the repo's docs folder. Use this skill when the user asks for a retro or reflection with `/compound`, or as the final step of the plan-work-review cycle. It answers what went well, what went wrong, and what to improve next time, writes the result to docs/retros/, and turns recurring lessons into concrete follow-ups.
---

# Compound - Retro and Self-Reflection After the Cycle

Compound is the step after `/work` and `/review` are done: a sprint-review
style retrospective on how the work actually went, written down so lessons
accumulate instead of evaporating. Each cycle should leave the process a
little better than it found it - that is the compounding.

The retro is about the process, not the change. TASK.md already records what
changed and why; the retro records how the working went and what to do
differently.

## Workflow

1. **Check the cycle is done.** The task's STATUS is `CLOSED` and the latest
   REVIEW.md round says `APPROVE`. If not, say so and stop, unless the user
   explicitly wants a retro on unfinished work.

2. **Gather the evidence.** Do not reflect from memory alone; re-read:
   - `tasks/<id>/TASK.md` - the plan as executed and the close-out notes;
   - `tasks/<id>/REVIEW.md` - every finding is something that escaped
     implementation, and every round is a cycle that cost time;
   - the branch's git log - rework, reverts and fix-up commits are signals;
   - what happened in the session(s): wrong turns, dead ends, lucky guesses.

3. **Reflect honestly.** Answer the three questions with specifics, not
   platitudes:
   - What went well - practices worth repeating on purpose.
   - What went wrong - and the root cause. "R1.1 happened because the
     middleware was written before reading how server state is shared", not
     "should have been more careful".
   - What to improve next time - phrased as something a future session can
     actually act on.

4. **Write the retro.** Save it as `docs/retros/<task-id>-<slug>.md` (format
   below). Create `docs/retros/` if it does not exist. The `docs/` folder is
   where all project documentation lives.

5. **Turn lessons into action.** A retro that changes nothing is shelf-ware:
   - a lesson that should apply to every future session belongs in AGENTS.md
     or the relevant skill - propose the edit;
   - follow-up code work becomes a new tatr task;
   - one-off observations just stay in the retro.

6. **Commit and report.** Commit the retro (on the feature branch if the work
   has not been merged yet, so it travels with the task; otherwise on the
   default branch). Summarize the key lessons and any follow-ups created.

## Retro File Format

```markdown
# Retro: Add rate limiting to the API

- TASK: 20260703-101500
- BRANCH: feature/api-rate-limiting
- REVIEW ROUNDS: 2

## What went well

- Integration test caught the config regression before review did.

## What went wrong

- R1.1 (limiter per request): middleware was written before reading how
  server state is shared. Root cause: skipped the understand-first step.

## What to improve next time

- Read the state-management code before writing anything that holds state.

## Action items

- [ ] tatr 20260703-183000: add a rate-limit metrics endpoint (follow-up)
- [x] proposed AGENTS.md note about reading state handling first
```

## Guidelines

- Blameless but specific: name the decision that failed, not just the
  outcome, and say why it seemed right at the time.
- Short beats complete. Three sharp observations are worth more than a page
  of filler; a smooth cycle deserves a short retro that says so.
- Look for patterns across retros in `docs/retros/`: a lesson appearing for
  the third time is a rule waiting to be added to AGENTS.md or a skill.
- Do not restate the diff or duplicate TASK.md's close-out notes; link to
  them instead.

## Relationship to the Cycle

The full loop is: tatr tracks, `/plan` scopes, `/work` implements, `/review`
critiques until APPROVE, `/compound` distills the lessons. Compound closes
the loop by feeding what was learned back into the tasks, docs and skills the
next cycle starts from.
