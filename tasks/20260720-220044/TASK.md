# plan skill: DoD-grep proof template excludes tasks/ by default

- STATUS: IN_PROGRESS
- PRIORITY: 90
- TAGS: feature, flow

## Story

As a flow user, I want the plan skill's generated DoD `cmd:` grep proofs to
exclude `tasks/` by default, so that a DoD criterion which quotes a search
string inside its own task record does not self-match. This is the single
most-repeated cross-repo failure (`dod-grep-excludes-task-records`, x5 in this
repo's ledger, and it independently bit tatr and the v2 adoption wave on the
same day).

## Steps

- [x] Locate the plan skill's DoD/grep proof guidance in home/modules/agents/skills/.
- [x] Update the grep template so generated `cmd:` proofs scope out `tasks/` (e.g. `--exclude-dir=tasks` or a ripgrep glob), keeping the skill generic across repos.
- [x] Note the docs-sync rule: this is a skill doc surface; keep the change generic (runs in every repo, not just this one).
- [x] Deploy and confirm the skill text renders (nix flake check --no-build green; skill packaged as a plain file).

## Definition of Done

- The plan skill produces DoD grep proofs that do not match the task file they live in (manual: inspect a freshly planned task's proofs).
- Change is generic, not nix.dotfiles-specific (manual: reviewer confirms no repo-local paths).

## Notes

- Unblocks task #11 (mark `dod-grep-excludes-task-records` promoted once this ships).
- Source lesson recurred x5; promoting prose to template is the "tool > prose" move the ledger keeps asking for.
