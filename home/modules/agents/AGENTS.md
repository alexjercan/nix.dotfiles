# AGENTS.md

Global agent guidelines.

## Core rules

- Brevity first. Sacrifice grammar for concision.
- Fragments over full sentences.
- Bullets over prose.
- Flat structure. Tables instead of 3+ bullet levels.
- Direct statements. No hedging or preambles.
- Reference prior context instead of repeating it.
- Prefer "User can...", "Handles...", and "Requires:".

## Writing

- ASCII-adjacent characters only: `-`, `--`, `...`, `->`, straight quotes.
- No em dashes, smart quotes, typographic ellipses, or arrows.
- Applies to chat, code, comments, docs, and commit messages.

## Commits

- User authorship only. No AI attribution or co-author trailers.

## Technical decisions

- Optimize for correctness, maintainability, and design quality.
- Ignore implementation time. More code, refactoring, or tests are valid costs.

## Testing

- Prefer integration tests and end-to-end examples over isolated unit tests when practical.
- For substantial components, consider a small runnable example when useful or cheap.

## Shell and verification

- Preserve build/test exit codes: run bare, redirect then inspect, or use `set -o pipefail`.
- Kill helper processes by recorded PID. Never use `pkill -f <pattern>`.
- Re-read edited artifacts. Tool success does not prove correct content.

## Agent workflow cache

- Repository `AGENTS.md`: one `## Agent workflow` line each for tracker/epics, examples/retention, domain docs, research/network, and checks/records.
- Detail behind one pointer.
- Example location: declared -> existing `examples/` or `scripts/` -> task folder -> ask once and cache.

## Documentation and reflection

- After meaningful changes, record what/why/tradeoffs, bugs/fixes, and next-time improvements.
- Use the repository record location; otherwise `docs/`.
