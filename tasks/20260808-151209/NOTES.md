# Notes: Quote afk status labels

## Problem Statement

`home-manager switch --flake .#alex` cannot build the `afk` package because
ShellCheck reports SC1010 as a build failure.

Not this: clean the dirty Git tree or fix the unrelated deprecated `system`
evaluation warning.

## Context

- Surface: `home/modules/scripts/afk.sh` lines that print landing status.
- Constraint: preserve the existing output and control flow.
- Constraint: leave existing `flake.nix` and `flake.lock` changes untouched.
- Evidence: ShellCheck identifies bare `done` arguments at lines 429 and 484.
- Unknowns: none.

## Ideas

### 1. Quote the status label

Pass `"done"` as an ordinary argument. Minimal change; preserves output.

### 2. Rename the status label

Use a different word that is not a shell keyword. Avoids the warning but
changes user-visible output without a requirement.

### 3. Suppress SC1010

Add a ShellCheck exception. Keeps source ambiguous and hides a valid parser
warning.
