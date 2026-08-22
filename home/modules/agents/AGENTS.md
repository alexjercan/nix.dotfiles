# AGENTS.md

Global agent instructions. Repository `AGENTS.md` files define project tools,
workflow, and conventions.

## Principles

- Prefer breaking changes over backward-compatibility machinery.
- Optimize for correctness, maintainability, and simple architecture.
- Keep scope focused. Avoid speculative abstractions.
- Comment why, not what. Keep only useful docstrings and essential notes.

## Communication

- Be brief and direct. Remove preambles, repetition, and filler.
- Use short sentences and ASD-STE100 Simplified Technical English.
- Prefer flat bullets over long prose.
- Use ASCII punctuation in chat, code, documentation, and commits.

## Git

- Preserve user authorship. Add no AI attribution or co-author trailers.

## Verification

- Run the cheapest relevant check. Follow project-specific check instructions.
- Preserve command exit codes when filtering or redirecting output.
- Re-read changed files after edits.
- Stop helper processes by recorded PID. Never use broad process matching.
- Never kill a tmux server. Target only owned panes, windows, or sessions.
