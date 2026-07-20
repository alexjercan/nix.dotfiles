# flow docs: write cross-repo task-history immutability policy

- STATUS: OPEN
- PRIORITY: 55
- TAGS: docs,flow

## Story

As a flow user, I want a written cross-repo policy on task-history mutability,
so that future migration-style tasks are unambiguous. During v2 adoption,
nova rewrote `docs/LESSONS` path mentions inside historical task records while
nix.dotfiles left history verbatim and excluded `tasks/` from the grep - both
matched their specs, but there is no unified ruling.

## Steps

- [ ] Draft the policy: historical task records stay verbatim; DoD/sweep greps exclude `tasks/` rather than rewriting history.
- [ ] Decide where it lives (flow skill guidance and/or a shared reference doc) so all repos inherit it.
- [ ] Keep it generic; deploy if it lands in a skill surface.

## Definition of Done

- A single documented policy states whether task history may be rewritten and how greps should scope around it (manual: reviewer reads the policy).

## Notes

- Pairs with task #1 (DoD-grep template) - same underlying tension.
