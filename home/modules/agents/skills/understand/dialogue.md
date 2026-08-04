# Talking to the user

This phase is the one place in the cycle where asking beats assuming. The
default elsewhere - proceed on a recorded assumption - is suspended here: a
wrong problem costs the whole task, and the user is the only source for what
the tree cannot say.

Use the runtime's blocking question tool when there is one. Otherwise ask, and
end the turn.

## 1. Confirm the problem

Before writing anything, restate the problem in one or two sentences and ask
whether that is the thing to solve. Offer the two answers plainly: it is
right, or it is not. Never a leading third option.

A rejection is information, not a failure: take what the user says, restate
again, and ask again. Loop until it is confirmed. Do not soften a restatement
into something agreeable to get a yes - a restatement the user corrects twice
means the problem is bigger than the goal line said, and that is worth
learning now.

## 2. Ask for context

Ask only what the tree cannot answer: intent, priority, a constraint that
lives in the user's head, an external system, a preference between two costs.
One question at a time. Read the code first and say what you already found, so
the question is narrow.

Stop asking when the next question would not change any idea. Curiosity is not
a requirement.

## 3. Put the choices

Not a summary and not a request for approval. Ask about the decisions the
ideas actually disagree on, one at a time, each with the concrete options and
what each costs:

- which shape or mechanism,
- which data structure or interface,
- what is deliberately left out,
- which risk is acceptable.

State your recommendation and why it beat the runner-up. An answer that picks
differently sends you back to ideation with that answer as a new constraint in
`## Context`. An answer that changes what the problem is sends you back to
step 1 - and the earlier sections are rewritten, not patched.

Three or four questions is the whole quiz. If it takes more, the context is
thin: go read.

## When nobody is there

An unattended run - `afk`, a cron job, any session with no reachable user -
cannot answer any of this. Do not stall, and do not invent an answer.

Take your own restatement as the problem, record every question you would have
asked as an `Assumption:` line in `## Context`, mark the decision record's
open risks with them, and carry on. The gate that follows is where a human
sees it. An assumption that the ideas cannot survive being wrong about is the
exception: stop there and report rather than guess.
