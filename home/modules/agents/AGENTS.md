# AGENTS.md

Global guidelines for agent sessions. Keep these in mind for all work.

## Writing style

- Do not use em dashes or other typographic characters (smart quotes, ellipsis chars, arrows, etc).
- Stick to plain ASCII-adjacent programmer syntax: `-`, `--`, `...`, `->`, straight quotes.
- This applies to code, comments, docs, commit messages, and chat output.

## Commits

- Do not add a Claude co-author trailer or any AI attribution to commits. Write plain commit messages authored by me only.

## Technical decisions

- Do not factor implementation time into technical decisions. Agents write code much faster than humans, so "this would take too long" is not a valid argument.
- Choose the approach that is correct, maintainable, and well-designed, even if it means more code, more refactoring, or more tests.

## Testing and examples

- Prefer integration tests and end-to-end example scripts over isolated unit tests where practical.
- When building a substantial component, consider shipping a small runnable example that exercises it end to end:
  - a parsing module can get its own example CLI
  - an algorithm can get a small GUI or visualization
  - a web-facing feature can get a demo HTML page
- These are not mandatory. Treat them as easy wins: if the user wants one or it is cheap to add, do it.

## Shell and verification

- Never end a build/test command with a pipe or echo that eats its exit code (`cargo test | grep ...` reports grep's 0 on a failed compile). Run it bare, or write output to a file and grep the file, or `set -o pipefail`.
- Kill helper processes by recorded PID, never `pkill -f <pattern>` - the pattern can match your own shell's command line or an unrelated process.
- An edit you believe you made is a hypothesis until the artifact shows it; re-read the produced text, not just the tool's success report.

## Documentation and reflection

After meaningful changes, document:

- What changed and why the decision was made (alternatives considered, tradeoffs).
- Difficulties encountered and any bugs that came up along the way, including how they were diagnosed and fixed.
- Self-reflected feedback: what could have gone better during the implementation, and what to do differently next time. This is for future sessions to learn from.

Keep these notes where the repository's own AGENTS.md says records live (task folders, a wiki, a lessons ledger). Only default to the repository's `docs/` folder when it defines no convention of its own.
