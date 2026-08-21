# Retain Sprout worktrees after landing

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: sprout, cli

## Goal

Make landing and cleanup separate by default so a landed Sprout worktree and its tmux session remain available for inspection or continued user activity.

## Accepted design

- `sprout land <feature> -m ...` performs the existing guarded squash commit onto the recorded landing target.
- Successful default landing retains the feature branch, worktree, and tmux session.
- Add `--remove` to `sprout land`. It preserves the current post-land cleanup behavior by removing the feature worktree and branch and killing the feature tmux session.
- `-n|--dry-run` remains write-free and accepts `--remove`, validating the invocation that a real land would perform.
- `sprout rm <feature>` remains the explicit standalone cleanup operation after a retained landing.
- Keep existing landing guards, rollback behavior, one-line successful stdout, and exact feature validation.
- Update usage, comments, Sprout skill or documentation, and integration tests.
- No compatibility alias or deprecation period. The new default is intentionally breaking.

## Definition of done

- Default land creates the squash commit and leaves worktree, branch, and tmux session intact.
- `land --remove` creates the squash commit and removes all three resources.
- A later `sprout rm` safely cleans a retained landed feature.
- Dry-run changes nothing with and without `--remove`.
- Failed land leaves main checkout and retained resources in the expected state.
- Existing sync, target, cleanliness, ancestry, message, and rollback guards remain covered.
- Repository guidance and verification evidence match implementation.

## Verification

- `bash home/modules/scripts/sprout-test.sh`.
- Repository-required checks from AGENTS.md.
- `git diff --check`.

## Implementation record

- Changed landing cleanup from implicit to opt-in `--remove`.
- Kept the existing guarded squash and rollback path. Cleanup still uses
  `cmd_rm`, so `land --remove` and standalone `rm` have the same semantics.
- Retained the main-checkout-only guard for one consistent landing contract.
- Added real integration coverage for retained worktrees, branches, and tmux
  sessions; `--remove`; later `rm`; both dry-run forms; and failed landing.
- Updated CLI help and the exported Sprout skill.

## Verification evidence

- `bash home/modules/scripts/sprout-test.sh` - pass, 34 tests.
- `bash -n home/modules/scripts/sprout.sh home/modules/scripts/sprout-test.sh` - pass.
- `git diff --check` - pass.
- `nix flake check` - pass.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` - pass.
- Implementation revision `2226d6b47c40faef30a3aa5c509d7d41172408f2`.
- `sprout sync sprout-retained-land` - pass, already up to date.
- All commands above passed again after synchronization.

## Reflection

- Direct tmux sessions test resource retention and cleanup without attaching a
  client. Teardown records exact session names and does not use broad process
  matching.
- Reusing `cmd_rm` avoids a second cleanup implementation and preserves forced
  worktree removal behavior. The tradeoff is unchanged: cleanup failure can
  follow a successful squash commit, while stdout still contains one landed
  line.
