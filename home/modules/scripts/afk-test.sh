#!/usr/bin/env bash
# Integration tests for afk.sh: drive the real runner against throwaway git
# repos under mktemp, with a fake `claude` first on PATH.
#
#   bash home/modules/scripts/afk-test.sh       # run all tests
#   bash home/modules/scripts/afk-test.sh -v    # also print passing asserts
#
# The fake `claude` records its argv, runs a per-invocation side-effect script
# that mutates the sandbox exactly as a real flow session would (tatr
# transitions, worktrees, commits, landing), then replays a stream-json
# fixture. That is what makes the runner's control logic testable without
# spending model quota: everything afk verifies is real durable state.
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
AFK="$SCRIPT_DIR/afk.sh"

VERBOSE=false
[[ ${1:-} == "-v" ]] && VERBOSE=true

# Hermetic git: fixed identity, no user/system config (a global commit.gpgsign
# or init.defaultBranch must not leak into the tests).
export GIT_AUTHOR_NAME="afk-test" GIT_AUTHOR_EMAIL="afk-test@example.invalid"
export GIT_COMMITTER_NAME="afk-test" GIT_COMMITTER_EMAIL="afk-test@example.invalid"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

PASS=0
FAIL=0
CASE_FAILED=0

afk() { bash "$AFK" "$@"; }

# Assertion helpers usable as `check` commands.
not() { ! "$@"; }
quiet() { "$@" > /dev/null 2>&1; }
str_contains() { [[ $1 == *"$2"* ]]; }
str_matches() { [[ $1 =~ $2 ]]; }
alive() { kill -0 "$1" 2> /dev/null; }
dead() { ! kill -0 "$1" 2> /dev/null; }

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

line_no() {
    # $1: text  $2: literal needle -> first matching line number, or 0.
    local n
    n=$(printf '%s\n' "$1" | grep -nF -m1 -- "$2" | cut -d: -f1)
    printf '%s\n' "${n:-0}"
}

in_order() {
    # $1: text; the rest are needles that must appear in this order.
    local text=$1 needle cur prev=0
    shift
    for needle in "$@"; do
        cur=$(line_no "$text" "$needle")
        if [[ $cur -le $prev ]]; then
            echo "      out of order: '$needle' at line $cur (previous $prev)"
            return 1
        fi
        prev=$cur
    done
}

# ---------------------------------------------------------------- fixtures --
#
# These run both in the test process and, via $TMP/fixtures.sh, inside the fake
# claude's side-effect scripts, so they may only use exported state
# ($AFK_TEST_TMP, $REPO, $XDG_CACHE_HOME) and never test-local variables.

WT_REL="sprouts/repo/feature/thing"

reply() {
    # $1: invocation number  $2: the AFK marker line (may be empty)
    # $3: the session's context size in tokens (default 57600).
    # Emits a minimal but realistic stream-json transcript. The marker is put
    # on the LAST line of the result text so the runner must scan for it. The
    # token total is split across all four usage fields, with distinct small
    # values, so a sum that drops one of them shows up in the reported count.
    local file="$AFK_TEST_TMP/replies/$1.jsonl" total=${3:-57600}
    mkdir -p "$AFK_TEST_TMP/replies"
    {
        printf '%s\n' '{"type":"system","subtype":"init","session_id":"fake"}'
        printf '{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":%d,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}\n' \
            "$((total - 6))"
        printf '{"type":"result","subtype":"success","is_error":false,"result":"phase summary\\n%s"}\n' "$2"
    } > "$file"
}

pause() {
    # $1: invocation number  $2: seconds the fake claude holds the stream open
    # before the LAST line of its transcript. Two things need that: a spinner
    # is only visible while a session is quiet, and a kill is only observable
    # in a session that has not already finished.
    mkdir -p "$AFK_TEST_TMP/replies"
    printf '%s\n' "$2" > "$AFK_TEST_TMP/replies/$1.slow"
}

reply_slow() {
    # $1: invocation number  $2: the AFK marker line  $3: seconds of silence
    # between the assistant event and the result.
    reply "$1" "$2"
    pause "$1" "$3"
}

reply_raw() {
    # $1: invocation number; the transcript is read from stdin verbatim.
    mkdir -p "$AFK_TEST_TMP/replies"
    cat > "$AFK_TEST_TMP/replies/$1.jsonl"
}

side() {
    # $1: invocation number; the side-effect script is read from stdin.
    mkdir -p "$AFK_TEST_TMP/replies"
    cat > "$AFK_TEST_TMP/replies/$1.sh"
}

exit_rc() {
    # $1: invocation number  $2: the exit status the fake claude should use.
    mkdir -p "$AFK_TEST_TMP/replies"
    printf '%s\n' "$2" > "$AFK_TEST_TMP/replies/$1.rc"
}

plan_sections() {
    # $1: TASK.md path. tatr's PLAN gate refuses to leave PLANNING without
    # these.
    cat >> "$1" << 'EOF'

## Steps

- [x] implement the thing

## Definition of Done

- it works. (cmd: `true`)
EOF
}

approved_review() {
    # $1: REVIEW.md path. tatr's REVIEW gate refuses to leave REVIEWING
    # without an APPROVE verdict and no open BLOCKER/MAJOR findings.
    cat > "$1" << 'EOF'
# Review: afk goal

- TASK: TODO
- BRANCH: feature/thing

## Round 1

- REVIEWER: afk-test
- VERDICT: APPROVE

- [x] R1.1 (MINOR) thing.txt:1 - nit, fixed
EOF
}

gen_work_to_land() {
    # Write the four invocations that carry a WORKING task to a landed commit,
    # starting at invocation $1 + 1.
    local b=$1

    # Worker: sprout a worktree off the approved plan, commit the work. The
    # plan gate already left the cursor in WORKING, so there is nothing to
    # transition here.
    side $((b + 1)) << 'EOF'
set -e
id=$(cat "$AFK_TEST_TMP/task_id")
wt="$XDG_CACHE_HOME/sprouts/repo/feature/thing"
mkdir -p "$(dirname "$wt")"
git -C "$REPO" worktree add -q -b feature/thing "$wt" HEAD
git -C "$REPO" config extensions.worktreeConfig true
git -C "$wt" config --worktree sprout.task "$id"
echo work > "$wt/thing.txt"
git -C "$wt" add -A
git -C "$wt" commit -qm "feat: thing"
EOF
    reply $((b + 1)) "AFK WORK_DONE $(cat "$AFK_TEST_TMP/task_id")"

    # Gate: approve the review handoff.
    side $((b + 2)) << 'EOF'
set -e
id=$(cat "$AFK_TEST_TMP/task_id")
wt="$XDG_CACHE_HOME/sprouts/repo/feature/thing"
tatr -r "$wt" flow "$id" > /dev/null
git -C "$wt" add -A
git -C "$wt" commit -qm "docs: reviewing"
EOF
    reply $((b + 2)) ""

    # Worker: review APPROVE, compound, close the task. The last flow earns
    # the RETRO gate and resolves the record DONE in one motion.
    side $((b + 3)) << 'EOF'
set -e
source "$AFK_TEST_TMP/fixtures.sh"
id=$(cat "$AFK_TEST_TMP/task_id")
wt="$XDG_CACHE_HOME/sprouts/repo/feature/thing"
approved_review "$wt/tasks/$id/REVIEW.md"
tatr -r "$wt" flow "$id" > /dev/null
tatr -r "$wt" scaffold "$id" RETRO > /dev/null
tatr -r "$wt" flow "$id" > /dev/null
git -C "$wt" add -A
git -C "$wt" commit -qm "docs: retro"
EOF
    reply $((b + 3)) "AFK LAND_READY $(cat "$AFK_TEST_TMP/task_id")"

    # Gate: land, exactly as `sprout land` would.
    side $((b + 4)) << 'EOF'
set -e
wt="$XDG_CACHE_HOME/sprouts/repo/feature/thing"
git -C "$REPO" merge --squash feature/thing > /dev/null
git -C "$REPO" commit -qm "feat: land thing"
git -C "$REPO" worktree remove --force "$wt"
git -C "$REPO" branch -qD feature/thing
EOF
    reply $((b + 4)) ""
}

gen_goal_cycle() {
    # Invocation 1 of a goal run: create the task, take it to PLANNING, and -
    # now that the ID exists - write every later fixture, including its own
    # reply (the fake claude runs the side script before replaying the reply).
    side 1 << 'EOF'
set -e
source "$AFK_TEST_TMP/fixtures.sh"
cd "$REPO"
id=$(tatr new "afk goal" -t feature -p 50 | grep -oE '[0-9]{8}-[0-9]{6}' | tail -1)
printf '%s\n' "$id" > "$AFK_TEST_TMP/task_id"
tatr flow "$id" > /dev/null            # no activity -> UNDERSTANDING
tatr flow "$id" > /dev/null            # UNDERSTANDING -> PLANNING
plan_sections "$REPO/tasks/$id/TASK.md"
git -C "$REPO" add -A
git -C "$REPO" commit -qm "docs: plan the goal"
reply 1 "AFK PLAN_READY $id"
# Gate: approve the plan.
side 2 << 'INNER'
set -e
id=$(cat "$AFK_TEST_TMP/task_id")
tatr -r "$REPO" flow "$id" > /dev/null
git -C "$REPO" add -A
git -C "$REPO" commit -qm "docs: plan approved"
INNER
reply 2 ""
gen_work_to_land 2
EOF
}

seed_working_task() {
    # Create a task walked to WORKING with the PLAN gate earned, committed,
    # and record its ID.
    local id
    id=$(cd "$REPO" && tatr new "afk goal" -t feature -p 50 | grep -oE '[0-9]{8}-[0-9]{6}' | tail -1)
    printf '%s\n' "$id" > "$TMP/task_id"
    (
        cd "$REPO" || exit 1
        tatr flow "$id" > /dev/null
        tatr flow "$id" > /dev/null
        plan_sections "$REPO/tasks/$id/TASK.md"
        tatr flow "$id" > /dev/null
        git add -A
        git commit -qm "docs: plan $id"
    )
    printf '%s\n' "$id"
}

token_band_color() {
    # $1: a session's context size in tokens -> the escape sequence coloring
    # its `tokens` line, from a one-invocation run on a pty. DONE with no
    # sprout worktree is the cheapest clean exit the runner has.
    restart_sandbox
    local id
    id=$(seed_working_task)
    reply 1 "AFK DONE $id" "$1"
    script -qec "bash '$AFK' run '$id'" /dev/null > "$TMP/pty.out" 2>&1
    grep -oE $'\033\\[[0-9;]*m''tokens' "$TMP/pty.out" | head -1
}

task_field() {
    # $1: tasks root  $2: task ID  $3: field name -> that field's value, read
    # the same way afk reads it.
    tatr -r "$1" show "$2" 2> /dev/null | sed -n "s/^- $3: //p" | head -1
}

# ------------------------------------------------------------------ harness --

setup() {
    TMP=$(mktemp -d)
    export AFK_TEST_TMP="$TMP"
    export XDG_CACHE_HOME="$TMP/cache"
    export REPO="$TMP/repo"
    mkdir -p "$REPO/tasks" "$TMP/bin" "$TMP/replies" "$XDG_CACHE_HOME"
    git -C "$REPO" init -q -b master
    echo base > "$REPO/base.txt"
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm "initial"

    # The fake claude. It must be found before the real one.
    cat > "$TMP/bin/claude" << 'SHIM'
#!/usr/bin/env bash
n=$(($(cat "$AFK_TEST_TMP/n" 2> /dev/null || echo 0) + 1))
printf '%s\n' "$n" > "$AFK_TEST_TMP/n"
{
    printf 'ARGV %s' "$n"
    for a in "$@"; do printf ' <%s>' "${a//$'\n'/ }"; done
    printf '\n'
} >> "$AFK_TEST_TMP/argv.log"
printf '%s\n' "$$" > "$AFK_TEST_TMP/claude.pid.$n"
if [[ -f "$AFK_TEST_TMP/replies/$n.sh" ]]; then
    bash "$AFK_TEST_TMP/replies/$n.sh" >> "$AFK_TEST_TMP/side.log" 2>&1 ||
        printf 'SIDE %s FAILED\n' "$n" >> "$AFK_TEST_TMP/side.log"
fi
if [[ -f "$AFK_TEST_TMP/replies/$n.jsonl" ]]; then
    if [[ -f "$AFK_TEST_TMP/replies/$n.slow" ]]; then
        head -n -1 "$AFK_TEST_TMP/replies/$n.jsonl"
        # The pause is a backgrounded sleep waited on under a trap, not a
        # foreground one: bash defers a signal until the foreground child
        # exits, which would make every kill look like it took the whole
        # pause. Under the trap the last line is never printed, which is
        # exactly what a killed session does.
        trap 'exit 143' TERM INT
        sleep "$(cat "$AFK_TEST_TMP/replies/$n.slow")" &
        wait $!
        trap - TERM INT
        tail -n 1 "$AFK_TEST_TMP/replies/$n.jsonl"
    else
        cat "$AFK_TEST_TMP/replies/$n.jsonl"
    fi
fi
exit "$(cat "$AFK_TEST_TMP/replies/$n.rc" 2> /dev/null || echo 0)"
SHIM
    chmod +x "$TMP/bin/claude"
    export PATH="$TMP/bin:$PATH"

    # Fixture helpers must also be callable from the side-effect scripts.
    declare -f reply reply_raw pause side exit_rc plan_sections approved_review \
        gen_work_to_land > "$TMP/fixtures.sh"

    export AFK_HEARTBEAT_SECS=30
    export AFK_MAX_SESSIONS=20
    cd "$REPO" || exit 1
}

teardown() {
    cd / && rm -rf "$TMP"
}

restart_sandbox() {
    teardown
    setup
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

invocations() { cat "$TMP/n" 2> /dev/null || echo 0; }
argv_line() { sed -n "s/^ARGV $1 //p" "$TMP/argv.log"; }

# -------------------------------------------------------------------- tests --

test_run_goal_full_cycle() {
    local out rc id
    gen_goal_cycle
    out=$(afk run "add a thing" 2>&1)
    rc=$?
    id=$(cat "$TMP/task_id" 2> /dev/null)

    check "goal run exits 0" test "$rc" -eq 0
    check "the created task is reported" str_contains "$out" "task    $id created"
    check "the run ends with a done line" str_contains "$out" "done  $id landed"
    check "the summary counts the 3 worker sessions" str_matches "$out" '3 sessions, [0-9]+m[0-9]{2}s'
    check "3 fresh sessions and 3 gate resumes ran" test "$(invocations)" -eq 6
    check "the work landed on master" test -f "$REPO/thing.txt"
    check "the landing commit is on master" test "$(git -C "$REPO" log -1 --format=%s)" = "feat: land thing"
    check "the branch is gone" not git -C "$REPO" show-ref --verify --quiet refs/heads/feature/thing
    check "the worktree is gone" not test -d "$XDG_CACHE_HOME/$WT_REL"
    check "the landed task is resolved DONE" test "$(task_field "$REPO" "$id" RESOLUTION)" = DONE
}

test_run_task_id_resumes() {
    local out rc id
    id=$(seed_working_task)
    gen_work_to_land 0
    out=$(afk run "$id" 2>&1)
    rc=$?

    check "task-ID run exits 0" test "$rc" -eq 0
    check "the header names the existing task" str_contains "$out" "task  $id"
    check "no goal header is printed" not str_contains "$out" "goal  add"
    check "the first prompt resumes the task" str_contains "$(argv_line 1)" "</flow $id>"
    check "no task was created" test "$(find "$REPO/tasks" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1
    check "only the work-to-land sessions ran" test "$(invocations)" -eq 4
    check "the run ends with a done line" str_contains "$out" "done  $id landed"
    check "the work landed on master" test -f "$REPO/thing.txt"
}

test_run_report_reads_as_a_report() {
    local out id
    gen_goal_cycle
    out=$(afk run "add a thing" 2>&1)
    id=$(cat "$TMP/task_id" 2> /dev/null)

    check "the run reads as a phase-by-phase report" in_order "$out" \
        "afk  unattended flow runner" \
        "goal  add a thing" \
        "session 1" \
        'prompt  /flow "add a thing"' \
        "tokens  57.6K" \
        "task    $id created" \
        "phase   PLANNING  writing the plan" \
        "commit  " \
        "gate    plan ready - approved automatically" \
        "phase   WORKING+PLAN  building on the feature branch" \
        "session 2" \
        "prompt  /flow $id" \
        "gate    work done - approved automatically" \
        "phase   REVIEWING+PLAN  reviewing the branch" \
        "session 3" \
        "phase   DONE  finished, ready to land" \
        "gate    landing - approved automatically" \
        "landed  " \
        "cleanup feature/thing worktree removed" \
        "done  $id landed" \
        "3 sessions, "
    check "the repository is named up front" str_contains "$out" "repo  $REPO"
    check "the branch commit is reported" str_matches "$out" 'commit  [0-9a-f]{7} feat: thing'
    check "the landing commit is reported" str_matches "$out" 'landed  [0-9a-f]{7} feat: land thing'
    check "elapsed time is reported" str_matches "$out" '3 sessions, [0-9]+m[0-9]{2}s'
    check "every auto-approved gate says why it was automatic" \
        test "$(printf '%s\n' "$out" | grep -c 'approved automatically, starting an afk run approves the flow gates')" -eq 3
}

test_session_header_names_the_claude_session_id() {
    local out i session uuid
    gen_goal_cycle
    out=$(afk run "add a thing" 2>&1)

    session=0
    for i in 1 3 5; do
        session=$((session + 1))
        uuid=$(printf '%s\n' "$(argv_line "$i")" |
            sed -n 's/.*<--session-id> <\([0-9a-f-]*\)>.*/\1/p')
        check "invocation $i was started with a session ID" \
            str_matches "$uuid" '^[0-9a-f-]{36}$'
        check "the session $session header names that Claude session ID" \
            str_contains "$out" "session $session  $uuid"
    done

    check "no session header carries the phase" \
        not str_matches "$out" 'session [0-9]+  (starting|OPEN|PLANNING|WORKING|REVIEWING)'
}

test_argv_session_and_resume_policy() {
    local i line fresh_ids resume_id
    gen_goal_cycle
    afk run "add a thing" > /dev/null 2>&1

    for i in 1 2 3 4 5 6; do
        line=$(argv_line "$i")
        check "invocation $i skips permission prompts" str_contains "$line" "<--dangerously-skip-permissions>"
        check "invocation $i denies the question tool" str_contains "$line" "<--disallowed-tools> <AskUserQuestion>"
        check "invocation $i streams structured events" str_contains "$line" "<--output-format> <stream-json>"
        check "invocation $i injects the marker protocol" str_contains "$line" "<--append-system-prompt>"
    done

    fresh_ids=""
    for i in 1 3 5; do
        line=$(argv_line "$i")
        check "worker invocation $i starts a fresh session" str_matches "$line" '<--session-id> <[0-9a-f-]{36}>'
        check "worker invocation $i never resumes" not str_contains "$line" "<--resume>"
        fresh_ids="$fresh_ids$(printf '%s\n' "$line" | sed -n 's/.*<--session-id> <\([0-9a-f-]*\)>.*/\1/p')
"
    done
    check "each worker session has its own ID" test "$(printf '%s' "$fresh_ids" | sort -u | wc -l)" -eq 3

    for i in 2 4 6; do
        line=$(argv_line "$i")
        check "gate invocation $i resumes exactly one session" \
            test "$(printf '%s\n' "$line" | grep -oc -- '<--resume>')" -eq 1
        check "gate invocation $i mints no new session" not str_contains "$line" "<--session-id>"
        resume_id=$(printf '%s\n' "$line" | sed -n 's/.*<--resume> <\([0-9a-f-]*\)>.*/\1/p')
        check "gate invocation $i resumes the preceding worker session" \
            str_contains "$fresh_ids" "$resume_id"
    done

    check "the plan gate sends the exact label" \
        str_contains "$(argv_line 2)" "<Approve plan - earn the PLAN gate>"
    check "the review gate sends the exact label" \
        str_contains "$(argv_line 4)" "<Approve review - move to REVIEWING>"
    check "the landing gate sends the exact label" \
        str_contains "$(argv_line 6)" "<Approve landing - land the branch>"
}

test_failure_paths() {
    local id out rc

    # A structured error result, even with subtype "success".
    id=$(seed_working_task)
    reply_raw 1 << 'EOF'
{"type":"result","subtype":"success","is_error":true,"result":"Claude usage limit reached"}
EOF
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "an error result fails the run" test "$rc" -ne 0
    check "the error result is reported" str_contains "$out" "usage limit reached"
    check "no further session is started" test "$(invocations)" -eq 1

    # A nonzero claude exit.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK ROTATE $id"
    exit_rc 1 9
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a nonzero claude exit fails the run" test "$rc" -ne 0
    check "the exit status is reported" str_contains "$out" "status 9"

    # A stall: no event within the heartbeat.
    restart_sandbox
    id=$(seed_working_task)
    side 1 << 'EOF'
sleep 20
EOF
    reply 1 "AFK ROTATE $id"
    AFK_HEARTBEAT_SECS=2 afk run "$id" > "$TMP/stall.out" 2>&1
    rc=$?
    out=$(cat "$TMP/stall.out")
    check "a stalled session fails the run" test "$rc" -ne 0
    check "the stall is named" str_contains "$out" "no output for 2s"

    # An unknown control status.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK WAT $id"
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "an unknown status fails the run" test "$rc" -ne 0
    check "the unknown status is named" str_contains "$out" "WAT"

    # A missing control marker.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "the phase went fine, honest"
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a missing marker fails the run" test "$rc" -ne 0
    check "the missing marker is named" str_contains "$out" "no AFK control marker"

    # A marker for a different task.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK ROTATE 19990101-000000"
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a foreign task ID fails the run" test "$rc" -ne 0
    check "the mismatch is named" str_contains "$out" "19990101-000000"

    # Goal mode - the only path with no task ID up front - reporting an ID that
    # was never written to disk.
    restart_sandbox
    reply 1 "AFK ROTATE 19990101-000000"
    out=$(afk run "invent a task" 2>&1)
    rc=$?
    check "an unrecorded task ID fails the run" test "$rc" -ne 0
    check "the failure says no such record exists" str_contains "$out" "no such record"
    check "the phantom task is not adopted" not str_contains "$out" "created"

    # A marker whose gate disagrees with durable state: PLAN_READY at a task
    # whose plan gate is already earned.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK PLAN_READY $id"
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a gate at the wrong activity fails the run" test "$rc" -ne 0
    check "the inconsistency is named" str_contains "$out" "PLANNING"
    check "the gate was never answered" test "$(invocations)" -eq 1

    # A gate approval that does not cause its transition.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK WORK_DONE $id"
    reply 2 ""
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "an ineffective approval fails the run" test "$rc" -ne 0
    check "the expected activity is named" str_contains "$out" "REVIEWING"
    check "the gate was answered once" test "$(invocations)" -eq 2

    # LAND_READY approved, but the branch never landed.
    restart_sandbox
    id=$(seed_working_task)
    (
        cd "$REPO" || exit 1
        git worktree add -q -b feature/thing "$XDG_CACHE_HOME/$WT_REL" HEAD
        git config extensions.worktreeConfig true
        git -C "$XDG_CACHE_HOME/$WT_REL" config --worktree sprout.task "$id"
        tatr -r "$XDG_CACHE_HOME/$WT_REL" flow "$id" > /dev/null
    )
    approved_review "$XDG_CACHE_HOME/$WT_REL/tasks/$id/REVIEW.md"
    (
        cd "$XDG_CACHE_HOME/$WT_REL" || exit 1
        tatr flow "$id" > /dev/null
        tatr scaffold "$id" RETRO > /dev/null
        tatr flow "$id" > /dev/null
        git add -A && git commit -qm "docs: done"
    )
    reply 1 "AFK LAND_READY $id"
    reply 2 ""
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "an unlanded branch fails the run" test "$rc" -ne 0
    check "the missing landing commit is named" str_contains "$out" "no commit"
    check "the branch survives for a retry" git -C "$REPO" show-ref --verify --quiet refs/heads/feature/thing

    # A half-landing: a commit appears on master but the branch is still
    # there, so the squash-and-clean-up never happened.
    rm -f "$TMP/n" "$TMP/argv.log"
    reply 1 "AFK LAND_READY $id"
    side 2 << 'EOF'
set -e
cd "$REPO"
echo half >> base.txt
git commit -aqm "not a landing"
EOF
    reply 2 ""
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a half-landing fails the run" test "$rc" -ne 0
    check "the surviving branch is named" str_contains "$out" "branch feature/thing still exists"

    # A spiked flow: the runner must not pick a seeded task by itself.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK SPIKED $id"
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a spiked flow fails the run" test "$rc" -ne 0
    check "the spike hands back to the user" str_contains "$out" "seeded"

    # The rotation bound.
    restart_sandbox
    id=$(seed_working_task)
    side 1 << 'EOF'
set -e
cd "$REPO"
echo progress >> base.txt
git commit -aqm "wip"
EOF
    reply 1 "AFK ROTATE $id"
    reply 2 "AFK ROTATE $id"
    out=$(AFK_MAX_SESSIONS=1 afk run "$id" 2>&1)
    rc=$?
    check "the rotation bound fails the run" test "$rc" -ne 0
    check "the bound is named" str_contains "$out" "AFK_MAX_SESSIONS"
    check "no session past the bound is started" test "$(invocations)" -eq 1
}

test_verbose_echoes_assistant_text() {
    # run_claude consumes the whole stream and prints nothing from it, so
    # AFK_VERBOSE is the only way to watch a live session.
    local id out

    id=$(seed_working_task)
    gen_work_to_land 0
    out=$(AFK_VERBOSE=1 afk run "$id" 2>&1)
    check "verbose echoes assistant text, prefixed" str_contains "$out" "| phase running"
    check "verbose does not echo the result text" not str_contains "$out" "| phase summary"

    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 0
    out=$(afk run "$id" 2>&1)
    check "the default suppresses assistant text" not str_contains "$out" "phase running"
}

test_session_token_report() {
    # The context meter: one permanent line per claude invocation, formatted in
    # K, colored by which side of the 120K/180K thresholds it lands on.
    local id out rc c_ok c_ok_edge c_warn c_warn_edge c_hot

    id=$(seed_working_task)
    gen_work_to_land 0
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a run reporting tokens exits 0" test "$rc" -eq 0
    check "every claude invocation reports its context size" \
        test "$(printf '%s\n' "$out" | grep -c '^  tokens  57\.6K$')" -eq 4
    check "the count is the four usage fields summed" \
        not str_contains "$out" "57.5K"

    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK DONE $id" 119999
    out=$(afk run "$id" 2>&1)
    check "the count is formatted in K with one decimal" \
        str_contains "$out" "tokens  119.9K"

    c_ok=$(token_band_color 57600)
    c_ok_edge=$(token_band_color 119999)
    c_warn=$(token_band_color 120000)
    c_warn_edge=$(token_band_color 179999)
    c_hot=$(token_band_color 180000)

    check "the tokens line is colored on a TTY" str_matches "${c_ok:-}" "^"$'\033'
    check "119999 is still in the low band" test "$c_ok_edge" = "$c_ok"
    check "120000 leaves the low band" not test "$c_warn" = "$c_ok"
    check "179999 is still in the middle band" test "$c_warn_edge" = "$c_warn"
    check "180000 leaves the middle band" not test "$c_hot" = "$c_warn"
    check "the top band differs from the low band" not test "$c_hot" = "$c_ok"

    restart_sandbox
    id=$(seed_working_task)
    reply_raw 1 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}]}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\\nAFK DONE $id"}
EOF
    out=$(afk run "$id" 2>&1)
    rc=$?
    check "a stream carrying no usage still succeeds" test "$rc" -eq 0
    check "a stream carrying no usage prints no tokens line" \
        not str_contains "$out" "tokens"

    # A dying invocation is the case the meter exists for: a session that
    # stalls or blows up is the one whose context size a human wants. Each of
    # these kills the run down a different path, all of them after the
    # assistant event that carried the count.
    restart_sandbox
    id=$(seed_working_task)
    reply 1 "AFK ROTATE $id"
    exit_rc 1 9
    out=$(afk run "$id" 2>&1)
    check "a nonzero claude exit still reports the count" \
        str_contains "$out" "tokens  57.6K"

    restart_sandbox
    id=$(seed_working_task)
    reply_slow 1 "AFK ROTATE $id" 20
    AFK_HEARTBEAT_SECS=2 afk run "$id" > "$TMP/stall.out" 2>&1
    check "a stalled session still reports the count" \
        str_contains "$(cat "$TMP/stall.out")" "tokens  57.6K"

    restart_sandbox
    id=$(seed_working_task)
    reply_raw 1 << 'EOF'
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":57594,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"result","subtype":"success","is_error":true,"result":"Claude usage limit reached"}
EOF
    out=$(afk run "$id" 2>&1)
    check "an error result still reports the count" \
        str_contains "$out" "tokens  57.6K"

    restart_sandbox
    id=$(seed_working_task)
    reply_raw 1 << 'EOF'
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":57594,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
EOF
    out=$(afk run "$id" 2>&1)
    check "a stream with no terminal result still reports the count" \
        str_contains "$out" "tokens  57.6K"
}

test_spinner_and_color_only_on_a_tty() {
    # The decoration is the ONLY thing that may differ between a terminal and a
    # pipe, so both halves of this run the same fixtures the same way.
    local id pty plain rc gate_color commit_color
    local spinner_re='[|/\-] working  WORKING\+PLAN  [0-9]+m[0-9]{2}s  57\.6K  phase running'
    local color_re=$'\033\\[[0-9;]*m'

    id=$(seed_working_task)
    gen_work_to_land 0
    reply_slow 1 "AFK WORK_DONE $id" 1.2
    script -qec "bash '$AFK' run '$id'" /dev/null > "$TMP/pty.out" 2>&1
    rc=$?
    pty=$(cat "$TMP/pty.out")

    check "the pty run exits 0" test "$rc" -eq 0
    check "a spinner frame carries the phase, elapsed time and latest message" \
        str_matches "$pty" "$spinner_re"
    gate_color=$(printf '%s\n' "$pty" | grep -oE "$color_re"'gate' | head -1)
    commit_color=$(printf '%s\n' "$pty" | grep -oE "$color_re"'commit' | head -1)
    check "the gate label is colored" str_matches "${gate_color:-}" "^$color_re"
    check "the commit label is colored" str_matches "${commit_color:-}" "^$color_re"
    check "gate and commit are colored differently" \
        not test "${gate_color%gate}" = "${commit_color%commit}"

    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 0
    reply_slow 1 "AFK WORK_DONE $id" 1.2
    plain=$(afk run "$id" 2>&1)
    rc=$?

    check "the piped run exits 0" test "$rc" -eq 0
    check "no escape sequence off a TTY" not str_contains "$plain" $'\033'
    check "no spinner line off a TTY" not str_contains "$plain" " working  "
    check "the tokens line survives off a TTY" str_contains "$plain" "tokens  57.6K"
    check "the report itself is unchanged" str_contains "$plain" "done  $id landed"
}

test_spinner_never_wraps() {
    # A spinner frame is only safe to erase with `\r\033[K` if it occupies
    # exactly one row, so every frame must be written with autowrap off. The
    # assertions are on the RAW pty capture, not on the rendered screen: the
    # escape sequences ARE the mechanism under test.
    local id wide cap chunk frames=0 clears=0 bad_open=0 bad_close=0 newlines=0
    local esc=$'\033'
    local -a chunks

    id=$(seed_working_task)
    gen_work_to_land 0
    reply_slow 1 "AFK WORK_DONE $id" 1.2
    # 80 double-width glyphs: 160 display columns, and exactly the input the
    # character-counting truncation under-measures. reply_slow's transcript is
    # replaced, but its pause is kept, so at least one frame is drawn.
    wide=$(printf '漢%.0s' {1..80})
    reply_raw 1 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"$wide"}],"usage":{"input_tokens":57594,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\nAFK WORK_DONE $id"}
EOF

    # The pty is forced narrow so the payload also over-runs afk's own idea of
    # the width; the glyphs alone would already exceed any real terminal.
    script -qec "stty cols 40 < /dev/tty; bash '$AFK' run '$id'" /dev/null \
        > "$TMP/pty.out" 2>&1
    cap=$(cat "$TMP/pty.out")

    # Every spinner write starts at column 0 and erases the row first, so
    # splitting on CR and keeping the chunks that open with an erase yields the
    # spinner's writes. Only the frames are CR-terminated - an erase is
    # followed straight away by the permanent line it made room for, in the
    # same chunk - so both kinds are recognized by their PREFIX.
    IFS=$'\r' read -r -d '' -a chunks < <(printf '%s\0' "$cap")
    for chunk in "${chunks[@]}"; do
        [[ $chunk == "$esc[K"* ]] || continue
        if [[ $chunk == "$esc[K$esc[?7h"* ]]; then
            clears=$((clears + 1))
            continue
        fi
        frames=$((frames + 1))
        [[ $chunk == "$esc[K$esc[?7l"* ]] || bad_open=$((bad_open + 1))
        [[ $chunk == *"$esc[?7h" ]] || bad_close=$((bad_close + 1))
        [[ $chunk == *$'\n'* ]] && newlines=$((newlines + 1))
    done

    check "the wide-message run drew at least one spinner frame" \
        test "$frames" -ge 1
    check "every frame disables autowrap before its text" test "$bad_open" -eq 0
    check "every frame re-enables autowrap after its text" \
        test "$bad_close" -eq 0
    check "no spinner frame contains a newline" test "$newlines" -eq 0
    check "erasing the spinner also restores autowrap" test "$clears" -ge 1
    # On a pty the label is colored, so the needle carries the reset the piped
    # run does not have; everything after it is the same content.
    check "the report's permanent lines survive" \
        str_contains "$cap" "done$esc[0m  $id landed"
}

test_spinner_strips_control_bytes() {
    # Assistant text reaches the spinner as SPIN_MSG, so a raw CR or ESC in it
    # would be executed by the terminal rather than shown: a CR splits the
    # frame's own single write, an ESC starts a sequence the frame never
    # closes. Both are flattened by the sanitizer, and both are asserted on the
    # RAW pty capture, where the leak would be visible.
    local id payload cap chunk body frames=0 bad_close=0 leaked=0 carried=0
    local esc=$'\033'
    local -a chunks

    id=$(seed_working_task)
    gen_work_to_land 0
    reply_slow 1 "AFK WORK_DONE $id" 1.2
    # Built with printf, not written literally, so the control bytes cannot be
    # lost to an editor or a diff. jq -Rs makes the JSON string, so the
    # transcript stays valid input for afk's own jq extraction. reply_slow's
    # transcript is replaced but its pause is kept, so a frame is drawn.
    payload=$(printf 'alpha\rbeta\033[31mgamma' | jq -Rs .)
    reply_raw 1 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":$payload}],"usage":{"input_tokens":57594,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\nAFK WORK_DONE $id"}
EOF

    # 80 columns, unlike the wrap test's 40: the sanitized message must SURVIVE
    # `${text:0:$((TERM_COLS - 1))}` for its bytes to be assertable at all.
    script -qec "stty cols 80 < /dev/tty; bash '$AFK' run '$id'" /dev/null \
        > "$TMP/pty.out" 2>&1
    cap=$(cat "$TMP/pty.out")

    # Same frame recognition as test_spinner_never_wraps: split on CR, keep the
    # chunks that open with an erase, and separate frames from bare erases by
    # the autowrap directive that follows.
    IFS=$'\r' read -r -d '' -a chunks < <(printf '%s\0' "$cap")
    for chunk in "${chunks[@]}"; do
        [[ $chunk == "$esc[K$esc[?7l"* ]] || continue
        frames=$((frames + 1))
        # A leaked CR would end this chunk early, before the frame's own
        # trailing directive - that is what makes CR observable here.
        if [[ $chunk == *"$esc[?7h" ]]; then
            body=${chunk#"$esc[K$esc[?7l"}
            body=${body%"$esc[?7h"}
        else
            bad_close=$((bad_close + 1))
            continue
        fi
        [[ $body == *"$esc"* ]] && leaked=$((leaked + 1))
        [[ $body == *"[31mgamma"* ]] && carried=$((carried + 1))
    done

    check "the control-byte run drew at least one spinner frame" \
        test "$frames" -ge 1
    check "no frame is cut short by a carriage return" test "$bad_close" -eq 0
    check "no frame body carries an escape byte" test "$leaked" -eq 0
    # Without this a frame that truncated the message away would pass the two
    # assertions above vacuously.
    check "a frame carries the message past the stripped escape" \
        test "$carried" -ge 1
}

test_interrupt_kills_recorded_pid() {
    local id afk_pid bystander_pid claude_pid rc waited
    local activity_before activity_after
    id=$(seed_working_task)
    activity_before=$(task_field "$REPO" "$id" ACTIVITY)
    side 1 << 'EOF'
sleep 20
EOF
    reply 1 "AFK ROTATE $id"

    sleep 20 &
    bystander_pid=$!

    # A background job in a non-interactive shell inherits SIGINT ignored, and
    # an ignored signal cannot be trapped, so the runner would never see it.
    # Monitor mode gives each job its own process group with default signal
    # dispositions - which is also what a real terminal run has.
    set -m
    # Started directly, not through the afk() helper: a function in a
    # background subshell would put the signal on the subshell, not on the
    # runner whose trap is under test.
    bash "$AFK" run "$id" > "$TMP/out" 2>&1 &
    afk_pid=$!
    set +m

    waited=0
    while [[ ! -f "$TMP/claude.pid.1" && $waited -lt 100 ]]; do
        sleep 0.1
        waited=$((waited + 1))
    done
    claude_pid=$(cat "$TMP/claude.pid.1" 2> /dev/null)
    check "the claude process was recorded" str_matches "${claude_pid:-}" '^[0-9]+$'

    kill -INT "$afk_pid"
    wait "$afk_pid"
    rc=$?
    activity_after=$(task_field "$REPO" "$id" ACTIVITY)

    check "an interrupted run exits non-zero" test "$rc" -ne 0
    check "the interruption is reported" str_contains "$(cat "$TMP/out")" "interrupted"
    check "the recorded claude process is dead" dead "$claude_pid"
    check "unrelated processes survive" alive "$bystander_pid"
    check "the task record is untouched" test "$activity_after" = "$activity_before"
    check "the run is resumable from durable state" test "$activity_after" = WORKING
    kill "$bystander_pid" 2> /dev/null
}

test_no_progress_fingerprint_stops() {
    local id out rc
    id=$(seed_working_task)
    reply 1 "AFK ROTATE $id"
    reply 2 "AFK ROTATE $id"
    reply 3 "AFK ROTATE $id"
    out=$(afk run "$id" 2>&1)
    rc=$?

    check "a stuck run exits non-zero" test "$rc" -ne 0
    check "the lack of progress is named" str_contains "$out" "no durable progress"
    check "it stops at the second identical fingerprint" test "$(invocations)" -eq 2
}

test_token_limit_rotation() {
    # The context meter is also a governor. A session that grows past a limit
    # is stopped and rotated, and because a killed session emits no marker,
    # durable state alone routes what comes next - the same route ROTATE takes.
    local id out rc t0 elapsed i

    # Soft limit: armed by the assistant event, fired by the next completed
    # tool call. The stop lands on that boundary, so neither the transcript's
    # long pause nor the BLOCKED marker behind it is ever reached, and a fresh
    # session carries the task the rest of the way.
    id=$(seed_working_task)
    gen_work_to_land 1
    reply_raw 1 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{}}],"usage":{"input_tokens":149994,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"user","message":{"content":[{"type":"tool_result","content":"ok"}]}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\nAFK BLOCKED $id"}
EOF
    pause 1 10
    t0=$SECONDS
    out=$(AFK_SOFT_TOKENS=100000 AFK_HARD_TOKENS=900000 afk run "$id" 2>&1)
    rc=$?
    elapsed=$((SECONDS - t0))

    check "a soft-limit stop still lands the run" test "$rc" -eq 0
    check "the soft limit is named on the next line" \
        str_contains "$out" "soft context limit crossed at 150.0K"
    check "the stopped session still reports its count" \
        str_contains "$out" "tokens  150.0K"
    check "the stop rotates to a fresh session" str_contains "$out" "session 2"
    check "the rotated run reaches the landing" str_contains "$out" "done  $id landed"
    check "the stop happens at the tool boundary, not after the pause" \
        test "$elapsed" -lt 8
    check "the killed session's own marker never routes anything" \
        not str_contains "$out" "the flow is blocked"

    # Armed but never given a boundary: every one of these sessions is over the
    # soft limit and none of them completes a tool call, so all four run to
    # their own result event and their markers route the whole cycle.
    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 0
    out=$(AFK_SOFT_TOKENS=1000 AFK_HARD_TOKENS=900000 afk run "$id" 2>&1)
    rc=$?

    check "an armed session with no tool result runs to its own end" \
        test "$rc" -eq 0
    check "and is routed by its own marker" str_contains "$out" "done  $id landed"
    check "every session was over the soft limit" \
        str_contains "$out" "tokens  57.6K"
    check "no session was stopped" not str_contains "$out" "context limit"
    check "only the work-to-land sessions ran" test "$(invocations)" -eq 4

    # Tools run in parallel, and each result comes back as its own user event,
    # so the FIRST result is not the boundary - the last one is. The second
    # result here is held behind the transcript's pause, so a stop that fired on
    # the first would land before it.
    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 1
    reply_raw 1 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{}},{"type":"tool_use","name":"Edit","input":{}}],"usage":{"input_tokens":149994,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"user","message":{"content":[{"type":"tool_result","content":"read"}]}}
{"type":"user","message":{"content":[{"type":"tool_result","content":"edited"}]}}
EOF
    pause 1 4
    t0=$SECONDS
    out=$(AFK_SOFT_TOKENS=100000 AFK_HARD_TOKENS=900000 afk run "$id" 2>&1)
    rc=$?
    elapsed=$((SECONDS - t0))

    check "a parallel-tool session is still stopped and landed" test "$rc" -eq 0
    check "the parallel-tool stop names the soft limit" \
        str_contains "$out" "soft context limit crossed at 150.0K"
    check "the stop waits for the outstanding sibling tool" test "$elapsed" -ge 3
    check "the parallel-tool run continues in a fresh session" \
        str_contains "$out" "done  $id landed"

    # Hard limit: no boundary, no waiting. The transcript offers no tool result
    # at all and the stop still fires on the assistant event that crossed it.
    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 1
    reply_raw 1 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":299994,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\nAFK BLOCKED $id"}
EOF
    pause 1 10
    t0=$SECONDS
    out=$(AFK_SOFT_TOKENS=100000 AFK_HARD_TOKENS=200000 afk run "$id" 2>&1)
    rc=$?
    elapsed=$((SECONDS - t0))

    check "a hard-limit stop still lands the run" test "$rc" -eq 0
    check "the hard limit is named" \
        str_contains "$out" "hard context limit crossed at 300.0K"
    check "the hard stop waits for no boundary" test "$elapsed" -lt 8
    check "the run continues in a fresh session" str_contains "$out" "done  $id landed"

    # A gate resume is one of the largest invocations afk makes, so it is
    # stopped like any other. A half-answered gate is not an approved one: the
    # run rotates, and a fresh /flow re-reaches the same gate from tatr.
    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 0
    reply_raw 2 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":299994,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\nAFK BLOCKED $id"}
EOF
    out=$(AFK_SOFT_TOKENS=100000 AFK_HARD_TOKENS=200000 afk run "$id" 2>&1)
    rc=$?

    check "a gate stopped on a limit does not fail the run" test "$rc" -eq 0
    check "the stopped gate rotates" str_contains "$out" "hard context limit"
    check "the rotated gate still reaches the landing" \
        str_contains "$out" "done  $id landed"

    # The landing gate has its own copy of that route. A stop there leaves the
    # branch unlanded, so the run must rotate rather than die on the
    # "produced no commit" check that guards an approved landing.
    restart_sandbox
    id=$(seed_working_task)
    gen_work_to_land 0
    side 4 < /dev/null
    reply_raw 4 << EOF
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":299994,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
{"type":"result","subtype":"success","is_error":false,"result":"phase summary\nAFK BLOCKED $id"}
EOF
    # The task is already DONE, so the fresh session only re-reports the gate;
    # its resume is what finally lands.
    reply 5 "AFK LAND_READY $id"
    side 6 << 'EOF'
set -e
wt="$XDG_CACHE_HOME/sprouts/repo/feature/thing"
git -C "$REPO" merge --squash feature/thing > /dev/null
git -C "$REPO" commit -qm "feat: land thing"
git -C "$REPO" worktree remove --force "$wt"
git -C "$REPO" branch -qD feature/thing
EOF
    reply 6 ""
    out=$(AFK_SOFT_TOKENS=100000 AFK_HARD_TOKENS=200000 afk run "$id" 2>&1)
    rc=$?

    check "a stopped landing gate does not fail the run" test "$rc" -eq 0
    check "the stopped landing gate rotates" str_contains "$out" "hard context limit"
    check "it does not die on the produced-no-commit check" \
        not str_contains "$out" "produced no commit"
    check "the rotated landing gate lands the branch" \
        str_contains "$out" "done  $id landed"

    # Two token rotations that change nothing durable is a run going nowhere,
    # and the existing fingerprint check is what stops it.
    restart_sandbox
    id=$(seed_working_task)
    for i in 1 2; do
        reply_raw "$i" << 'EOF'
{"type":"system","subtype":"init","session_id":"fake"}
{"type":"assistant","message":{"content":[{"type":"text","text":"phase running"}],"usage":{"input_tokens":299994,"cache_creation_input_tokens":1,"cache_read_input_tokens":2,"output_tokens":3}}}
EOF
    done
    out=$(AFK_SOFT_TOKENS=100000 AFK_HARD_TOKENS=200000 afk run "$id" 2>&1)
    rc=$?

    check "two token stops with no progress fail the run" test "$rc" -ne 0
    check "the lack of progress is named" str_contains "$out" "no durable progress"
    check "it stops at the second token rotation" test "$(invocations)" -eq 2
}

test_usage() {
    local out
    check "help exits 0" quiet afk help
    out=$(afk help 2>&1)
    check "help documents run" str_contains "$out" "run <goal|task-id>"
    check "help documents the soft limit" str_contains "$out" "AFK_SOFT_TOKENS"
    check "help documents the hard limit" str_contains "$out" "AFK_HARD_TOKENS"
    check "an unknown command fails" not quiet afk frobnicate
    check "run without an argument fails" not quiet afk run
    check "run with two arguments fails" not quiet afk run a b
    out=$(cd "$TMP" && afk run "goal" 2>&1)
    check "outside a repository the run fails" not test $? -eq 0
    check "the missing repository is named" str_contains "$out" "not inside a git repository"
}

echo "== afk integration tests =="
run_test test_usage
run_test test_run_goal_full_cycle
run_test test_run_task_id_resumes
run_test test_run_report_reads_as_a_report
run_test test_session_header_names_the_claude_session_id
run_test test_argv_session_and_resume_policy
run_test test_failure_paths
run_test test_verbose_echoes_assistant_text
run_test test_session_token_report
run_test test_spinner_and_color_only_on_a_tty
run_test test_spinner_never_wraps
run_test test_spinner_strips_control_bytes
run_test test_interrupt_kills_recorded_pid
run_test test_no_progress_fingerprint_stops
run_test test_token_limit_rotation
echo
echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]
