---
name: plan
description: Turn a feature request or piece of work into a concrete implementation plan captured as tatr tasks. Use this skill when the user asks to plan, break down, or scope out work with `/plan`, or whenever a request is large enough that it should be split into ordered, checkable steps before any code is written. The output of planning is one or more tatr tasks whose descriptions contain the numbered steps to implement.
---

# Plan - Break Work Into Implementable Tatr Tasks

Planning takes a fuzzy request and produces a set of `tatr` tasks that a future
session (or the current one) can pick up and implement step by step. The plan
lives in the repo as `tasks/<id>/TASK.md` files, so it is versioned alongside
the code. See the [[tatr]] skill for the underlying CLI and file format.

The goal is not to write code. The goal is to leave behind a clear, ordered
list of steps so implementation is mechanical.

## Workflow

1. **Understand the request.** Read the relevant code first. Do not plan
   against assumptions. If the scope is ambiguous or there are real forks in
   the approach that change what gets built, ask the user before writing the
   plan. Do not ask about things you can decide from the code or sensible
   defaults.

2. **Decide the task breakdown.** Split the work along natural boundaries
   (components, layers, independent features). Prefer several small tasks over
   one giant task when the pieces can be implemented and committed
   independently. Keep a single task when the work is one cohesive change.

3. **Create the tasks.** For each task run:

   ```bash
   tatr new "Short imperative title" -p <priority> -t <tags>
   ```

   Priorities encode order: higher runs first (0 low, 50 medium, 100 high).
   When tasks must happen in sequence, give earlier tasks higher priority.

4. **Fill in the plan.** Edit each `tasks/<id>/TASK.md` so the description
   contains the numbered implementation steps (see format below). This is the
   heart of the plan.

5. **Report back.** List the created task IDs and titles, and the intended
   order. Do not start implementing unless the user asks.

## Task File Format for a Plan

Keep the tatr header exact, then use the description for the plan itself:

```markdown
# Add rate limiting to the API

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature, api

## Goal

One or two sentences on what this task delivers and why.

## Steps

1. Add a `RateLimiter` struct in `src/middleware/ratelimit.rs`.
2. Wire it into the request pipeline in `src/server.rs`.
3. Read the limit from config, defaulting to 100 req/min.
4. Add an integration test that exceeds the limit and asserts a 429.

## Notes

- Relevant files: src/server.rs, src/config.rs
- Open question / assumption: using a token-bucket, not a sliding window.
```

## Guidelines for Good Steps

- Each step is a concrete, verifiable action, ideally naming the file(s) it
  touches. "Add a RateLimiter struct in src/middleware/ratelimit.rs" not
  "implement rate limiting".
- Order steps so each builds on the previous one; the implementer should be
  able to go top to bottom.
- Include a step for tests or a runnable example when the change warrants it.
- Call out assumptions and open questions explicitly in a Notes section rather
  than baking an unstated guess into a step.
- Do not pad the plan. A three-line change gets a three-line plan.

## Relationship to Implementation

When work on a planned task begins, the implementer follows the [[tatr]]
workflow: set STATUS to `IN_PROGRESS`, check off / annotate steps as they go,
then set STATUS to `CLOSED` with a record of what changed and any lessons.
The plan's Steps section is the checklist they work through.
