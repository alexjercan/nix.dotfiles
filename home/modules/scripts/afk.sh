#!/usr/bin/env bash
# afk - run /flow unattended through disposable Claude Code sessions.
# /flow owns the workflow. afk only creates/resumes tasks, rotates context,
# checks durable progress, and stops on completion or a human blocker.

set +o errexit
set +o pipefail
set +o nounset

usage() {
    echo "Usage: afk <COMMAND> [ARGS]"
    echo "Run /flow unattended through fresh Claude Code sessions."
    echo
    echo "Commands:"
    echo "  run <goal|task-id>...  Run goals/tasks sequentially until landed"
    echo "  help                   Show this help message"
    echo
    echo "Environment:"
    echo "  AFK_HEARTBEAT_SECS  Stall timeout between stream events (default 900)"
    echo "  AFK_SOFT_TOKENS     Rotate after a completed tool call (default 180000)"
    echo "  AFK_HARD_TOKENS     Rotate immediately (default 200000)"
    echo "  AFK_MAX_SESSIONS    Fresh sessions per item (default 40)"
    echo "  AFK_VERBOSE         Set to 1 to echo Claude assistant text"
}

read -r -d '' PROTOCOL <<'EOF_PROTOCOL'
AFK RUNNER PROTOCOL

You are running unattended. AskUserQuestion is disabled. Run the requested
/flow autonomously and use durable task artifacts for handoff across sessions.

For a task, keep its tatr STATUS IN_PROGRESS while work is active. Before the
final sprout land, set it CLOSED so the landed commit contains the closed task.

End every response with exactly one final line:

  AFK <STATUS> <task-id>

<STATUS> is one of:

  CONTINUE   useful durable progress was made, but another fresh context is useful
  FLOW_DONE  the branch is landed and the task is finished
  BLOCKED    a human decision or human: proof is required; add a short reason

Never invent a task ID. Never report FLOW_DONE while a sprout worktree/branch
for the task still exists.
EOF_PROTOCOL

if [[ -t 1 ]]; then OUT_TTY=1; else OUT_TTY=0; fi
if [[ -t 2 ]]; then ERR_TTY=1; else ERR_TTY=0; fi

C_RESET=$'\033[0m'
C_AFK=$'\033[1;36m'
C_SESSION=$'\033[1;35m'
C_PROMPT=$'\033[2m'
C_PHASE=$'\033[36m'
C_COMMIT=$'\033[32m'
C_LAND=$'\033[1;32m'
C_NEXT=$'\033[2m'
C_TOK_OK=$'\033[32m'
C_TOK_WARN=$'\033[33m'
C_TOK_HOT=$'\033[31m'
if [[ $OUT_TTY -eq 0 ]]; then
    C_RESET="" C_AFK="" C_SESSION="" C_PROMPT="" C_PHASE=""
    C_COMMIT="" C_LAND="" C_NEXT=""
    C_TOK_OK="" C_TOK_WARN="" C_TOK_HOT=""
fi

E_RESET=$'\033[0m'
E_ERROR=$'\033[1;31m'
if [[ $ERR_TTY -eq 0 ]]; then E_RESET="" E_ERROR=""; fi

TERM_COLS=80
if [[ $OUT_TTY -eq 1 ]]; then
    _cols=$(stty size < /dev/tty 2>/dev/null | cut -d' ' -f2)
    [[ $_cols =~ ^[0-9]+$ && $_cols -ge 20 ]] && TERM_COLS=$_cols
fi

SPIN_FRAMES=$'|/-\\'
SPIN_INDEX=0
SPIN_LIVE=0
SPIN_PHASE=""
SPIN_MSG=""
SESSION_TOKENS=""
CLAUDE_PID=""
KILL_REASON=""
RESULT_TEXT=""
BATCH_REMAINING=""

fmt_tokens() { printf '%d.%dK' $(($1 / 1000)) $((($1 % 1000) / 100)); }

tok_color() {
    if [[ $1 -lt 120000 ]]; then printf '%s' "$C_TOK_OK"
    elif [[ $1 -lt $AFK_SOFT_TOKENS ]]; then printf '%s' "$C_TOK_WARN"
    else printf '%s' "$C_TOK_HOT"
    fi
}

spin_clear() {
    [[ $SPIN_LIVE -eq 1 ]] || return 0
    SPIN_LIVE=0
    printf '\r\033[K\033[?7h'
}

say() { spin_clear; printf '%s\n' "$*"; }
err() { spin_clear; printf '%s\n' "$*" >&2; }
head_line() { say "$1$2$C_RESET  $3"; }
line() { say "$(printf '  %s%-7s%s %s' "$1" "$2" "$C_RESET" "$3")"; }

spin() {
    [[ $OUT_TTY -eq 1 ]] || return 0
    local frame text tok=""
    frame=${SPIN_FRAMES:$SPIN_INDEX:1}
    SPIN_INDEX=$(((SPIN_INDEX + 1) % ${#SPIN_FRAMES}))
    [[ -z $SESSION_TOKENS ]] || tok="$(fmt_tokens "$SESSION_TOKENS")  "
    text=$(printf '%s working  %s  %dm%02ds  %s%s' \
        "$frame" "$SPIN_PHASE" $(($1 / 60)) $(($1 % 60)) "$tok" "$SPIN_MSG")
    printf '\r\033[K\033[?7l%s\033[?7h' "${text:0:$((TERM_COLS - 1))}"
    SPIN_LIVE=1
}

report_tokens() {
    [[ -n $SESSION_TOKENS ]] || return 0
    spin_clear
    line "$(tok_color "$SESSION_TOKENS")" tokens "$(fmt_tokens "$SESSION_TOKENS")"
    SESSION_TOKENS=""
}

report_remaining() {
    [[ -n $BATCH_REMAINING ]] || return 0
    err "not started: $BATCH_REMAINING"
}

die() {
    err "${E_ERROR}error${E_RESET}  $*"
    report_remaining
    err "afk run failed"
    exit 1
}

main_worktree=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10); exit}')

# A task's active sprout worktree owns its in-flight artifacts. Otherwise main.
task_root() {
    local id=$1 line wt roots=()
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wt=${line#worktree }
                if [[ $(git -C "$wt" config --worktree --get sprout.task 2>/dev/null) == "$id" ]]; then
                    roots+=("$wt")
                fi
                ;;
        esac
    done < <(git -C "$main_worktree" worktree list --porcelain)
    case ${#roots[@]} in
        0) printf '%s\n' "$main_worktree" ;;
        1) printf '%s\n' "${roots[0]}" ;;
        *) err "multiple worktrees claim task $id: ${roots[*]}"; return 1 ;;
    esac
}

task_worktree() {
    local root
    root=$(task_root "$1") || return 1
    [[ $root == "$main_worktree" ]] && return 0
    printf '%s\n' "$root"
}

task_file() { printf '%s/tasks/%s/TASK.md\n' "$(task_root "$1")" "$1"; }

task_exists() { [[ -f $(task_file "$1") ]]; }

task_status() {
    local file
    file=$(task_file "$1") || return 1
    sed -n 's/^- STATUS: //p' "$file" | head -1
}

set_task_status() {
    local id=$1 status=$2 root
    root=$(task_root "$id") || die "cannot locate task $id"
    tatr -r "$root" edit "$id" --status "$status" >/dev/null ||
        die "cannot set $id status to $status"
}

feature_branch() {
    local wt
    wt=$(task_worktree "$1") || return 1
    [[ -n $wt ]] || return 0
    git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null
}

ref_head() { git -C "$main_worktree" rev-parse --verify --quiet "$1" 2>/dev/null; }

# Durable progress = task artifacts, git state, or worktree/branch changes.
fingerprint() {
    local id=$1 root wt branch
    root=$(task_root "$id") || return 1
    wt=$(task_worktree "$id")
    branch=$(feature_branch "$id")
    {
        printf 'status=%s\n' "$(task_status "$id")"
        printf 'root=%s\n' "$root"
        printf 'branch=%s\n' "$branch"
        [[ -d $root/tasks/$id ]] && find "$root/tasks/$id" -maxdepth 2 -type f -print0 2>/dev/null | sort -z | xargs -0r sha1sum
        printf 'main=%s\n' "$(ref_head HEAD)"
        [[ -n $branch ]] && printf 'feature=%s\n' "$(ref_head "refs/heads/$branch")"
        if [[ -n $wt ]]; then
            git -C "$wt" status --porcelain
            git -C "$wt" diff HEAD
        fi
    } | sha1sum | cut -d' ' -f1
}

report_state() {
    local id=$1 status branch
    status=$(task_status "$id")
    branch=$(feature_branch "$id")
    SPIN_PHASE=${status:-UNKNOWN}
    line "$C_PHASE" status "${status:-UNKNOWN}${branch:+  $branch}"
}

report_commits() {
    local id=$1 main_before=$2 feature_before=$3 after branch
    branch=$(feature_branch "$id")
    [[ -z $branch ]] || {
        after=$(ref_head "refs/heads/$branch")
        if [[ -n $after && $after != "$feature_before" ]]; then
            line "$C_COMMIT" commit "${after:0:7} $(git -C "$main_worktree" log -1 --format=%s "$after")"
        fi
    }
    after=$(ref_head HEAD)
    if [[ -n $after && $after != "$main_before" ]]; then
        line "$C_COMMIT" commit "${after:0:7} $(git -C "$main_worktree" log -1 --format=%s "$after")"
    fi
}

create_task() {
    local goal=$1 out id before after
    before=$(mktemp)
    after=$(mktemp)
    find "$main_worktree/tasks" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort >"$before"
    out=$(tatr -r "$main_worktree" new "$goal" 2>&1)
    [[ $? -eq 0 ]] || { rm -f "$before" "$after"; die "tatr new failed: $out"; }
    id=$(printf '%s\n' "$out" | grep -oE '[0-9]{8}-[0-9]{6}' | tail -1)
    if [[ -z $id ]]; then
        find "$main_worktree/tasks" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort >"$after"
        id=$(comm -13 "$before" "$after" | grep -E '^[0-9]{8}-[0-9]{6}$' | head -1)
        [[ $(comm -13 "$before" "$after" | grep -Ec '^[0-9]{8}-[0-9]{6}$') -eq 1 ]] || id=""
    fi
    rm -f "$before" "$after"
    [[ -n $id ]] || die "tatr created a task but afk could not identify its ID"
    printf '%s\n' "$id"
}

on_signal() {
    trap - INT TERM
    local rc=130
    if [[ -n $CLAUDE_PID ]] && kill -0 "$CLAUDE_PID" 2>/dev/null; then
        kill "$CLAUDE_PID" 2>/dev/null
        wait "$CLAUDE_PID" 2>/dev/null
        rc=$?
    fi
    err "${E_ERROR}interrupted${E_RESET}  resumable with 'afk run <task-id>'"
    report_remaining
    [[ $rc -ne 0 ]] || rc=130
    exit "$rc"
}

stop_claude() {
    exec {sfd}<&-
    kill -"$1" "$CLAUDE_PID" 2>/dev/null
    wait "$CLAUDE_PID" 2>/dev/null
    CLAUDE_PID=""
    rm -rf "$dir"
    report_tokens
}

run_claude() {
    local uuid=$1 prompt=$2
    KILL_REASON=""
    RESULT_TEXT=""
    local args=(
        -p
        --output-format stream-json
        --verbose
        --dangerously-skip-permissions
        --disallowed-tools AskUserQuestion
        --append-system-prompt "$PROTOCOL"
        --session-id "$uuid"
        "$prompt"
    )
    local dir fifo event typ text used result="" rc sfd partial="" started last_event
    local soft_armed=0 pending_tools=0 drained
    dir=$(mktemp -d) || die "cannot create temporary directory"
    fifo="$dir/stream"
    mkfifo "$fifo" || die "cannot create event pipe"

    set -m
    claude "${args[@]}" >"$fifo" 2>"$dir/err" &
    CLAUDE_PID=$!
    set +m
    exec {sfd}<"$fifo"

    started=$SECONDS
    last_event=$SECONDS
    SPIN_MSG=""
    SESSION_TOKENS=""
    while true; do
        IFS= read -r -t 0.2 -u "$sfd" event
        rc=$?
        if [[ $rc -gt 128 ]]; then
            if [[ -n $event ]]; then partial+=$event; last_event=$SECONDS; fi
            if [[ $((SECONDS - last_event)) -ge $AFK_HEARTBEAT_SECS ]]; then
                stop_claude TERM
                die "claude produced no output for ${AFK_HEARTBEAT_SECS}s; session killed"
            fi
            spin $((SECONDS - started))
            continue
        fi

        last_event=$SECONDS
        event="$partial$event"
        partial=""
        if [[ -n $event ]]; then
            typ=$(printf '%s' "$event" | jq -r 'try .type catch empty' 2>/dev/null)
            case "$typ" in
                result) result=$event ;;
                assistant)
                    used=$(printf '%s' "$event" | jq -r 'try (if .message.usage then (.message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0) + (.output_tokens // 0)) else empty end) catch empty' 2>/dev/null)
                    if [[ $used =~ ^[0-9]+$ ]]; then
                        SESSION_TOKENS=$used
                        if [[ $SESSION_TOKENS -ge $AFK_HARD_TOKENS ]]; then
                            KILL_REASON="hard context limit crossed at $(fmt_tokens "$SESSION_TOKENS")"
                            stop_claude INT
                            return 0
                        elif [[ $SESSION_TOKENS -ge $AFK_SOFT_TOKENS ]]; then
                            soft_armed=1
                        fi
                    fi
                    drained=$(printf '%s' "$event" | jq -r 'try ([.message.content[]? | select(.type=="tool_use")] | length) catch 0' 2>/dev/null)
                    [[ $drained =~ ^[0-9]+$ ]] && pending_tools=$((pending_tools + drained))
                    text=$(printf '%s' "$event" | jq -r 'try ([.message.content[]? | select(.type=="text") | .text] | join("\n")) catch empty')
                    if [[ -n $text ]]; then
                        SPIN_MSG=$(printf '%s' "$text" | tr '\n\t\r\033' '    ' | tr -s ' ')
                        if [[ ${AFK_VERBOSE:-0} == 1 ]]; then spin_clear; printf '%s\n' "$text" | sed 's/^/| /'; fi
                    fi
                    ;;
                user)
                    drained=$(printf '%s' "$event" | jq -r 'try ([.message.content[]? | select(.type=="tool_result")] | length) catch 0' 2>/dev/null)
                    if [[ $drained =~ ^[0-9]+$ && $drained -gt 0 ]]; then
                        pending_tools=$((pending_tools - drained))
                        [[ $pending_tools -ge 0 ]] || pending_tools=0
                        if [[ $soft_armed -eq 1 && $pending_tools -eq 0 ]]; then
                            KILL_REASON="soft context limit crossed at $(fmt_tokens "$SESSION_TOKENS")"
                            stop_claude TERM
                            return 0
                        fi
                    fi
                    ;;
            esac
        fi
        [[ $rc -eq 0 ]] || break
    done

    exec {sfd}<&-
    spin_clear
    wait "$CLAUDE_PID"; rc=$?
    CLAUDE_PID=""
    report_tokens
    if [[ $rc -ne 0 ]]; then
        err "$(tail -5 "$dir/err" 2>/dev/null)"
        rm -rf "$dir"
        die "claude exited with status $rc"
    fi
    rm -rf "$dir"
    [[ -n $result ]] || die "claude ended without terminal result event"
    if [[ $(printf '%s' "$result" | jq -r 'try .is_error catch "true"') == true ]]; then
        die "claude reported an error: $(printf '%s' "$result" | jq -r 'try (.result // .error // "unknown") catch "unknown"')"
    fi
    RESULT_TEXT=$(printf '%s' "$result" | jq -r 'try (.result // "") catch ""')
}

parse_marker() {
    local marker
    marker=$(printf '%s\n' "$RESULT_TEXT" | grep -E '^AFK (CONTINUE|FLOW_DONE|BLOCKED) [0-9]{8}-[0-9]{6}([[:space:]].*)?$' | tail -1)
    [[ -n $marker ]] || return 1
    read -r _ MARKER_STATUS MARKER_ID MARKER_REASON <<<"$marker"
}

require_progress() {
    local id=$1 fp
    fp=$(fingerprint "$id") || die "cannot fingerprint $id"
    [[ -z $prev_fp || $fp != "$prev_fp" ]] || die "no durable progress across two consecutive sessions"
    prev_fp=$fp
}

run_item() {
    local input=$1 goal="" id="" session=0 prev_fp="" prompt
    local main_before feature_before branch status item_started=$SECONDS

    if [[ $input =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
        id=$input
        task_exists "$id" || die "no task $id"
        head_line "$C_AFK" task "$id"
    else
        goal=$input
        head_line "$C_AFK" goal "$goal"
        id=$(create_task "$goal")
        line "$C_PHASE" task "$id created"
    fi

    status=$(task_status "$id")
    case "$status" in
        OPEN) set_task_status "$id" IN_PROGRESS ;;
        IN_PROGRESS) ;;
        CLOSED)
            [[ -z $(task_worktree "$id") ]] || die "$id is CLOSED but still has a worktree"
            line "$C_LAND" done "$id already CLOSED"
            ITEM_SESSIONS=0
            return 0
            ;;
        *) die "$id has invalid or missing STATUS '$status'" ;;
    esac

    prev_fp=$(fingerprint "$id")
    while true; do
        session=$((session + 1))
        [[ $session -le $AFK_MAX_SESSIONS ]] || die "reached AFK_MAX_SESSIONS=$AFK_MAX_SESSIONS"

        SESSION_UUID=$(uuidgen)
        say ""
        head_line "$C_SESSION" "session $session" "$SESSION_UUID"
        report_state "$id"
        prompt="/flow $id"
        line "$C_PROMPT" prompt "$prompt"

        main_before=$(ref_head HEAD)
        branch=$(feature_branch "$id")
        feature_before=""
        [[ -z $branch ]] || feature_before=$(ref_head "refs/heads/$branch")

        run_claude "$SESSION_UUID" "$prompt"
        report_state "$id"
        report_commits "$id" "$main_before" "$feature_before"

        if [[ -n $KILL_REASON ]]; then
            require_progress "$id"
            line "$C_NEXT" next "$KILL_REASON; rotating to fresh context"
            continue
        fi

        parse_marker || die "session ended without AFK marker; last line: $(printf '%s\n' "$RESULT_TEXT" | tail -1)"
        [[ $MARKER_ID == "$id" ]] || die "session reported task $MARKER_ID, expected $id"

        case "$MARKER_STATUS" in
            CONTINUE)
                require_progress "$id"
                line "$C_NEXT" next "rotating to fresh context"
                ;;
            BLOCKED)
                die "flow blocked: ${MARKER_REASON:-human input required}"
                ;;
            FLOW_DONE)
                [[ -z $(task_worktree "$id") ]] || die "FLOW_DONE but task $id still has a worktree"
                [[ $(task_status "$id") == CLOSED ]] || die "FLOW_DONE but task $id is not CLOSED"
                break
                ;;
        esac
    done

    local elapsed=$((SECONDS - item_started))
    say ""
    head_line "$C_LAND" done "$id landed"
    say "$(printf '      %d sessions, %dm%02ds' "$session" $((elapsed / 60)) $((elapsed % 60)))"
    ITEM_SESSIONS=$session
}

cmd_run() {
    [[ $# -ge 1 ]] || die "run takes at least one goal or task ID"
    [[ -n $main_worktree ]] || die "not inside a git repository"
    cd "$main_worktree" || die "cannot enter $main_worktree"

    local arg
    for arg in "$@"; do [[ -n $arg ]] || die "empty run argument"; done
    for arg in "$@"; do
        [[ $arg =~ ^[0-9]{8}-[0-9]{6}$ ]] || continue
        task_exists "$arg" || die "no task $arg"
    done

    head_line "$C_AFK" afk "unattended flow runner"
    head_line "$C_AFK" repo "$main_worktree"

    local total=$# index=0 sessions=0 started=$SECONDS
    for arg in "$@"; do
        index=$((index + 1))
        BATCH_REMAINING="${*:index+1}"
        run_item "$arg"
        sessions=$((sessions + ITEM_SESSIONS))
    done
    BATCH_REMAINING=""

    [[ $total -gt 1 ]] || return 0
    local elapsed=$((SECONDS - started))
    say ""
    head_line "$C_LAND" batch "$total tasks completed"
    say "$(printf '      %d sessions, %dm%02ds' "$sessions" $((elapsed / 60)) $((elapsed % 60)))"
}

AFK_HEARTBEAT_SECS=${AFK_HEARTBEAT_SECS:-900}
AFK_SOFT_TOKENS=${AFK_SOFT_TOKENS:-180000}
AFK_HARD_TOKENS=${AFK_HARD_TOKENS:-200000}
AFK_MAX_SESSIONS=${AFK_MAX_SESSIONS:-40}
trap on_signal INT TERM

cmd=${1:-}
[[ $# -eq 0 ]] || shift
case "$cmd" in
    run) cmd_run "$@" ;;
    help|-h|--help) usage ;;
    "") usage ;;
    *) err "afk: unknown command '$cmd'"; usage >&2; exit 1 ;;
esac
