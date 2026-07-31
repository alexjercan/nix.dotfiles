# Parallel planning lanes

Several planners answer the same question from different angles, and one of
them synthesizes. Fresh perspectives are bought with context, so they are
opened deliberately and closed the moment the plan is chosen.

## When to open lanes

The default is one planner. Ordinary work - a change whose shape is already
settled, a small addition inside an existing pattern, anything a three-line
plan covers - gets one, and this file has nothing to add to it.

Open lanes only when at least one of these holds:

- The plan turns on a fork that is expensive or irreversible to undo later: a
  schema, a wire format, a public interface, a storage layout.
- The work spans independent domains that a single planner would have to think
  about serially anyway.
- The task is an Epic whose material does not fit one context, so a single
  planner would be planning from a summary.
- The user asked for lanes, or asked to see alternatives compared.

Two or three lanes. Not one per idea, not one per file. If you cannot say what
a fourth lane would look for that the first three would miss, there is no
fourth lane.

## The three lanes

Each lane is a full plan for the whole task, differing in what it optimizes:

- **Minimal end to end.** The smallest thing that delivers the Story and can
  land. What does it defer, and what does deferring cost?
- **Deep interface.** The shape a cold reader would want in a year: the seams,
  the naming, the invariants that stay true as the code grows.
- **Migration and risk.** What breaks, what has to move, what is hard to
  reverse. Existing data, existing callers, existing records, the rollback.

Drop a lane whose angle the task does not have - a change with no existing
callers and no stored state has no migration lane.

## The context packet

Every lane receives an identical packet and nothing else:

- the task ID and the request as the user stated it;
- the artifacts `tatr context <id> --phase plan` lists, read-only;
- the files and commands the packet names, for the lane to read itself;
- this lane's angle, and its output cap.

A lane never sees another lane's packet reply, and no other lane's conclusions
reach it - not as a summary, not as "the other planner suggested". Lanes that
compare notes produce one plan wearing three hats, which is the failure this
whole shape exists to avoid. Neither does a lane receive the orchestrating
session's own leanings; those are exactly the assumptions being tested.

A lane returns at most 400 words: its ordered Steps, its Definition of Done,
and the one thing it thinks the other angles will get wrong. No narrative, no
code, no writes to any file.

## Synthesis

The orchestrating session, not a lane, chooses. Read all replies, then:

1. Pick the lane that best fits the constraints, or assemble one plan from the
   parts that survive scrutiny. Verify a claim before adopting it; a lane's
   confidence is not evidence.
2. Write one plan into the task's `TASK.md` - Steps and Definition of Done as
   the plan skill specifies.
3. Write one DECISION.md when the choice was load-bearing. Each losing lane
   gets one rejected alternative paragraph: what it would have done here, and
   the constraint that ruled it out. Two or three sentences each.

Then discard the rest. Candidate replies are scratch: they are not committed,
not stored under `tasks/`, and not pasted into the record. What survives is the
chosen plan and the reasoning a cold reader needs, and nothing whose only
function is to show that lanes ran.

If two lanes disagree on a fact rather than a preference, that disagreement is
the finding: check the fact yourself before choosing.

## Resources

Planning lanes are read-only. They read the repository and the task records,
run nothing that writes, and never sprout a worktree. Every lane can therefore
share the checkout that is already open, and no isolation is needed to keep
them apart. A lane that wants to try something out is asking for a spike, not
for write access.

Nothing here changes when the branch is created: the chosen plan is
implemented afterwards, in one worktree, by one implementer.
