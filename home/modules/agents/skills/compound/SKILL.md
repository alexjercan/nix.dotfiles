---
name: compound
description: Write a task retro after its review is APPROVEd and submit reusable observations. Use for `/compound` before landing.
---

# Compound - Retro After Review

RETRO records one-off process and failed observation writes. TASK records the
change; REVIEW records findings.

## Workflow

1. Require latest REVIEW.md APPROVE and clean
   `tatr -r <task-root> check <id>`. Under flow, require COMPOUNDING.
   Otherwise stop unless the user explicitly requests an unfinished retro.
2. Re-read TASK.md, every review round, the branch log, and any
   `Process signal:` bullets or recorded checkpoints. Compare the original
   Story and Steps against the final diff. Identify practices to repeat,
   failures and root causes, and actionable improvements.
3. Run `tatr -r <task-root> scaffold <id> RETRO`; fill it briefly and
   blamelessly. Name the failed decision and why it seemed sound then. Append a
   `## Landing message` section: a fenced Conventional-Commit subject, blank
   line, short body - one summary of the finished task, not the concatenated
   branch messages.
4. Submit reusable observations through the `knowledge` skill with project and
   task provenance. Pass an explicit `--repo`; the default writes a shadow
   lesson tree into this checkout and reports success. Do not search,
   promote, ask disposition, or block DONE when the central checkout is
   unavailable; keep that signal in RETRO.
5. Under flow, run `tatr -r <task-root> flow <id>`, which earns the `RETRO`
   gate and resolves the record `DONE`, then commit retro and close
   together. DONE -> LAND_READY without landing. Outside flow,
   commit retro on the feature branch. If already landed, first verify the
   main checkout branch, then commit there.

Do not duplicate prose across records; a recurring pattern belongs in the
central knowledge repository.

## Diagnose

Answer three questions, each only from what the records show:

- Breadth: ask why the diff grew. Inherently large feature, a missed
  independently landable split, a weak ownership boundary, scope found late, or
  a plan that encoded the wrong design? A large diff is a question, not a
  verdict.
- Churn: which plan-time question would have prevented this review rework -
  the from-scratch challenge in `plan`, or the cold-reader rationale test in
  `plan/decision.md`? The plan is the subject of that answer, never the worker.
- Context: record only observed context pressure - a threshold
  crossing, a compaction warning, a handoff, a delegation - and what to split,
  delegate, defer, or load later next time. Never invent a token count no
  record holds.

## Output

New/bumped slugs and follow-up IDs; at most 100 words. Under flow, only after
DONE return the gate status `LAND_READY <id>` without landing.
