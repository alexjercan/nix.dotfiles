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
   before writing the plan. Do not ask about things you can decide from the
   code or sensible defaults.

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

- Requests over the limit get a 429 with a Retry-After header; the
  integration test pins it; the config knob is documented.

## Notes

- Relevant files: src/server.rs, src/config.rs
- Assumption: token-bucket, not a sliding window.
- Depends on: 20260703-101500 (config loader refactor)
```

A `## Goal` paragraph may stand in for Story on trivial tasks, but Steps plus
a Definition of Done is the shape /work implements against and /review
verifies against - the DoD is the review contract.

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
  about a dependency is a hypothesis, not evidence.
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
