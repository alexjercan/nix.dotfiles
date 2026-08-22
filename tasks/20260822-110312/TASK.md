# Make global agent prose audience-aware

- STATUS: OPEN
- PRIORITY: 100
- TAGS: agents, writing

## Goal

Reduce irrelevant scope disclaimers and mechanical sentence templates across agent chat, documentation, comments, plans, reviews, and reports.

## Accepted change

In the deployed global agent instructions:

- Add: `Write for the audience. Include only facts they need.`
- Add: `State present behavior directly. Mention absence only when consequential.`
- Add: `Keep compliance evidence separate from the result.`
- Replace the preferred `User can...`, `Handles...`, and `Requires:` sentence templates with: `Name the actor and action when responsibility matters.`

Keep the rules in `Core rules`. Preserve the existing terse bullet style. Do not add documentation-specific workflow or task-record guidance.

## Verification

- Confirm the source instructions contain the exact accepted rules once.
- Confirm the old sentence-template rule is absent.
- Run repository checks and build the Home Manager activation package.
- Review before activation.
- After activation, confirm `~/AGENTS.md` matches the source.
