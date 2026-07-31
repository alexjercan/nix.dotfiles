---
name: spike
description: Research a fuzzy question before committing, leaving a SPIKE.md and the tasks it seeds. Use for `/spike` when the open question is what to build.
---

# Spike - Research Before Committing

A spike is a time-boxed exploration that turns an undefined idea into a
researched direction. It sits before `plan`: when the plan itself is the
unknown, there is nothing to break into steps yet.

The output is a durable `tasks/<id>/SPIKE.md` plus the tasks it seeds - not
production code. Because the doc lives in the repository, later cycles build
on the same research instead of re-deriving it.

## 1. Frame the question

Restate the fuzzy idea as the concrete uncertainty the spike exists to reduce
- a question with an answer, not a vibe. Write down what a good-enough answer
looks like and set a rough time-box.

## 2. Route to a mode

Ask what evidence would actually settle the question, then load that branch.

- Facts this repository cannot answer -> research.
- A behavior only a running thing can show -> a logic or UI prototype.
- Both -> mixed evidence: settle the facts first, build against them second.

Read the relevant code first whichever way it goes, so the exploration is
grounded in what exists. Then diverge: enumerate the candidate approaches,
sketch how each would work here, and note the unknowns each carries. If you
only ever considered one approach you did not spike, you guessed.

## 3. Converge

Weigh the candidates on effort, risk, fit and reversibility, and pick a
recommended direction. Be honest about the runners-up and what is still
unknown. "Not worth doing" and "need more information" are successful spikes.

## 4. Write the doc

```bash
tatr new "Spike: <question>" -k SPIKE -t spike
tatr scaffold <id> SPIKE
```

Fill the scaffolded `tasks/<id>/SPIKE.md`. Write it to be read cold by a
session that was not here: the reasoning and the rejected options, not just
the conclusion. `- STATUS:` is `RECOMMENDED`, `INCONCLUSIVE` or `DROPPED`.
Every claim carries what backs it - a citation, or an artifact path and the
command that reproduces its result.

## 5. Route the result

A recommendation is a hypothesis that survived, not a shipped feature.

- The load-bearing choice it settles becomes a `DECISION.md` on the owning
  task: the spike doc holds the evidence, the decision record holds the call.
- Seed coarse tatr tasks - a Story, a `Spike: tasks/<id>/SPIKE.md` pointer in
  Notes, a `spike` tag - and list each under the doc's `## Next steps`, which
  `tatr check` resolves. One `tatr new` per command, never chained: a
  same-second ID collision fails the call and kills the rest of the chain. Do
  NOT write their Steps; that is `plan`'s job when the task is picked up.
- Those planned Stories carry the behavior into production through the normal
  work and review lifecycle, with production tests. Exploratory code is
  evidence; it is never presented as production surface.
- A DROPPED spike seeds nothing, and the doc says so.
- Under an Epic, the result is one line in its Decisions index, plus a Fog
  line for any new question it opened.

When the spike seeds MORE THAN ONE task, give the doc a `## Fix record`
section. Each implementing task appends a few lines there as it lands, so the
doc stays the family's single source of current state and a later cycle starts
here instead of re-reading every sibling task.

## 6. Close the spike task

A spike task is a task: it still owes a REVIEW.md and a RETRO.md before
`tatr flow --to DONE` will close it. The review reviews the DOC - is the
question answered, are the alternatives real, does the recommendation follow
from the evidence.

## Guidelines

- Time-box. The moment you are writing production code you have left the
  spike and should be in `work` on a task it seeded.
- A negative result is a real result. Write the `DROPPED` doc; it saves a
  future flow from the same dead end.
- Make the doc self-contained. A later flow should need only the doc, not this
  session's chat.
- A recommendation resting on "which feels better" is a hypothesis, not a
  verdict. Keep the deciding parameter a single tunable so the reversal is a
  one-line change, and treat a later reversal as a normal cycle.
- Do not pad. A small question gets a short doc.

## Output

The recommendation, the open risk, and links to the doc and seeded task IDs -
120 words or fewer, ending with `SPIKED <id>`.

## Load on demand

Read one ONLY when its condition holds. Mixed evidence reads both.

- research settles it - external or current facts, or mixed evidence -> `research.md`
- a runnable logic or UI prototype, or mixed evidence -> `prototype.md`
