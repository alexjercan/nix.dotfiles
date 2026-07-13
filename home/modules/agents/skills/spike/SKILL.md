---
name: spike
description: Explore a fuzzy idea or open question before committing to it - brainstorm approaches, weigh tradeoffs, and land on a direction, then capture the research as a durable SPIKE.md in the spike's task folder plus the tatr tasks it seeds. Use this skill when the user asks to spike, ideate, brainstorm, or research an approach with `/spike`, or whenever a request is too fuzzy to plan yet because the real question is "what should we even build here". A spike's output is research and direction-level tasks, not shipped code.
---

# Spike - Ideate and Research Before Committing

A spike is a time-boxed exploration that turns an undefined idea or open
question into a researched direction. It sits at the very front of the
lifecycle, before `/plan`: when a request is still fuzzy - "should we do X?",
"how would we even approach Y?", "is Z worth it?" - you cannot write a clean
plan yet, because the plan itself is the unknown. The spike answers that
question, writes the answer down where it will not evaporate, and seeds the
tatr tasks that turn the chosen direction into work.

The output of a spike is not code. It is a durable research doc - the spike's
own tatr task folder's `SPIKE.md` - plus one or more seeded tasks that
reference it. Because the doc lives in the repo, multiple later `/flow` runs
can build on the same research instead of each session re-deriving it.

## Workflow

1. **Frame the question.** Restate the fuzzy idea as the concrete uncertainty
   the spike exists to reduce - a question with an answer, not a vibe. Write
   down what a good-enough answer looks like and set a rough time-box, so the
   exploration stays bounded and does not slide into building.

2. **Explore - diverge.** Read the relevant code first so the research is
   grounded in what exists, not assumptions. Then think widely: enumerate the
   candidate approaches, look up prior art, sketch how each would work, and
   note the unknowns each one carries. This is the brainstorming step; the
   goal is breadth, so do not converge yet.

3. **Converge on a direction.** Weigh the candidates against each other -
   effort, risk, fit with the codebase, reversibility - and pick a recommended
   direction. Be honest about the runners-up and about what is still unknown; a
   spike is allowed to conclude "not worth doing" or "need more information",
   and that is a successful spike, not a failed one.

4. **Write the research doc.** Create the spike's own task
   (`tatr new "Spike: <question>" -t spike`) and save the doc as
   `tasks/<id>/SPIKE.md` (format below); close the spike task once the doc
   is written - the seeded tasks carry the work forward. This doc is the
   spike's primary, long-lived deliverable; write it to be read cold by a
   future session that was not here.

5. **Seed the tasks.** Turn the recommended direction into one or more tatr
   tasks with `tatr new` (see the tatr skill; one call per command, never
   chained). Keep them coarse and direction-level - a Goal, a
   `Spike: tasks/<id>/SPIKE.md` link in Notes, and a `spike` tag - not a
   detailed Steps list. Breaking a task into Steps
   is `/plan`'s job, and it runs later when the task is picked up (tatr's rule
   that a stepless ad-hoc task is planned first with `/plan` applies here).
   Spike owns the what and why; plan owns the how. If the spike concluded "do
   not build", create no tasks and say so in the doc.

6. **Report back.** Summarize the recommendation in a sentence or two, point at
   the spike doc, and list the task IDs it seeded. Offer to commit the doc and
   tasks. Do not start implementing; that is `/work`'s job, driven from the
   tasks this spike created.

## Spike Doc Format

```markdown
# Spike: Should the API use a token bucket or a sliding window?

- DATE: 20260704-130606
- STATUS: RECOMMENDED   # RECOMMENDED | INCONCLUSIVE | DROPPED
- TAGS: spike, api, ratelimit

## Question

The one uncertainty this spike set out to reduce, and what a good answer
looks like.

## Context

What already exists that constrains the answer - relevant code, prior
decisions, requirements. Ground the reader in one paragraph.

## Options considered

- **Token bucket** - how it works here; pros; cons; unknowns.
- **Sliding window** - how it works here; pros; cons; unknowns.
- **Do nothing** - always a candidate; what it costs to defer.

## Recommendation

The chosen direction and the reasons it beat the runners-up. Concrete enough
that a planner can expand it into steps without re-litigating the choice.

## Open questions

- What is still unknown, and what would resolve it (a follow-up spike, a
  measurement, a user decision).

## Next steps

Direction-level tasks this spike seeded, for `/plan` to break into steps:

- tatr 20260704-131500: build the token-bucket rate limiter
- tatr 20260704-131530: expose the rate as a config knob

## Fix record

(Only for spikes that seed MULTIPLE tasks.) Each implementing task
appends a few lines here as it lands - what shipped, the headline
number, a pointer to its TASK.md - so this doc stays the family's
single source of current state and later cycles start here instead of
re-reading every sibling task. Keep entries short; the task file holds
the detail.
```

## Guidelines

- Time-box and stay exploratory. A spike buys information; the moment you are
  writing production code you have left the spike and should be in `/work` on
  one of the tasks it seeded.
- A negative result is a real result. "Explored X, not worth it because ..."
  saved a future flow from the same dead end - write it down as a `DROPPED`
  spike doc even though it spawns no tasks.
- Make the doc self-contained. A later flow should need only the spike doc,
  not this session's chat, to pick up the work - so capture the reasoning and
  the rejected options, not just the conclusion.
- Diverge before you converge. If you only ever considered one approach, you
  did not spike; you guessed. Name the alternatives even when the answer is
  obvious, so the reader can trust it was actually weighed.
- Do not pad. A small question gets a short doc. The value is in the decision
  and its reasons, not in length.

## Relationship to the Other Skills

Spike is the front of the funnel, one step before `/plan`. Where `/plan` takes
a *defined* feature and mechanically breaks it into ordered steps, spike takes
an *undefined* problem and figures out what the feature should be in the first
place - so a fuzzy request is spiked first, then its seeded direction-level
tasks are planned into steps and built. The full lifecycle is: `/spike`
explores, `/plan` scopes, sprout
isolates, `/work` implements, `/review` critiques, `/compound` distills, and
`/flow` drives the whole loop. A spike's SPIKE.md is durable and
shared: several tasks - and several separate `/flow` runs - can all cite
the same research, which is the point of writing it down rather than deciding
in the moment and forgetting why.
