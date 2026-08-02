---
name: spike
description: Research a fuzzy question before committing, leaving a SPIKE.md and the tasks it seeds. Use for `/spike` when the open question is what to build.
---

# Spike - Research Before Planning

Output: durable evidence and seeded tasks, never production code.

## Workflow

1. Turn the fuzzy idea into an answerable uncertainty. Define sufficient
   evidence and a rough time-box.
2. Read relevant code, then choose evidence: repository-external facts use
   research; running behavior uses logic/UI prototype; mixed evidence uses
   both, facts first. Compare real alternatives and their unknowns.
3. Rank candidates by effort, risk, fit, and reversibility. Recommend one;
   `DROPPED` and `INCONCLUSIVE` are valid.
4. Run one command at a time:

   ```bash
   tatr new "Spike: <question>" -k SPIKE -t spike
   tatr -r <task-root> scaffold <id> SPIKE
   ```

   Fill a cold-readable SPIKE.md with reasoning, rejected options, open
   questions, and a citation or reproducible artifact/command for every
   claim. Status: `RECOMMENDED`, `INCONCLUSIVE`, or `DROPPED`.
5. Put a settled load-bearing call in the owning task's DECISION.md. Seed
   coarse tasks with a spike pointer/tag and list them in `## Next steps`; do
   not write their Steps. Exploratory code remains evidence. A DROPPED spike
   seeds nothing. For multiple tasks add `## Fix record`, updated briefly as
   each lands. Under an Epic, update its Decisions/Fog index.
6. Close the spike through normal REVIEW.md, RETRO.md, and tatr gates; review
   the document's evidence and conclusion.

## Rules

- Stop when production implementation starts.
- Preserve useful negative results.
- A preference without evidence stays reversible: one tunable, normal later
  reversal.
- Do not pad.

## Output

Recommendation, open risk, doc, seeded task IDs; at most 120 words, ending
`SPIKED <id>`.

## Load on demand

- external/current facts or mixed evidence -> `research.md`
- runnable logic/UI prototype or mixed evidence -> `prototype.md`
