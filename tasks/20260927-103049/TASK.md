# Add waiting task state to pause continuation until subagent wake

- STATUS: CLOSED
- PRIORITY: 50
- TAGS: pi

Added `waiting` with a required reason to the tasks tool and `/todos` (`w`).
Waiting tasks remain unresolved but do not request settle continuations.
Agents must mark parents waiting when their remaining work depends on a
worker, then resume the tasks when the worker wakes the session. The 19 task
tests, TypeScript typecheck, Nix package build, and Alejandra check passed.

