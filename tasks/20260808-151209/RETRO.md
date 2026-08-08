# Retro: Quote afk status labels

- TASK: 20260808-151209
- BRANCH: fix/afk-status-labels
- REVIEW ROUNDS: 1

## What went well

The build log named both faulty lines and the exact ShellCheck rule. The
source-shape proof was red before the edit. Integration tests and the
activation build passed after a two-token quoting fix. Review found no issues.

## What went wrong

Bare `done` labels reached the branch because the behavioral integration suite
does not run ShellCheck. The Nix derivation was the first static-analysis gate.

## What to improve next time

Quote display labels that match shell grammar words. For `writeShellApplication`
scripts, run the owning Nix build as well as direct script tests.

## Action items

No follow-up task. Submit the shell-keyword quoting rule as a reusable
observation.

## Landing message

```
fix(afk): quote status labels

Quote two `done` display arguments so the writeShellApplication ShellCheck
gate accepts afk without changing its output.
```
