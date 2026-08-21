#!/usr/bin/env bash
# Integration tests for sprout.sh: drive the real script against throwaway
# git repos under mktemp, one fresh sandbox per test.
#
#   bash home/modules/scripts/sprout-test.sh
#   bash home/modules/scripts/sprout-test.sh -v  # also print passing asserts
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
    TEST_SESSIONS=()
    TMP=$(mktemp -d)
    export XDG_CACHE_HOME="$TMP/cache"
    export TMUX_TMPDIR="$TMP/tmux"
    REPO="$TMP/repo"
    mkdir -p "$REPO" "$TMUX_TMPDIR"
    chmod 700 "$TMUX_TMPDIR"
    git -C "$REPO" init -q -b master
    echo base > "$REPO/base.txt"
    git -C "$REPO" add base.txt
    git -C "$REPO" commit -qm "initial"
    cd "$REPO" || exit 1
}

teardown() {
    local session
    for session in "${TEST_SESSIONS[@]}"; do
        tmux kill-session -t "=$session" 2> /dev/null || true
    done
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
    check "ls lists branch, empty task, and path" str_matches "$ls_out" '^feat +- +/'
    shown=$(sprout show feat 2> /dev/null)
    check "show prints the same path" test "$shown" = "$path"
    check "rm exits 0" quiet sprout rm feat
    check "worktree removed" not test -d "$path"
    check "branch deleted" not git show-ref --verify --quiet refs/heads/feat
}

test_new_task_association() {
    local path ls_out task
    task=20260802-113805
    path=$(sprout new feat --task "$task" 2> /dev/null)
    check "new with task prints only the path" test "$path" = "$XDG_CACHE_HOME/sprouts/repo/feat"
    check "task is stored in worktree config" test "$(git -C "$path" config --worktree --get sprout.task)" = "$task"
    ls_out=$(sprout ls 2> /dev/null)
    check "ls lists branch, task, and path" str_matches "$ls_out" "^feat +$task +/"
}

test_new_rejects_duplicate_task() {
    local task err rc
    task=20260802-192659
    sprout new feature/dup --task "$task" > /dev/null 2>&1
    err=$(sprout new feat/dup --task "$task" 2>&1 > /dev/null)
    rc=$?
    check "refuses a second worktree for the same task" test "$rc" -ne 0
    check "reason names the existing worktree" str_contains "$err" "$XDG_CACHE_HOME/sprouts/repo/feature/dup"
    check "no second worktree created" not test -d "$XDG_CACHE_HOME/sprouts/repo/feat/dup"
    check "no second branch created" not git show-ref --verify --quiet refs/heads/feat/dup
    check "a different task still sprouts" quiet sprout new feat/other --task 20260802-192700
}

test_new_records_target() {
    local path
    path=$(sprout new feat 2> /dev/null)
    check "target recorded from the main checkout's branch" test "$(git -C "$path" config --worktree --get sprout.target)" = "master"
}

test_new_detached_records_no_target() {
    # --task so the config write actually runs: the case is "the missing
    # target does not break recording", not "nothing is recorded".
    local path
    git checkout -q --detach
    path=$(sprout new feat --task 20260803-105234 2> /dev/null)
    check "new succeeds on a detached main checkout" test -d "$path"
    check "the task is still recorded" test "$(git -C "$path" config --worktree --get sprout.task)" = "20260803-105234"
    check "no target recorded" test -z "$(git -C "$path" config --worktree --get sprout.target)"
}

test_new_rejects_bad_task() {
    check "rejects missing task ID" not quiet sprout new feat --task
    check "rejects malformed task ID" not quiet sprout new feat --task not-an-id
    check "rejects unknown new option" not quiet sprout new feat --unknown
    check "invalid task creates no worktree" not test -d "$XDG_CACHE_HOME/sprouts/repo/feat"
}

test_new_rejects_bad_names() {
    check "rejects '..' segments" not quiet sprout new ../escape
    check "rejects leading '/'" not quiet sprout new /abs
    check "rejects leading '-'" not quiet sprout new -flag
}

# Start the real tmux resource that interactive Sprout use creates.
start_feature_session() {
    FEATURE_SESSION=repo_$(echo "$1" | tr './ :' '____')
    tmux new-session -ds "$FEATURE_SESSION"
    TEST_SESSIONS+=("$FEATURE_SESSION")
}

# Move master on by one commit touching $1 with content $2.
advance_master() {
    echo "$2" > "$REPO/$1"
    git -C "$REPO" add "$1"
    git -C "$REPO" commit -qm "master: $1"
}

test_sync_merges_target() {
    local wt rc
    wt=$(make_feature feat)
    advance_master other.txt diverge
    sprout sync feat > /dev/null 2>&1
    rc=$?
    check "sync exits 0" test "$rc" -eq 0
    check "target content is in the worktree" test -f "$wt/other.txt"
    check "branch now contains the target tip" git merge-base --is-ancestor master feat
    check "master untouched" test "$(git rev-list --count master)" -eq 2
    check "main checkout clean" test -z "$(git status --porcelain --untracked-files=no)"
}

test_sync_already_up_to_date() {
    local wt rc before
    wt=$(make_feature feat)
    before=$(git -C "$wt" rev-parse HEAD)
    sprout sync feat > /dev/null 2>&1
    rc=$?
    check "an already up to date sync succeeds" test "$rc" -eq 0
    check "branch tip unchanged" test "$(git -C "$wt" rev-parse HEAD)" = "$before"
}

test_sync_dry_run_clean() {
    local wt rc before out
    wt=$(make_feature feat)
    before=$(git -C "$wt" rev-parse HEAD)
    advance_master other.txt diverge
    out=$(sprout sync feat -n 2> /dev/null)
    rc=$?
    check "a clean dry run exits 0" test "$rc" -eq 0
    check "it reports the merge on stdout" str_contains "$out" "would merge cleanly"
    check "branch tip unchanged" test "$(git -C "$wt" rev-parse HEAD)" = "$before"
    check "nothing merged into the worktree" not test -f "$wt/other.txt"
    check "worktree clean" test -z "$(git -C "$wt" status --porcelain)"
}

test_sync_dry_run_conflict() {
    local wt err rc before
    wt=$(make_feature feat)
    echo "feature side" > "$wt/base.txt"
    git -C "$wt" commit -aqm "wip: base.txt"
    before=$(git -C "$wt" rev-parse HEAD)
    advance_master base.txt "master side"
    err=$(sprout sync feat --dry-run 2>&1 > /dev/null)
    rc=$?
    check "a conflicting dry run exits non-zero" test "$rc" -ne 0
    check "it names the conflicting path" str_contains "$err" "base.txt"
    check "it says the merge would conflict" str_contains "$err" "would conflict"
    check "branch tip unchanged" test "$(git -C "$wt" rev-parse HEAD)" = "$before"
    check "worktree clean" test -z "$(git -C "$wt" status --porcelain)"
}

test_sync_conflict_stays_in_worktree() {
    local wt rc
    wt=$(make_feature feat)
    echo "feature side" > "$wt/base.txt"
    git -C "$wt" commit -aqm "wip: base.txt"
    advance_master base.txt "master side"
    sprout sync feat > /dev/null 2>&1
    rc=$?
    check "a conflicting sync exits non-zero" test "$rc" -ne 0
    check "the conflict is left in the worktree" str_contains "$(git -C "$wt" status --porcelain)" "UU base.txt"
    check "master untouched" test "$(git rev-list --count master)" -eq 2
    check "main checkout clean" test -z "$(git status --porcelain --untracked-files=no)"
}

test_sync_rejects_bad_args() {
    # Each case asserts its OWN message: an exit code alone cannot tell a
    # refusal by `sync` from `sync` not existing at all.
    local err rc
    make_feature feat > /dev/null
    mkdir -p "$XDG_CACHE_HOME/sprouts/repo/master"

    err=$(sprout sync 2>&1 > /dev/null)
    rc=$?
    check "rejects a missing feature" test "$rc" -ne 0
    check "reason is the missing name" str_contains "$err" "missing <feature>"

    err=$(sprout sync feat --force 2>&1 > /dev/null)
    rc=$?
    check "rejects an unknown flag" test "$rc" -ne 0
    check "reason names the argument" str_contains "$err" "unexpected argument '--force'"

    err=$(sprout sync nope 2>&1 > /dev/null)
    rc=$?
    check "rejects an unknown feature" test "$rc" -ne 0
    check "reason is the missing worktree" str_contains "$err" "no worktree"

    err=$(sprout sync master 2>&1 > /dev/null)
    rc=$?
    check "rejects a feature equal to the target" test "$rc" -ne 0
    check "reason is the self-target" str_contains "$err" "own landing target"
}

test_sync_refuses_missing_target() {
    local wt err rc
    git checkout -qb release
    wt=$(make_feature feat)
    git checkout -q master
    git branch -qD release
    err=$(sprout sync feat 2>&1 > /dev/null)
    rc=$?
    check "refuses when the recorded target is gone" test "$rc" -ne 0
    check "reason names the missing target" str_contains "$err" "no target branch 'release'"
    check "it does not claim a conflict" not str_contains "$err" "conflict"
    err=$(sprout sync feat -n 2>&1 > /dev/null)
    rc=$?
    check "the dry run refuses the same way" test "$rc" -ne 0
    check "the dry run names the missing target" str_contains "$err" "no target branch 'release'"
    check "worktree clean" test -z "$(git -C "$wt" status --porcelain)"
}

test_sync_refuses_detached_worktree() {
    # A detached sprout worktree would merge into HEAD, not into the branch:
    # sync must refuse rather than report a success that lands nothing.
    local wt err rc before
    wt=$(make_feature feat)
    advance_master other.txt diverge
    git -C "$wt" checkout -q --detach
    before=$(git rev-parse feat)
    err=$(sprout sync feat 2>&1 > /dev/null)
    rc=$?
    check "refuses a detached worktree" test "$rc" -ne 0
    check "reason names the worktree" str_contains "$err" "$wt"
    check "branch tip unchanged" test "$(git rev-parse feat)" = "$before"
    check "the dry run refuses too" not quiet sprout sync feat -n
}

test_land_retains_then_rm() {
    local wt out rc session
    wt=$(make_feature feature/demo)
    start_feature_session feature/demo
    session=$FEATURE_SESSION
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
    check "worktree retained" test -d "$wt"
    check "branch retained" git show-ref --verify --quiet refs/heads/feature/demo
    check "tmux session retained" tmux has-session -t "=$session"

    check "standalone rm cleans retained land" quiet sprout rm feature/demo
    check "retained worktree removed by rm" not test -d "$wt"
    check "retained branch removed by rm" not git show-ref --verify --quiet refs/heads/feature/demo
    check "retained tmux session removed by rm" not quiet tmux has-session -t "=$session"
}

test_land_remove() {
    local wt out rc session
    wt=$(make_feature feat)
    start_feature_session feat
    session=$FEATURE_SESSION
    out=$(sprout land feat --remove -m "feat: remove after land" 2> /dev/null)
    rc=$?
    check "land --remove exits 0" test "$rc" -eq 0
    check "land --remove stdout is one landed line" str_matches "$out" '^landed [0-9a-f]+ feat: remove after land$'
    check "land --remove creates the squash commit" test "$(git log -1 --format=%s)" = "feat: remove after land"
    check "land --remove removes worktree" not test -d "$wt"
    check "land --remove deletes branch" not git show-ref --verify --quiet refs/heads/feat
    check "land --remove kills tmux session" not quiet tmux has-session -t "=$session"
}

test_land_dry_run_ok() {
    local out rc
    make_feature feat > /dev/null
    out=$(sprout land feat -n -m "feat: x" 2> /dev/null)
    rc=$?
    check "a landable branch dry runs green" test "$rc" -eq 0
    check "it reports the land it would do" str_contains "$out" "'feat' would land onto 'master'"
}

test_land_dry_run_writes_nothing() {
    local wt rc session before
    wt=$(make_feature feat)
    start_feature_session feat
    session=$FEATURE_SESSION
    before=$(git -C "$wt" rev-parse HEAD)
    sprout land feat --dry-run -m "feat: x" > /dev/null 2>&1
    rc=$?
    check "the retained dry run exits 0" test "$rc" -eq 0
    sprout land feat --remove -n -m "feat: x" > /dev/null 2>&1
    rc=$?
    check "the --remove dry run exits 0" test "$rc" -eq 0
    check "master untouched" test "$(git rev-list --count master)" -eq 1
    check "main checkout clean" test -z "$(git status --porcelain)"
    check "worktree kept" test -d "$wt"
    check "worktree tip unchanged" test "$(git -C "$wt" rev-parse HEAD)" = "$before"
    check "branch kept" git show-ref --verify --quiet refs/heads/feat
    check "tmux session kept" tmux has-session -t "=$session"
}

test_land_dry_run_refuses_behind() {
    local wt err rc
    wt=$(make_feature feat)
    advance_master other.txt diverge
    err=$(sprout land feat -n -m "x" 2>&1 > /dev/null)
    rc=$?
    check "a stale branch dry runs red" test "$rc" -ne 0
    check "reason is the real refusal" str_contains "$err" "not up to date"
    check "worktree kept" test -d "$wt"
}

test_land_dry_run_requires_message() {
    local err rc
    make_feature feat > /dev/null
    err=$(sprout land feat -n 2>&1 > /dev/null)
    rc=$?
    check "a message-less dry run is refused" test "$rc" -ne 0
    check "reason is the missing message" str_contains "$err" "commit message"
}

test_land_refuses_target_mismatch() {
    local wt err rc
    wt=$(make_feature feat)
    git checkout -qb release
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "refuses when the main checkout left the recorded target" test "$rc" -ne 0
    check "reason names the recorded target" str_contains "$err" "master"
    check "reason names the current branch" str_contains "$err" "release"
    check "release untouched" test "$(git rev-list --count release)" -eq 1
    check "worktree kept" test -d "$wt"
}

test_land_uses_recorded_target() {
    local wt rc
    wt=$(make_feature feat)
    git checkout -qb release
    check "the recorded target refuses the land" not quiet sprout land feat -m "x"
    git -C "$wt" config --worktree --unset sprout.target
    sprout land feat -m "feat: landed via fallback" > /dev/null 2>&1
    rc=$?
    check "without a recorded target it falls back to the current branch" test "$rc" -eq 0
    check "the commit landed on the current branch" test "$(git log -1 --format=%s release)" = "feat: landed via fallback"
    check "master untouched" test "$(git rev-list --count master)" -eq 1
}

test_land_refuses_behind() {
    local wt err rc session
    wt=$(make_feature feat)
    start_feature_session feat
    session=$FEATURE_SESSION
    echo diverge > other.txt
    git add other.txt
    git commit -qm "master moved on"
    err=$(sprout land feat -m "x" 2>&1 > /dev/null)
    rc=$?
    check "land refuses a stale branch" test "$rc" -ne 0
    check "reason is the sync gate" str_contains "$err" "not up to date"
    check "the remedy is the sync command" str_contains "$err" "sprout sync feat"
    check "master untouched" test "$(git rev-list --count master)" -eq 2
    check "worktree kept for the sync" test -d "$wt"
    check "branch kept for the sync" git show-ref --verify --quiet refs/heads/feat
    check "tmux session kept for the sync" tmux has-session -t "=$session"
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
run_test test_new_task_association
run_test test_new_rejects_duplicate_task
run_test test_new_records_target
run_test test_new_detached_records_no_target
run_test test_new_rejects_bad_task
run_test test_new_rejects_bad_names
run_test test_sync_merges_target
run_test test_sync_already_up_to_date
run_test test_sync_dry_run_clean
run_test test_sync_dry_run_conflict
run_test test_sync_conflict_stays_in_worktree
run_test test_sync_rejects_bad_args
run_test test_sync_refuses_missing_target
run_test test_sync_refuses_detached_worktree
run_test test_land_retains_then_rm
run_test test_land_remove
run_test test_land_dry_run_ok
run_test test_land_dry_run_writes_nothing
run_test test_land_dry_run_refuses_behind
run_test test_land_dry_run_requires_message
run_test test_land_refuses_target_mismatch
run_test test_land_uses_recorded_target
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
