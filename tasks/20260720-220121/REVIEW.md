# Review

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

**What I tried to break.** I read TASK.md for the DoD, then diffed master against the branch and ran the DoD proof grep (`grep -rn "append-only"`), which returns exactly two hits: work/SKILL.md:115 and flow/SKILL.md:267 - the primary statement and the cross-reference, as required. I probed for the three failure modes a policy like this invites: (1) vagueness - does it actually assert history is verbatim and that greps exclude `tasks/`? It does, unambiguously: "TASK-HISTORY IS IMMUTABLE", "leave the history verbatim", "EXCLUDE it from the sweep (`--exclude-dir=tasks`...)", and it names the concrete records (TASK/REVIEW/RETRO/NOTES) that must not be rewritten. (2) contradiction with the plan skill - I read plan/SKILL.md:120-126, whose absence-proving DoD-grep guidance already tells greps to exclude `tasks/`; the new work-skill text explicitly points at it ("This is why absence-proving DoD greps also exclude `tasks/` (plan skill)") and they reinforce rather than conflict. (3) repo-locality/overclaim - the nova/nix.dotfiles divergence is presented as an illustrative parenthetical example, not a hard dependency; the rule itself is generic. I checked the flow<->work cross-reference for mutual consistency: flow/SKILL.md says the trail is "append-only history... EXCLUDE the `tasks/` tree... History stays verbatim" and points to both the work sweep step and plan DoD greps, matching the work-skill statement. Markdown renders cleanly (the `--exclude-dir=tasks` and path fragments are inline code / plain prose inside existing list items, no broken fences). The only non-substantive diff noise is a TAGS whitespace normalization (`docs,flow` -> `docs, flow`) in TASK.md, which is harmless.

- No findings.
