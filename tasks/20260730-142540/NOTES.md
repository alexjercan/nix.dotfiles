# Design refinement: Wayfinding, parallelism, and retained prototypes

User feedback after the source spike refined these requirements.

## Tatr-native wayfinder

Represent the hierarchy as Epic -> Stories. The Epic is a compact context map,
not a copy of every Story:

- Destination: what completing the Epic means.
- Decisions: one-line answers with links to their owning records.
- Frontier: unblocked, unclaimed Stories available now.
- Fog: in-scope questions not yet precise enough to become Stories.
- Out of Scope: explicit boundaries.

Each Story is sized for one context and owns its detailed task, plan, review,
and retro. Research, decision, and prototype tasks may precede Stories; their
answers graduate Fog into concrete Stories.

Add web research as a wayfinder/spike branch. Prefer primary sources, save
cited findings in the owning task folder, and put only a one-line answer plus
pointer in the Epic. Independent research tasks are safe to run in parallel.

## Retained prototypes

Call these exploratory prototypes, not throwaway prototypes. Select storage by
repository policy:

1. Use AGENTS.md when it names the location.
2. Use an established repo-native location such as Rust `examples/` or a
   project `scripts/`/`demos/` directory.
3. Otherwise use `tasks/<id>/prototype/`.
4. Ask the user only when more than one placement has meaningful consequences,
   then cache the answer in AGENTS.md.

A prototype in `examples/` or `scripts/` is a supported artifact: land it,
document its run command, and keep it covered by the relevant build/smoke
check. A task-local prototype is retained evidence: keep its command, result,
and limitations with the task without presenting it as production surface.

Spike routes among research, logic prototype, UI prototype, or mixed evidence.
Its answer records the artifact path, run command, observations, and verdict.
Accepted behavior still enters normal plan/work/review with production tests.

## Conditional parallel planning

Use one planner by default. Use independent parallel planners for a
load-bearing design fork, multiple independent domains, an Epic too large for
one context, or an explicit request for alternatives. Give each the same
read-only packet and a different lens. Persist only the selected plan and the
decision rationale.

## Conditional parallel review

Keep the local review format and one final severity-ranked verdict.

- Trivial change: one in-session reviewer.
- Normal substantive change: the current fresh out-of-context reviewer.
- High-risk change: parallel independent lanes for behavior/proofs,
  correctness/security/concurrency as applicable, and
  design/standards/docs.

Select high-risk review from consequences, not line count: authentication,
authorization, secrets, persistence/migrations, concurrency, public APIs,
shared infrastructure, or a broad cross-module contract. Each lane returns
bounded findings. The primary reviewer verifies, deduplicates, assigns local
severities, and writes one REVIEW.md round.

## Vocabulary clarification

`Low-resolution map` means a compact Epic index. An agent reads the Epic's
destination, decisions, frontier, fog, and scope, then opens only the active
Story. Rename the concept to `context map` or `Epic index` in the local suite.

`Leading words` means stable short terms that replace repeated explanations.
For example, `frontier` means "unblocked and unclaimed Stories ready now."
Project domain vocabulary can have the same benefit. Use only terms that recur
and save real explanation; do not create a glossary for its own sake.
