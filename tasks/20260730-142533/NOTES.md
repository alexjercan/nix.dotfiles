# Design refinement: Context, output, and enforcement

User feedback after the source spike refined these requirements.

## Mandatory lesson-promotion gate

`/compound` may collect and count lessons, but must not silently promote one
into a tool, template, AGENTS.md, or skill. At the promotion threshold:

1. Move the lesson to Pending promotions.
2. Stop at an explicit user decision gate. Use the platform's user-input tool
   when available; otherwise ask directly.
3. Offer a recommendation and these outcomes:
   - PROMOTE: name the target and create/approve a tatr task.
   - DEFER: record the reason and a revisit condition.
   - RETIRE: record why no action is appropriate.
   - ABSORBED: name the existing tool/template that already enforces it.
4. Run every approved promotion through plan, work, review, and compound.

The ledger caches the answer so later flows do not ask again. A bare pending
entry is unresolved and must keep the lessons/flow finish gate red.

## Tatr work that can replace prose

Current `tatr edit -s` validates only the status token and writes it. Current
`tatr check` audits malformed states later. Prefer transactional commands plus
the existing audit:

### Highest value

- Add `tatr start <id>`: require approved plan, closed dependencies, and an
  atomic claim before moving to work.
- Add `tatr advance <id> <phase>`: enforce legal flow transitions and the
  allowed REVIEWING -> WORKING review loop.
- Add `tatr close <id>`: refuse closure until Steps are complete, the latest
  review is APPROVE, RETRO exists, required manual decisions are recorded, and
  flow state is DONE.
- Route `tatr edit -s` through the same transition checks for flow-managed
  tasks, or reject it with a pointer to the lifecycle command. Otherwise it is
  an unrestricted bypass and the guard is only advisory.
- Keep tasks IN_PROGRESS through review and compound. Closing before review
  creates a knowingly invalid intermediate state.
- Extend ledger checking so a bare Pending promotion emits
  `promotion-awaiting-decision`; validate PROMOTE/DEFER/RETIRE/ABSORBED
  dispositions and referenced task/target paths.

### Artifact schemas

- Scaffold TASK, SPIKE, DECISION, REVIEW, and RETRO records from one source.
- Validate required headings and non-empty records for modern flow tasks.
- Validate DoD proof syntax: `test:`, `cmd:`, or `manual:`.
- Validate review round numbers, finding IDs, reviewer field, verdict values,
  and that APPROVE has no open BLOCKER/MAJOR findings.
- Validate reciprocal DECISION supersede links, not only that targets exist.
- Validate SPIKE status and all seeded task/artifact pointers.

### Epic and parallel-work guards

- Add structured parent and dependency fields.
- Check missing parents/dependencies, dependency cycles, child/parent
  reciprocity, starting while blocked, and closing an epic with open stories.
- Add `tatr frontier <epic>` and an atomic `tatr claim <id>`.
- Add `tatr context <id> --phase <phase>` to print the minimal task/artifact
  packet for plan, work, review, compound, or resume.

Tatr should validate proof shape and expose proofs as structured output, but it
should not execute arbitrary shell commands from Markdown. Flow/work/review
remain responsible for running them.

## What remains judgment

Keep these in skills and review:

- whether a lesson is generalizable;
- whether a task needs a spike or parallel planners/reviewers;
- severity, root cause, architecture, and tradeoffs;
- which code and tests satisfy a story;
- whether an exploratory artifact deserves supported-example status.

## Repository configuration cache

Add a short `## Agent workflow` cache to AGENTS.md, with detail behind one
pointer when needed:

- issue tracker and epic/story convention;
- prototype/example location and retention policy;
- domain/glossary location, if the repo has one;
- allowed research sources or network constraints;
- canonical checks.

Resolve a prototype location in this order: AGENTS.md policy, an established
repo-native `examples/` or `scripts/` convention, the task folder, then one
user question. Once answered, cache it so future sessions do not ask again.

## Output limits

Enforce skill/description/reference budgets in a dedicated skill-conformance
check. Enforce task-artifact schemas in tatr. Chat limits remain skill output
contracts because tatr cannot observe chat.
