#!/usr/bin/env bash
# Integration tests for sprout.sh: drive the real script against throwaway
# git repos under mktemp, one fresh sandbox per test.
#
#   bash home/modules/scripts/sprout-test.sh       # run all tests
#   bash home/modules/scripts/sprout-test.sh -v    # also print passing asserts
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SPROUT="$SCRIPT_DIR/sprout.sh"

VERBOSE=false
[[ ${1:-} == "-v" ]] && VERBOSE=true

# Hermetic git: fixed identity, no user/system config (a global
# commit.gpgsign or init.defaultBranch must not leak into the tests).
export GIT_AUTHOR_NAME="sprout-test" GIT_AUTHOR_EMAIL="sprout-test@example.invalid"
export GIT_COMMITTER_NAME="sprout-test" GIT_COMMITTER_EMAIL="sprout-test@example.invalid"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

PASS=0
FAIL=0
CASE_FAILED=0

sprout() { bash "$SPROUT" "$@"; }

# Assertion helpers usable as `check` commands.
not() { ! "$@"; }
quiet() { "$@" > /dev/null 2>&1; }
str_prefix() { [[ $1 == "$2"* ]]; }
str_contains() { [[ $1 == *"$2"* ]]; }
str_matches() { [[ $1 =~ $2 ]]; }

check() {
    # $1: description; the rest is a command expected to succeed.
    local desc=$1
    shift
    if "$@"; then
        if $VERBOSE; then echo "    ok: $desc"; fi
    else
        echo "    FAILED: $desc"
        CASE_FAILED=1
    fi
}

setup() {
    # Fresh sandbox: a repo with one commit and an isolated sprouts cache.
    TMP=$(mktemp -d)
    export XDG_CACHE_HOME="$TMP/cache"
    REPO="$TMP/repo"
    mkdir -p "$REPO"
    git -C "$REPO" init -q -b master
    echo base > "$REPO/base.txt"
    git -C "$REPO" add base.txt
    git -C "$REPO" commit -qm "initial"
    cd "$REPO" || exit 1
}

teardown() {
    cd / && rm -rf "$TMP"
}

run_test() {
    CASE_FAILED=0
    setup
    "$1"
    teardown
    if [[ $CASE_FAILED -eq 0 ]]; then
        PASS=$((PASS + 1))
        echo "PASS $1"
    else
        FAIL=$((FAIL + 1))
        echo "FAIL $1"
    fi
}

# Make a feature worktree with one committed change; prints its path.
make_feature() {
    local wt
    wt=$(sprout new "$1" 2> /dev/null)
    echo "change by $1" > "$wt/$(echo "$1" | tr / -).txt"
    git -C "$wt" add -A
    git -C "$wt" commit -qm "wip: $1"
    echo "$wt"
}

test_new_show_rm() {
    local path shown ls_out
    path=$(sprout new feat 2> /dev/null)
    check "new prints the expected path" test "$path" = "$XDG_CACHE_HOME/sprouts/repo/feat"
    check "worktree directory exists" test -d "$path"
    check "branch created" git show-ref --verify --quiet refs/heads/feat
    ls_out=$(sprout ls 2> /dev/null)
    check "ls lists the feature and its branch" str_matches "$ls_out" '^feat +feat +/'
    shown=$(sprout show feat 2> /dev/null)
    check "show prints the same path" test "$shown" = "$path"
    check "rm exits 0" quiet sprout rm feat
    check "worktree removed" not test -d "$path"
    check "branch deleted" not git show-ref --verify --quiet refs/heads/feat
}

test_new_rejects_bad_names() {
    check "rejects '..' segments" not quiet sprout new ../escape
    check "rejects leading '/'" not quiet sprout new /abs
    check "rejects leading '-'" not quiet sprout new -flag
}

test_land_happy() {
    local wt out rc
    wt=$(make_feature feature/demo)
    echo more >> "$wt/feature-demo.txt"
    git -C "$wt" commit -aqm "wip: more"
    out=$(sprout land feature/demo -m "feat: demo landed" -m "two wips squashed" 2> /dev/null)
    rc=$?
    check "land exits 0" test "$rc" -eq 0
    check "stdout is exactly the landed line" str_matches "$out" '^landed [0-9a-f]+ feat: demo landed$'
    check "single squash commit subject" test "$(git log -1 --format=%s)" = "feat: demo landed"
    check "commit body from second -m" test "$(git log -1 --format=%b)" = "two wips squashed"
    check "exactly one commit added to master" test "$(git rev-list --count master)" -eq 2
    check "branch content present on master" test -f feature-demo.txt
    check "main checkout clean after land" test -z "$(git status --porcelain)"
    check "worktree cleaned up" not test -d "$wt"
    check "branch deleted" not git show-ref --verify --quiet refs/heads/feature/demo
}

test_land_refuses_behind() {
    local wt err rc
    wt=$(make_feature feat)
    echo diverge > other.txt
    git add other.txt
    git commit -qm "master moved on"
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "land refuses a stale branch" test "$rc" -ne 0
    check "reason is the sync gate" str_contains "$err" "not up to date"
    check "master untouched" test "$(git rev-list --count master)" -eq 2
    check "worktree kept for the sync" test -d "$wt"
}

test_land_refuses_dirty_main() {
    local err rc
    make_feature feat > /dev/null
    echo dirty >> base.txt
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses with modified tracked file" test "$rc" -ne 0
    check "reason is the dirty main checkout" str_contains "$err" "staged or modified"
    git add base.txt
    check "refuses with staged file" not quiet sprout land feat -m "x"
    check "master untouched" test "$(git rev-list --count master)" -eq 1
}

test_land_allows_untracked_main() {
    local rc
    make_feature feat > /dev/null
    echo junk > untracked.txt
    sprout land feat -m "feat: landed over untracked" > /dev/null 2>&1
    rc=$?
    check "untracked files do not block landing" test "$rc" -eq 0
    check "untracked file survives" test -f untracked.txt
    check "commit landed" test "$(git log -1 --format=%s)" = "feat: landed over untracked"
}

test_land_refuses_detached() {
    local err rc
    make_feature feat > /dev/null
    git checkout -q --detach
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses on detached HEAD" test "$rc" -ne 0
    check "reason is the detached HEAD" str_contains "$err" "detached"
}

test_land_refuses_missing_feature() {
    local err rc
    err=$(sprout land nope -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses unknown feature" test "$rc" -ne 0
    check "reason is the missing worktree" str_contains "$err" "no worktree"
}

test_land_requires_message() {
    local err rc
    make_feature feat > /dev/null
    err=$(sprout land feat 2>&1 > /dev/null)
    rc=$?
    check "refuses without -m" test "$rc" -ne 0
    check "reason is the missing message" str_contains "$err" "commit message"
    check "refuses dangling -m" not quiet sprout land feat -m
}

test_land_empty_squash_rolls_back() {
    local wt err rc
    wt=$(sprout new feat 2> /dev/null) # no commits: nothing to squash
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "empty squash fails" test "$rc" -ne 0
    check "reports the rollback" str_contains "$err" "reset"
    check "no staged state left behind" test -z "$(git status --porcelain)"
    check "master untouched" test "$(git rev-list --count master)" -eq 1
    check "worktree kept" test -d "$wt"
}

test_land_commit_failure_rolls_back() {
    # A REAL squash (staged changes present) followed by a failing commit:
    # git aborts on an empty -m message. The rollback must leave nothing
    # staged for a parallel session to sweep up.
    local wt err rc
    wt=$(make_feature feat)
    err=$(sprout land feat -m "" 2>&1 > /dev/null)
    rc=$?
    check "commit failure exits non-zero" test "$rc" -ne 0
    check "reports the rollback" str_contains "$err" "reset"
    check "no staged state left behind" test -z "$(git status --porcelain)"
    check "master untouched" test "$(git rev-list --count master)" -eq 1
    check "worktree kept" test -d "$wt"
}

test_land_refuses_missing_branch() {
    # Simulated stale state: a directory at the worktree path, no branch.
    local err rc
    mkdir -p "$XDG_CACHE_HOME/sprouts/repo/ghost"
    err=$(sprout land ghost -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses when the branch is missing" test "$rc" -ne 0
    check "reason is the missing branch" str_contains "$err" "no branch"
}

test_land_refuses_target_equals_feature() {
    # Simulated stale state: a dir at the worktree path named like the
    # branch the main checkout has checked out.
    local err rc
    mkdir -p "$XDG_CACHE_HOME/sprouts/repo/master"
    err=$(sprout land master -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses when feature is the checked-out target" test "$rc" -ne 0
    check "reason names the collision" str_contains "$err" "itself checked out"
}

test_land_from_inside_worktree() {
    local wt err rc
    wt=$(make_feature feat)
    cd "$wt" || return
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses to land from inside the worktree" test "$rc" -ne 0
    check "reason names the worktree" str_contains "$err" "inside"
    cd "$REPO" || return
    check "master untouched" test "$(git rev-list --count master)" -eq 1
}

echo "== sprout integration tests =="
run_test test_new_show_rm
run_test test_new_rejects_bad_names
run_test test_land_happy
run_test test_land_refuses_behind
run_test test_land_refuses_dirty_main
run_test test_land_allows_untracked_main
run_test test_land_refuses_detached
run_test test_land_refuses_missing_feature
run_test test_land_requires_message
run_test test_land_empty_squash_rolls_back
run_test test_land_commit_failure_rolls_back
run_test test_land_refuses_missing_branch
run_test test_land_refuses_target_equals_feature
run_test test_land_from_inside_worktree
echo
echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]
