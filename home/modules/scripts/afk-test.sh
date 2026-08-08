#!/usr/bin/env bash
# Integration tests for afk.sh with a fake Claude process.
set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
AFK="$SCRIPT_DIR/afk.sh"
PASS=0
FAIL=0

check() {
    local name=$1
    shift
    if "$@"; then PASS=$((PASS + 1)); else
        printf 'FAIL %s\n' "$name"
        FAIL=$((FAIL + 1))
    fi
}

contains() { [[ $1 == *"$2"* ]]; }

setup() {
    AFK_TEST_TMP=$(mktemp -d)
    export AFK_TEST_TMP
    export REPO="$AFK_TEST_TMP/repo"
    mkdir -p "$REPO/tasks/20260808-120000" "$AFK_TEST_TMP/bin"
    git -C "$REPO" init -q -b master
    git -C "$REPO" config user.name afk-test
    git -C "$REPO" config user.email afk-test@example.invalid
    printf 'base\n' > "$REPO/base"
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm initial

    cat > "$AFK_TEST_TMP/bin/uuidgen" <<'EOF'
#!/usr/bin/env bash
printf '00000000-0000-4000-8000-000000000000\n'
EOF
    chmod +x "$AFK_TEST_TMP/bin/uuidgen"
    export PATH="$AFK_TEST_TMP/bin:$PATH"
}

write_task() {
    cat > "$REPO/tasks/20260808-120000/TASK.md" <<'EOF'
# Planned task

- STATUS: IN_PROGRESS

## Steps

- [ ] Make the change.

## Definition of Done

- Change works. (cmd: `true`)
EOF
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm plan
}

fake_claude() {
    local marker=$1 side=${2:-:}
    cat > "$AFK_TEST_TMP/bin/claude" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" > "\$AFK_TEST_TMP/argv"
$side
printf '%s\n' '{"type":"result","is_error":false,"result":"$marker"}'
EOF
    chmod +x "$AFK_TEST_TMP/bin/claude"
}

test_requires_task_id() {
    setup
    local out rc
    out=$(cd "$REPO" && bash "$AFK" run "write a goal" 2>&1); rc=$?
    check "reject goal text" test "$rc" -ne 0
    check "name invalid ID" contains "$out" "invalid task ID"
    rm -rf "$AFK_TEST_TMP"
}

test_requires_plan() {
    setup
    printf '# Task\n\n- STATUS: IN_PROGRESS\n' > "$REPO/tasks/20260808-120000/TASK.md"
    local out rc
    out=$(cd "$REPO" && bash "$AFK" run 20260808-120000 2>&1); rc=$?
    check "reject unplanned task" test "$rc" -ne 0
    check "name required sections" contains "$out" "non-empty Steps and Definition of Done"
    check "start no session" test ! -e "$AFK_TEST_TMP/argv"
    rm -rf "$AFK_TEST_TMP"
}

test_protocol_and_completion() {
    setup
    write_task
    fake_claude "AFK FLOW_DONE 20260808-120000" \
        "sed -i 's/IN_PROGRESS/CLOSED/' \"\$REPO/tasks/20260808-120000/TASK.md\""
    local out rc argv
    out=$(cd "$REPO" && bash "$AFK" run 20260808-120000 2>&1); rc=$?
    argv=$(cat "$AFK_TEST_TMP/argv")
    check "complete planned task" test "$rc" -eq 0
    check "use AFK prompt" contains "$argv" "Continue planned task 20260808-120000"
    check "inject work-review-compound protocol" contains "$argv" "Use the work skill"
    check "report landing" contains "$out" "20260808-120000 landed"
    rm -rf "$AFK_TEST_TMP"
}

test_blocked() {
    setup
    write_task
    fake_claude "AFK BLOCKED 20260808-120000 dirty-main"
    local out rc
    out=$(cd "$REPO" && bash "$AFK" run 20260808-120000 2>&1); rc=$?
    check "blocked exits nonzero" test "$rc" -ne 0
    check "blocked reason reported" contains "$out" "afk blocked: dirty-main"
    rm -rf "$AFK_TEST_TMP"
}

test_rejects_bad_completion() {
    setup
    write_task
    fake_claude "AFK FLOW_DONE 20260808-120000"
    local out rc
    out=$(cd "$REPO" && bash "$AFK" run 20260808-120000 2>&1); rc=$?
    check "open completion fails" test "$rc" -ne 0
    check "completion requires closed task" contains "$out" "task 20260808-120000 is not CLOSED"
    rm -rf "$AFK_TEST_TMP"
}

test_rejects_bad_marker() {
    setup
    write_task
    fake_claude "AFK FLOW_DONE 19990101-000000"
    local out rc
    out=$(cd "$REPO" && bash "$AFK" run 20260808-120000 2>&1); rc=$?
    check "foreign marker fails" test "$rc" -ne 0
    check "foreign marker names mismatch" contains "$out" "expected 20260808-120000"
    rm -rf "$AFK_TEST_TMP"
}

test_batch_validates_first() {
    setup
    write_task
    fake_claude "AFK BLOCKED 20260808-120000 should-not-run"
    local out rc
    out=$(cd "$REPO" && bash "$AFK" run 20260808-120000 19990101-000000 2>&1); rc=$?
    check "bad batch fails" test "$rc" -ne 0
    check "bad batch starts no session" test ! -e "$AFK_TEST_TMP/argv"
    rm -rf "$AFK_TEST_TMP"
}

test_requires_task_id
test_requires_plan
test_protocol_and_completion
test_blocked
test_rejects_bad_completion
test_rejects_bad_marker
test_batch_validates_first

printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
