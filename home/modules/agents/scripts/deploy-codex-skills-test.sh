#!/usr/bin/env bash

set -euo pipefail

DEPLOY=${DEPLOY_CODEX_SKILLS:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/deploy-codex-skills.sh"}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
root="$tmp/codex"
mkdir -p "$tmp/alpha" "$tmp/beta" "$tmp/broken" "$root/.system" "$root/unmanaged"
printf '%s\n' alpha >"$tmp/alpha/SKILL.md"
printf '%s\n' beta >"$tmp/beta/SKILL.md"
printf '%s\n' system >"$root/.system/keep"
printf '%s\n' unmanaged >"$root/unmanaged/keep"
printf '%s\n' docs >"$tmp/README.md"

"$DEPLOY" "$root" --readme "$tmp/README.md" alpha "$tmp/alpha"
[[ -f $root/alpha/SKILL.md ]]
[[ ! -L $root/alpha/SKILL.md ]]
grep -qx alpha "$root/.agents-nix-managed"
grep -qx docs "$root/README.md"

"$DEPLOY" "$root" --readme "$tmp/README.md" beta "$tmp/beta"
[[ ! -e $root/alpha ]]
[[ -f $root/beta/SKILL.md ]]
[[ -f $root/.system/keep ]]
[[ -f $root/unmanaged/keep ]]

if "$DEPLOY" "$root" broken "$tmp/broken" 2>/dev/null; then
    echo "missing SKILL.md was accepted" >&2
    exit 1
fi
[[ -f $root/beta/SKILL.md ]]

if "$DEPLOY" "$root" ../escape "$tmp/alpha" 2>/dev/null; then
    echo "unsafe skill name was accepted" >&2
    exit 1
fi
[[ -f $root/beta/SKILL.md ]]

"$DEPLOY" "$root"
[[ ! -e $root/beta ]]
[[ ! -e $root/.agents-nix-managed ]]
[[ ! -e $root/README.md ]]
[[ -f $root/.system/keep ]]
[[ -f $root/unmanaged/keep ]]

printf 'deploy-codex-skills: clean\n'
