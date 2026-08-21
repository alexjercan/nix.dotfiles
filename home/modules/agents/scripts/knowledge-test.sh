#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ -n ${KNOWLEDGE:-} ]]; then
    KNOWLEDGE_COMMAND=("$KNOWLEDGE")
else
    KNOWLEDGE_COMMAND=("$SCRIPT_DIR/knowledge.py")
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

knowledge() {
    "${KNOWLEDGE_COMMAND[@]}" "$@"
}

expect_failure() {
    local message=$1
    shift
    if "$@" >"$tmp/unexpected.out" 2>"$tmp/error"; then
        echo "$message" >&2
        exit 1
    fi
}

store="$tmp/store"
out=$(knowledge --directory "$store" create process/search-before-create \
    --tag knowledge --tag agents --tag knowledge \
    --body "Search existing lessons first.")
[[ $out == process/search-before-create ]]
[[ -f $store/process/search-before-create.md ]]
cat >"$tmp/expected" <<'EOF'
---
id: process/search-before-create
tags:
  - agents
  - knowledge
---
Search existing lessons first.
EOF
knowledge --directory "$store" read process/search-before-create >"$tmp/actual"
cmp "$tmp/expected" "$tmp/actual"

printf 'Read bodies from standard input.\n' |
    knowledge --directory "$store" create process/stdin \
        --tag input --body - >/dev/null
printf 'Read bodies from files.\n' >"$tmp/body"
knowledge --directory "$store" create process/file \
    --tag input --body "@$tmp/body" >/dev/null

after=$(knowledge --directory "$store" update process/search-before-create \
    --body "Update matching lessons instead.")
[[ $after == process/search-before-create ]]
grep -q '^  - agents$' "$store/process/search-before-create.md"
grep -q '^Update matching lessons instead\.$' "$store/process/search-before-create.md"
knowledge --directory "$store" update process/search-before-create \
    --tag durable --tag agents >/dev/null
! grep -q '^  - knowledge$' "$store/process/search-before-create.md"
grep -q '^  - durable$' "$store/process/search-before-create.md"
grep -q '^Update matching lessons instead\.$' "$store/process/search-before-create.md"

expect_failure "create replaced an existing lesson" \
    knowledge --directory "$store" create process/file --tag input --body Changed
expect_failure "update accepted no changes" \
    knowledge --directory "$store" update process/file
expect_failure "update accepted a missing lesson" \
    knowledge --directory "$store" update process/missing --body Missing
expect_failure "create accepted an invalid ID" \
    knowledge --directory "$store" create ../escape --tag input --body Unsafe
expect_failure "create accepted an invalid tag" \
    knowledge --directory "$store" create process/tag --tag 'Bad Tag' --body Unsafe
expect_failure "create accepted an empty body" \
    knowledge --directory "$store" create process/empty --tag input --body ' '

mapfile -t listed < <(knowledge --directory "$store" list)
[[ ${listed[*]} == "process/file process/search-before-create process/stdin" ]]
[[ $(knowledge --directory "$store" search MATCHING) == process/search-before-create ]]
[[ $(knowledge --directory "$store" search INPUT) == $'process/file\nprocess/stdin' ]]
[[ -z $(knowledge --directory "$store" search absent) ]]
knowledge --directory "$store" check

[[ $(knowledge --directory "$store" delete process/file) == process/file ]]
[[ ! -e $store/process/file.md ]]
expect_failure "delete accepted a missing lesson" \
    knowledge --directory "$store" delete process/file

mkdir -p "$tmp/home"
HOME="$tmp/home" XDG_DATA_HOME="$tmp/xdg" AGENTS_KNOWLEDGE_DIR= \
    knowledge create defaults/xdg --tag path --body XDG >/dev/null
[[ -f $tmp/xdg/agents/knowledge/defaults/xdg.md ]]
HOME="$tmp/home" XDG_DATA_HOME= AGENTS_KNOWLEDGE_DIR= \
    knowledge create defaults/home --tag path --body Home >/dev/null
[[ -f $tmp/home/.local/share/agents/knowledge/defaults/home.md ]]
HOME="$tmp/home" XDG_DATA_HOME="$tmp/ignored-xdg" \
    AGENTS_KNOWLEDGE_DIR="$tmp/environment" \
    knowledge create defaults/environment --tag path --body Environment >/dev/null
[[ -f $tmp/environment/defaults/environment.md ]]
HOME="$tmp/home" XDG_DATA_HOME="$tmp/ignored-xdg" \
    AGENTS_KNOWLEDGE_DIR="$tmp/ignored-environment" \
    knowledge --directory "$tmp/argument" create defaults/argument \
        --tag path --body Argument >/dev/null
[[ -f $tmp/argument/defaults/argument.md ]]

empty="$tmp/does-not-exist"
[[ -z $(knowledge --directory "$empty" list) ]]
[[ -z $(knowledge --directory "$empty" search anything) ]]
knowledge --directory "$empty" check
[[ ! -e $empty ]]

invalid="$tmp/invalid"
mkdir -p "$invalid/process"
cat >"$invalid/process/broken.md" <<'EOF'
---
id: process/wrong
tags:
  - Bad Tag
---
EOF
printf 'unexpected\n' >"$invalid/process/unexpected.txt"
ln -s broken.md "$invalid/process/linked.md"
expect_failure "check accepted an invalid store" \
    knowledge --directory "$invalid" check
grep -q 'ID does not match path' "$tmp/error"
grep -q 'invalid tag' "$tmp/error"
grep -q 'empty body' "$tmp/error"
grep -q 'unexpected file' "$tmp/error"
grep -q 'symbolic link' "$tmp/error"

printf 'knowledge: clean\n'
