---
name: compound
description: Write a task retro after its review is APPROVEd and fold the lessons into the ledger. Use for `/compound` before landing.
---

# Compound - Retro After Review

RETRO records process. TASK records the change; REVIEW records findings.

## Workflow

1. Require latest REVIEW.md APPROVE and clean `tatr check <id>`. Under flow,
   require COMPOUNDING. Otherwise stop unless the user explicitly requests an
   unfinished retro.
2. Re-read TASK.md, every review round, and branch log. Identify practices to
   repeat, specific failures and root causes, and actionable improvements.
3. Run `tatr scaffold <id> RETRO`; fill it briefly and blamelessly. Name the
   failed decision and why it seemed sound then.
4. Search the ledger. Append or bump each general lesson: slug, one sentence,
   bare count, task IDs; two lines maximum. Mark skill-specific candidates
   with `-> <skill> skill`.
5. At occurrence three, move the bare-count entry to Pending promotions and
   propose `tool > template/format > skill prose`. Record no disposition and
   ask nothing here; `lessons` owns the user gate. Follow-up implementation
   gets a new task. Keep one-offs only in RETRO.
6. Commit retro and ledger on the feature branch before landing. If already
   landed, first verify the main checkout branch, then commit there.

Do not duplicate prose across records. A recurring pattern belongs in the
ledger, not every close-out.

## Output

New/bumped slugs and follow-up IDs; at most 100 words. Then `tatr flow <id>`
moves COMPOUNDING to DONE.
