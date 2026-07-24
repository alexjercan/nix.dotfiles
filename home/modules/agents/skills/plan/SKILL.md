---
name: plan
description: Turn a feature request or piece of work into a concrete implementation plan captured as tatr tasks. Use this skill when the user asks to plan, break down, or scope out work with `/plan`, or whenever a request is large enough that it should be split into ordered, checkable steps before any code is written. The output of planning is one or more tatr tasks whose descriptions contain the steps to implement.
---

# Plan - Break Work Into Implementable Tatr Tasks

Planning takes a fuzzy request and produces a set of tatr tasks that a future
session (or the current one) can pick up and implement step by step. The plan
lives in the repo as `tasks/<id>/TASK.md` files, so it is versioned alongside
the code. See the tatr skill for the CLI commands and file format.

The goal is not to write code. The goal is to leave behind a clear, ordered
list of steps so implementation is mechanical.

Planning assumes the *what* is already decided and only the *how* needs
breaking down. If the request is still genuinely undefined - the open question
is what to build, not how - run `/spike` first. A spike researches the
direction and leaves a `SPIKE.md` (in the spike's own task folder) plus
coarse, direction-level tasks; planning then expands each of those tasks into
steps, citing the spike doc as the input it was scoped from.

## Workflow

1. **Understand the request.** Read the relevant code first; do not plan
   against assumptions. Check the existing backlog with `tatr ls` so the plan
   extends it instead of duplicating tasks. If the scope is ambiguous or there
   is a real fork in the approach that changes what gets built, ask the user
   before writing the plan. Confirm the concrete ARTIFACT, not just the goal:
   when the request fixes only where a thing goes or how it should look but not
   WHICH thing it is - which type, which mechanism - pin that down before
   planning against a guessed shape, and put the constraints that make the
   candidates mutually exclusive in front of the user (e.g. "a bcs status item
   cannot carry a border, so it is a status item OR it keeps the pill, not
   both"). That incompatibility is usually the real decision; surfacing it is
   what turns a blind pick into an informed one. Do not ask about things you
   can decide from the code or sensible defaults.

2. **Decide the task breakdown.** Split the work along natural boundaries
   (components, layers, independent features). Prefer several small tasks over
   one giant task when the pieces can be implemented and committed
   independently. Keep a single task when the work is one cohesive change.

3. **Create the tasks.** Make sure `tasks/` exists at the project root
   (`mkdir -p tasks`), then for each task run:

   ```bash
   tatr new "Short imperative title" -p <priority> -t <tags>
   ```

   Each invocation prints the new task ID; keep it, you need it to edit the
   file (or seed the body directly with `tatr new -b <file>`). Run ONE
   `tatr new` per command - never several chained; a same-second call now
   FAILS rather than overwriting (see the tatr skill's gotchas), so a chain
   just dies midway. Priorities encode order: higher runs first - slot each
   new task RELATIVE to the existing list (`tatr ls --sort priority`), and
   follow the project's scheduling-tag convention from its AGENTS.md if it
   has one. When one task cannot start before another finishes, also record
   that in its Notes section (`Depends on: <task-id>`); priority alone is only
   a soft ordering.

4. **Fill in the plan.** Edit each `tasks/<id>/TASK.md` so the description
   contains the implementation steps as a checkbox list (see format below).
   This is the heart of the plan.

5. **Report back.** List the created task IDs and titles in intended order,
   plus any assumptions the user should double-check. Offer to commit the new
   task files. Do not start implementing unless the user asks.

   Under `/flow` there is an extra step: the run already created an umbrella
   task with a `GOAL.md` (see the flow skill). Append the planned tasks to
   that GOAL.md Tasks list - one unchecked line each, in intended order - so
   the goal artifact carries the live queue that flow ticks as tasks land.

## Task File Format for a Plan

Keep the tatr header exact, then use the description for the plan itself:

```markdown
# Add rate limiting to the API

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature, api

## Story

As an API operator, I want per-client rate limiting, so that one client
cannot starve the rest. Plus whatever context a cold session needs.

## Steps

- [ ] Add a `RateLimiter` struct in `src/middleware/ratelimit.rs`.
- [ ] Wire it into the request pipeline in `src/server.rs`.
- [ ] Read the limit from config, defaulting to 100 req/min.
- [ ] Add an integration test that exceeds the limit and asserts a 429.

## Definition of Done

- Requests over the limit get a 429 with a Retry-After header
  (test: `ratelimit_returns_429_when_over_limit`).
- The limit is read from config and its default is documented
  (cmd: `grep -n "req/min" docs/config.md`).
- manual: under a real burst from one client, other clients' latency
  stays flat.

## Notes

- Relevant files: src/server.rs, src/config.rs
- Assumption: token-bucket, not a sliding window.
- Depends on: 20260703-101500 (config loader refactor)
```

A `## Goal` paragraph may stand in for Story on trivial tasks, but Steps plus
a Definition of Done is the shape /work implements against and /review
verifies against - the DoD is the review contract.

**Every DoD item names its proof.** End each item with how it is checked, and
put the test name or command in backticks so globs, quotes and stars render
literally in markdown:

- `(test: <name>)` - an automated test that fails without the change; write
  it as `` (test: `the_test_name`) ``.
- `(cmd: <command>)` - a command whose output shows the criterion holds
  (a grep, a build, a script); write it as `` (cmd: `grep -n foo file`) `` so
  brace-globs like `{a,b}` do not get mangled. /work and /review run it
  verbatim. A repo-wide grep that proves an ABSENCE (no stale references to a
  renamed symbol remain, no leftover TODO) must exclude the `tasks/` tree from
  the start - the task's own record and this very DoD item quote the string
  being searched, so an unscoped grep self-matches its own file and can never go
  green. Scope it to the code/doc paths that matter, e.g.
  `` (cmd: `grep -rn oldname src/ docs/`) ``, or exclude the records explicitly,
  e.g. `` (cmd: `grep -rn --exclude-dir=tasks oldname .`) ``.
- `(manual: <what the user confirms>)` - a human judgement no test can make
  (it reads well, it feels right, the burst does not degrade latency). When
  the whole criterion IS the judgement, lead the item with a bare
  `manual: <...>` instead of trailing it - the criterion and its proof are one
  and the same, so there is nothing to state twice.

An item with no nameable proof is a red flag: rephrase it into something
observable, or demote it to a Notes bullet - do not ship acceptance criteria
that nothing can check. `manual:` items are the honest escape hatch for
genuinely human calls, not a dumping ground for "too hard to test"; they do
not block landing but are batched to the user (see the flow skill's Finish
gate). This makes unverifiable criteria visible at plan time instead of
letting a green harness proxy-verify a dead feature.

Each DoD item's proof is ALSO the test-first target for `/work`: the `test:`
and `cmd:` proofs are written before the implementation and watched to fail
(see the work skill), so phrase them so the implementer can encode them as the
first artifact, not reverse-engineer them from finished code.

## Recording a Decision (DECISION.md)

Planning is where a load-bearing architectural choice usually gets made -
which mechanism, which layering, which dependency. When that choice is
non-trivial and a cold reader would need to know *why* (not just *what*),
record it as a `DECISION.md`, so the reasoning survives past the chat and the
next session does not re-litigate it.

Writing the record is MANDATORY, not optional, for any load-bearing build-shape
fork - the kind you confirmed with the user in step 1 (which artifact, which
mechanism, and the constraint that forced the choice). The confirm and the
record are one move: confirm the concrete artifact, then capture the confirmed
choice AND the rejected alternative AND the constraint that separated them in
the DECISION.md, before the build. A choice made by inferring a shape, or
confirmed in chat but never recorded, is exactly the failure this section
guards against - the reasoning evaporates and the next session (or a mid-build
surprise, like "a status item cannot carry the pill") re-opens it from zero.

This is a decision RECORD, and it is distinct from a spike:

- A `/spike` reduces uncertainty about *what to build* when the direction is
  fuzzy; its output is a chosen direction (`SPIKE.md`). A spike is optional and
  only fires when there is something genuinely to explore.
- A `DECISION.md` records *a choice that was made* and its rationale, whether or
  not a spike happened. A dead-obvious choice with no alternatives worth
  weighing still gets a record if it is load-bearing; a choice reached by a
  spike can cite that `SPIKE.md` as its context rather than repeat it.

Do NOT force a spike just to justify a decision - that is exploration theater
for a choice you never actually explored. Write the record directly.

**Where it lives.** In the folder of the task that owns the decision:
`tasks/<id>/DECISION.md`. For a choice that spans the whole goal rather than one
task, put it in the umbrella task's folder next to `GOAL.md`. Under `/flow`,
add a one-line pointer to the goal's `GOAL.md` Decisions index (see the flow
skill) so the decision is findable without grepping every task folder.

**Supersede, do not rewrite.** The `tasks/` tree is append-only history (see
the flow and work skills), so a decision that later changes is NOT edited in
place. Write a NEW `DECISION.md` in the task that changes it, with a
`Supersedes: tasks/<id>/DECISION.md` header pointing back; and add the matching
`SUPERSEDED by tasks/<id>/DECISION.md` line to the old record's STATUS - that
one-line lifecycle annotation is the only edit the old file takes, the same way
the lessons ledger annotates a RETIRED entry rather than deleting it. A reader
landing on either record can then walk to the current one.

```markdown
# Decision: Rate-limit with a token bucket, not a sliding window

- DATE: 20260704-131500
- STATUS: ACCEPTED   # ACCEPTED | SUPERSEDED by tasks/<id>/DECISION.md
- TASK: 20260704-131500
- TAGS: decision, api, ratelimit
- Supersedes: tasks/<id>/DECISION.md   # omit unless this replaces one

## Context

The forces that make this a real choice - constraints, requirements, what
already exists. One paragraph; cite a `SPIKE.md` here if a spike fed it.

## Decision

The choice, in active voice.

## Alternatives considered

- **Sliding window** - how it would work here; why rejected.
- **Do nothing** - what deferring costs.

## Consequences

What gets easier AND what gets harder as a result - the honest downsides too.
```

## Guidelines for Good Steps

- Each step is a concrete, verifiable action, ideally naming the file(s) it
  touches. "Add a RateLimiter struct in src/middleware/ratelimit.rs" not
  "implement rate limiting".
- List order is execution order; each step builds on the previous one, so the
  implementer can go top to bottom.
- Include a step for tests or a runnable example when the change warrants it,
  and a documentation step when the change alters behavior worth documenting
  (a design/fix record is `tasks/<id>/NOTES.md`; reference docs live in
  `docs/`).
- Record the files and facts you discovered while reading the code in Notes,
  so the implementer does not have to re-search.
- Call out assumptions and open questions explicitly in Notes rather than
  baking an unstated guess into a step.
- A step that encodes a physical mechanism, a formula, or a dependency's
  schedule/ordering behavior must either cite the file or derivation that
  verifies it, or be phrased as a verify-first question ("confirm X,
  then..."). Plans written from a model of the system instead of the
  system have been wrong repeatedly (nova-protocol, three cycles in a
  row on 2026-07-11). The same goes for engine/dependency behavior: read the
  dependency's source (or write a five-line probe) before designing around
  its ordering, observer semantics, or failure modes - a reasoned verdict
  about a dependency is a hypothesis, not evidence. For load-bearing git or nix
  semantics a step will rely on (merge/rebase behavior, worktree or flake
  path/GC rules), verify them in a THROWAWAY scratch repo first and write the
  step from what you observed, not from memory of how the tool "should" behave.
- When a task adds a new route into an existing state or mode (a new setter
  of a state machine, a new entry into "paused"), plan a step that greps for
  everything gated on that state and lists what newly runs in the new
  context - new entry paths keep surprising their consumers.
- Do not pad the plan. A three-line change gets a three-line plan.

## Relationship to Implementation

When work on a planned task begins, the implementer follows the tatr
workflow: set STATUS to `IN_PROGRESS`, tick the checkboxes as steps land, and
finally set STATUS to `CLOSED` with a record of what changed and any lessons.
If the plan turns out to be wrong mid-implementation, update the Steps in
TASK.md to match reality instead of silently diverging; the file should always
reflect the actual plan.
