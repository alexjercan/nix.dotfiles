# Decision: Quote afk status labels

- DATE: 20260808-151224
- STATUS: ACCEPTED
- TASK: 20260808-151209
- TAGS: bug,afk

## Context

The afk package treats ShellCheck findings as build failures. Two output calls
pass the shell keyword `done` as an unquoted argument, which triggers SC1010.
The output text and control flow must stay unchanged.

## Decision

Quote both `done` arguments. This makes their string role explicit without
changing behavior.

## Alternatives considered

- Rename the label. Rejected because it changes user-visible output.
- Suppress SC1010. Rejected because the source remains ambiguous.
- Do nothing. Rejected because home-manager cannot build the package.

## Consequences

The afk derivation can pass ShellCheck and the output remains stable. The
change adds no new behavior or configuration.
