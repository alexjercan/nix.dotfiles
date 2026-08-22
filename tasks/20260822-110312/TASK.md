# Make global agent prose audience-aware

- STATUS: CLOSED
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

## Implementation

Updated `home/modules/agents/AGENTS.md` only. Added the four accepted
`Core rules` statements and removed the old preferred sentence-template rule.
The Home Manager module deploys this source as `~/AGENTS.md` and
`~/.codex/AGENTS.md`.

## Evidence

Implementation revision:
`2b52634363c315f897efa8c753f234933a4fdf70`. `sprout sync audience-aware-prose`
reported already up to date with landing target
`23181648517866f20331e6b69e2025a36fe6ebeb`.

Post-synchronization verification:

- Exact fixed-line counts: each accepted rule occurs once.
- Old template fixed-string count: zero.
- `nix flake check`: passed.
- `nix build .#homeConfigurations.alex.activationPackage --no-link`: passed.
- `git diff --check`: passed before commit and after synchronization.

Activation and deployed-copy comparison remain deferred to the separate review
and activation step. This task did not activate Home Manager.
