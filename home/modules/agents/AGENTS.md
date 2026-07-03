# AGENTS.md

Global guidelines for agent sessions. Keep these in mind for all work.

## Writing style

- Do not use em dashes or other typographic characters (smart quotes, ellipsis chars, arrows, etc).
- Stick to plain ASCII-adjacent programmer syntax: `-`, `--`, `...`, `->`, straight quotes.
- This applies to code, comments, docs, commit messages, and chat output.

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

## Documentation and reflection

After meaningful changes, document:

- What changed and why the decision was made (alternatives considered, tradeoffs).
- Difficulties encountered and any bugs that came up along the way, including how they were diagnosed and fixed.
- Self-reflected feedback: what could have gone better during the implementation, and what to do differently next time. This is for future sessions to learn from.

Keep these notes in the repository's `docs/` folder, which is where all project documentation is expected to live, so future agent sessions can pick up the context.
