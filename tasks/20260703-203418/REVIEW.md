# Review: Write Claude Code skills for `daily` and `today`

- TASK: 20260703-203418
- BRANCH: agent-daily-today
- ROUND: 1
- VERDICT: APPROVE

## Summary

Reviewed the two new SKILL.md files against the shipped behavior of `today`
and `daily`. Frontmatter matches the house style (name + selection-oriented
description), commands and exit codes match the built binaries' `--help`, and
the agent-facing contracts (stdout-is-just-the-path; `--json` object shape and
index semantics) are documented accurately. Approve.

## Findings

### [info] Docs derived from the built binaries, not memory
The command tables and exit codes were taken from the actual `--help` of the
built `today`/`daily` derivations, so they cannot drift from what shipped in
the other two tasks.

### [info] Wiring confirmed, not assumed
`agents/default.nix` links `./skills` with `recursive = true`; the new `today/`
and `daily/` dirs appear in the branch tree and need no module change. A real
`nix eval` of `homeConfigurations.alex` resolves both scripts, and both
derivations build (shellcheck) from the real config.

### [low] JSON example uses `16.0`, output emits `16.00`
The `--json` example shows `"protein": 16.0` while the tool prints `16.00`.
Both are the same JSON number; the example is illustrative. Non-blocking.

## Verdict

APPROVE. Skills are accurate, cross-referenced, and consistent with the
existing skill set.
