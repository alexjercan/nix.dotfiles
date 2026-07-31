#!/usr/bin/env bash
# Assert that VERIFICATION.md records EVERY canonical check with its result.
#
# The weaker form of this proof - counting `exit=0` anywhere in the file - stays
# green after five of the six rows are deleted, so it never proved the criterion
# it was attached to. This names each command and requires its own row, with the
# exit status on the same line.
set -euo pipefail

record="$(dirname "$0")/VERIFICATION.md"

# One extended regex per canonical check, anchored so that `tatr check` cannot
# be satisfied by the `tatr check --ledger` row (or vice versa).
rows=(
  '^\$ tatr check +exit=[0-9]+$'
  '^\$ tatr check --ledger LESSONS\.md +exit=[0-9]+$'
  '^\$ python3 tasks/20260730-155003/tatr-rev\.py +exit=[0-9]+$'
  '^\$ bash home/modules/agents/skills/check\.sh +exit=[0-9]+$'
  '^\$ bash home/modules/scripts/sprout-test\.sh +exit=[0-9]+$'
  '^\$ nix flake check --no-build +exit=[0-9]+$'
)

missing=0
for row in "${rows[@]}"; do
  if ! grep -qE "$row" "$record"; then
    echo "MISSING: no row matching /$row/ in $record"
    missing=$((missing + 1))
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "FAIL: $missing canonical check(s) unrecorded"
  exit 1
fi

# A row that records a FAILING check is not a pass either.
if grep -nE '^\$ .+ +exit=[1-9][0-9]*$' "$record"; then
  echo "FAIL: the record above shows a canonical check that did not exit 0"
  exit 1
fi

echo "OK: all ${#rows[@]} canonical checks recorded, all exit=0"
