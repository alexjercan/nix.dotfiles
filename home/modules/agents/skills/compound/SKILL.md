---
name: compound
description: Write a task retro after its review is APPROVEd and fold the lessons into the ledger. Use for `/compound` before landing.
---

# Compound - Retro After Review

RETRO records one-off process, LESSONS recurring lessons. TASK records the
change; REVIEW records findings.

## Workflow

1. Require latest REVIEW.md APPROVE and clean `tatr check <id>`. Under flow,
   require COMPOUNDING. Otherwise stop unless the user explicitly requests an
   unfinished retro.
2. Re-read TASK.md, every review round, the branch log, and any
   `Process signal:` bullets or recorded checkpoints. Compare the original
   Story and Steps against the final diff. Identify practices to repeat,
   specific failures and root causes, and actionable improvements.
3. Run `tatr scaffold <id> RETRO`; fill it briefly and blamelessly. Name the
   failed decision and why it seemed sound then.
4. Search the ledger. Append or bump each general lesson: slug, one sentence,
   bare count, task IDs; two lines maximum. Mark skill-specific candidates
   with `-> <skill> skill`.
5. At occurrence three, move the bare-count entry to Pending promotions and
   propose `tool > template/format > skill prose`. Record no disposition and
   ask nothing here; `lessons` owns the user gate. Follow-up implementation
   gets a new task. Keep one-offs only in RETRO.
6. Under flow, run `tatr flow <id> --to DONE`, then commit retro, ledger, and
   close together. DONE -> LAND_READY without landing. Outside flow, commit
   retro and ledger on the feature branch. If already landed, first verify the
   main checkout branch, then commit there.

Do not duplicate prose across records. A recurring pattern belongs in the
ledger, not every close-out.

## Diagnose

Answer three questions, each only from what the records show:

- Breadth: ask why the diff grew. Inherently large feature, a missed split that
  was independently landable, a weak ownership boundary, scope found late, or a
  plan that encoded the wrong design? A large diff is a question, not a verdict.
- Churn: which plan-time question would have prevented this review rework -
  the from-scratch challenge in `plan`, or the cold-reader rationale test in
  `plan/decision.md`? The plan is the subject of that answer, never the worker.
- Context: record only measured or observed context pressure - a threshold
  crossing, a compaction warning, a handoff, a delegation - and what to split,
  delegate, defer, or load later next time. Never invent a token count no
  record holds.

## Output

New/bumped slugs and follow-up IDs; at most 100 words. Under flow, only after
DONE return the gate status `LAND_READY <id>` without landing.
