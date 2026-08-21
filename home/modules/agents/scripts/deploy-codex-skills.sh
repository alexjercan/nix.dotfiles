#!/usr/bin/env bash
# Materialize managed Codex skills while preserving every unmanaged entry.

set -euo pipefail

usage() {
    echo "Usage: agents-deploy-codex-skills <skills-root> [--readme <file>] [<name> <source>]..." >&2
    exit 2
}

valid_name() {
    [[ $1 =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

[[ $# -ge 1 ]] || usage
root=$1
shift
readme=
if [[ ${1:-} == --readme ]]; then
    [[ $# -ge 2 ]] || usage
    readme=$2
    shift 2
    [[ -f $readme ]] || {
        echo "agents-deploy-codex-skills: README source '$readme' is not a file" >&2
        exit 1
    }
fi
(( $# % 2 == 0 )) || usage

mkdir -p "$root"
manifest="$root/.agents-nix-managed"
tmp=$(mktemp "$root/.agents-nix-managed.XXXXXX")
trap 'rm -f "$tmp"' EXIT

names=()
sources=()
while [[ $# -gt 0 ]]; do
    name=$1
    source=$2
    shift 2

    valid_name "$name" || {
        echo "agents-deploy-codex-skills: invalid skill name '$name'" >&2
        exit 1
    }
    [[ -f $source/SKILL.md ]] || {
        echo "agents-deploy-codex-skills: $source has no SKILL.md" >&2
        exit 1
    }
    names+=("$name")
    sources+=("$source")
    printf '%s\n' "$name" >>"$tmp"
done

managed_before=false
if [[ -f $manifest ]]; then
    managed_before=true
    while IFS= read -r name; do
        [[ -n $name ]] || continue
        if valid_name "$name"; then
            rm -rf -- "${root:?}/$name"
        else
            echo "agents-deploy-codex-skills: ignoring invalid managed name '$name'" >&2
        fi
    done <"$manifest"
fi

if $managed_before; then
    rm -f "$root/README.md"
fi

if [[ ${#names[@]} -eq 0 && -z $readme ]]; then
    rm -f "$manifest"
    exit 0
fi

mv "$tmp" "$manifest"
trap - EXIT

if [[ -n $readme ]]; then
    cp -L -- "$readme" "$root/README.md"
    chmod u+w "$root/README.md"
fi

for ((i = 0; i < ${#names[@]}; i++)); do
    destination="$root/${names[$i]}"
    rm -rf -- "$destination"
    cp -rL -- "${sources[$i]}" "$destination"
    chmod -R u+w "$destination"
done
