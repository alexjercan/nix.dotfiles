# flow docs: write cross-repo task-history immutability policy

- STATUS: CLOSED
- PRIORITY: 55
- TAGS: docs, flow

## Story

As a flow user, I want a written cross-repo policy on task-history mutability,
so that future migration-style tasks are unambiguous. During v2 adoption,
nova rewrote `docs/LESSONS` path mentions inside historical task records while
nix.dotfiles left history verbatim and excluded `tasks/` from the grep - both
matched their specs, but there is no unified ruling.

## Steps

- [x] Draft the policy: historical task records stay verbatim; DoD/sweep greps exclude `tasks/` rather than rewriting history.
- [x] Decide where it lives (flow skill guidance and/or a shared reference doc) so all repos inherit it.
- [x] Keep it generic; deploy if it lands in a skill surface.

## Definition of Done

- A single documented policy states task history is immutable/verbatim and that sweeps/DoD greps exclude tasks/ (manual: reviewer reads the policy).
- The policy is stated in the work skill sweep step and cross-referenced from the flow skill (cmd: `grep -rn "append-only" home/modules/agents/skills/`).

## Notes

- Pairs with task #1 (DoD-grep template) - same underlying tension.
