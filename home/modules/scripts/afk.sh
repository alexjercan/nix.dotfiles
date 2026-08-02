#!/usr/bin/env bash
# afk - drive this repository's /flow skill unattended through headless Claude
# Code sessions.
#
# The problem afk solves is not reasoning, it is the human loop: /flow already
# reconstructs its whole state from tasks/, git and the sprout worktrees at
# every phase, so a long run is mostly a person re-typing /clear then
# /flow <id> and answering three fixed approval gates. afk supervises
# DISPOSABLE Claude sessions instead: every ordinary continuation is a brand
# new session (that is the /clear equivalent), and --resume is used only to
# complete one approval transaction.
#
# Authority stays with tatr and git. The `AFK <STATUS> <id>` marker injected
# through --append-system-prompt is a routing HINT; every route it selects is
# cross-checked against durable state, and any disagreement stops the run.
#
# This file is the whole implementation; afk.nix wraps it with
# pkgs.writeShellApplication, which prepends its own strict-mode prologue
# (relaxed right below). Keeping the script in a plain file makes it directly
# testable:
#   bash home/modules/scripts/afk-test.sh

set +o errexit
set +o pipefail
set +o nounset

usage() {
    echo "Usage: afk <COMMAND> [ARGS]"
    echo "Run the /flow skill unattended through headless Claude Code sessions."
    echo
    echo "Commands:"
    echo "  run <goal|task-id>"
    echo "                   Drive one goal, or one existing task, from its"
    echo "                   current flow step through to a landed commit,"
    echo "                   auto-approving the standard flow gates"
    echo "  help             Show this help message"
    echo
    echo "Starting a run IS the approval for the plan, review and landing"
    echo "gates. Everything else - a spike, a blocked flow, a marker that"
    echo "disagrees with tatr or git - stops the run non-zero, leaving the task"
    echo "and its worktree ready for 'afk run <task-id>'."
    echo
    echo "Environment:"
    echo "  AFK_HEARTBEAT_SECS  Stall timeout between stream events (default 900)"
    echo "  AFK_MAX_SESSIONS    Maximum fresh Claude sessions (default 40)"
    echo "  AFK_VERBOSE         Set to 1 to echo Claude's assistant text"
}

# The protocol injected into every session. It is deliberately small: the only
# thing afk needs out of a session that git and tatr cannot tell it is WHY the
# turn ended.
read -r -d '' PROTOCOL << 'EOF'
AFK RUNNER PROTOCOL

You are running unattended under the afk runner. There is no interactive user
and no way to ask one a question; the AskUserQuestion tool is disabled. When
the flow reaches an approval gate, summarize the phase, ask its question, and
end the turn - the runner answers it.

End every response with exactly one final line of this form, and nothing after
it:

  AFK <STATUS> <task-id>

<STATUS> is one of:

  PLAN_READY  the plan gate is pending
  WORK_DONE   the review gate is pending
  LAND_READY  the landing gate is pending
  ROTATE      the flow asked for /clear then /flow <id>, or the phase advanced
              and needs a fresh context
  DONE        the branch is landed and the goal is finished
  BLOCKED     the flow must stop for a human decision; add a one-line reason

Never invent a task ID; use the one the flow is working on.
EOF

say() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }

die() {
    err "ERROR $*"
    err "AFK RUN FAILED"
    exit 1
}

# Resolve the project from the MAIN worktree so afk behaves the same whether it
# is run from the main checkout or from inside one of its worktrees. The first
# entry of 'git worktree list' is always the main worktree. Flow itself must
# run from the main checkout: it discovers the task's worktree by itself.
main_worktree=$(git worktree list --porcelain 2> /dev/null | awk '/^worktree /{print substr($0, 10); exit}')

# ------------------------------------------------------------ durable state --

task_root() {
    # $1: task ID -> the checkout whose tasks/ dir is authoritative for it.
    # A sprout worktree associated with the task owns the records while the
    # task is in flight; the main checkout's copy is stale until it lands.
    # Two matches are ambiguous state, not something to guess at.
    local line wt roots=()
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wt=${line#worktree }
                if [[ $(git -C "$wt" config --worktree --get sprout.task 2> /dev/null) == "$1" ]]; then
                    roots+=("$wt")
                fi
                ;;
        esac
    done < <(git -C "$main_worktree" worktree list --porcelain)

    case ${#roots[@]} in
        0) printf '%s\n' "$main_worktree" ;;
        1) printf '%s\n' "${roots[0]}" ;;
        *)
            err "ERROR ${#roots[@]} worktrees claim task $1: ${roots[*]}"
            return 1
            ;;
    esac
}

task_worktree() {
    # $1: task ID -> its sprout worktree path, or empty if it has none.
    local root
    root=$(task_root "$1") || return 1
    [[ $root == "$main_worktree" ]] && return 0
    printf '%s\n' "$root"
}

flow_step() {
    # $1: task ID -> its FLOW STEP, read from the authoritative record.
    local root
    root=$(task_root "$1") || return 1
    tatr -r "$root" show "$1" 2> /dev/null | sed -n 's/^- FLOW STEP: //p' | head -1
}

feature_branch() {
    # $1: task ID -> the branch checked out in its worktree, or empty.
    local wt
    wt=$(task_worktree "$1") || return 1
    [[ -n $wt ]] || return 0
    git -C "$wt" symbolic-ref --quiet --short HEAD 2> /dev/null
}

ref_head() {
    # $1: ref -> its commit, or empty when the ref does not exist.
    git -C "$main_worktree" rev-parse --verify --quiet "$1" 2> /dev/null
}

fingerprint() {
    # $1: task ID -> a hash of everything a productive session must change.
    # A session that leaves all of it identical made no durable progress, no
    # matter what its prose claimed.
    local id=$1 wt root verdict
    root=$(task_root "$id") || return 1
    wt=$(task_worktree "$id")
    verdict=$(sed -n 's/^- VERDICT: //p' "$root/tasks/$id/REVIEW.md" 2> /dev/null | tail -1)
    {
        printf '%s\n' "$(flow_step "$id")"
        printf '%s\n' "$(ref_head HEAD)"
        printf '%s\n' "$(ref_head "refs/heads/$(feature_branch "$id")")"
        printf '%s\n' "$verdict"
        if [[ -n $wt ]]; then
            git -C "$wt" status --porcelain
            git -C "$wt" diff HEAD
        fi
    } | sha1sum | cut -d' ' -f1
}

# ------------------------------------------------------------ claude driver --

CLAUDE_PID=""

on_signal() {
    # Kill ONLY the claude process this runner started - never the process
    # group, which would take out unrelated work sharing the terminal - and
    # exit with its status. Everything afk cares about is already on disk, so
    # the interrupted run stays resumable with 'afk run <task-id>'.
    trap - INT TERM
    local rc=130
    if [[ -n $CLAUDE_PID ]] && kill -0 "$CLAUDE_PID" 2> /dev/null; then
        kill "$CLAUDE_PID" 2> /dev/null
        wait "$CLAUDE_PID" 2> /dev/null
        rc=$?
    fi
    err "AFK RUN INTERRUPTED"
    [[ $rc -ne 0 ]] || rc=130
    exit "$rc"
}

run_claude() {
    # $1: 'fresh' or 'resume'  $2: session UUID  $3: prompt.
    # Streams the session, enforcing the heartbeat, and leaves the terminal
    # result's text in RESULT_TEXT.
    local mode=$1 uuid=$2 prompt=$3
    local args=(
        -p
        --output-format stream-json
        --verbose
        --dangerously-skip-permissions
        --disallowed-tools AskUserQuestion
        --append-system-prompt "$PROTOCOL"
    )
    if [[ $mode == resume ]]; then
        args+=(--resume "$uuid")
    else
        args+=(--session-id "$uuid")
    fi
    args+=("$prompt")

    local dir fifo line typ text result="" rc sfd
    dir=$(mktemp -d) || die "cannot create a temporary directory"
    fifo="$dir/stream"
    mkfifo "$fifo" || die "cannot create the event pipe"

    claude "${args[@]}" > "$fifo" 2> "$dir/err" &
    CLAUDE_PID=$!
    exec {sfd}< "$fifo"

    # read -t returns >128 on timeout and 1 on EOF, which is the whole reason
    # there is no wall-clock cap: a long, productive turn keeps emitting events
    # and only a genuinely silent one is killed.
    while true; do
        # '!' would reset $?, so the read status is captured on its own line:
        # >128 is the heartbeat timeout, 1 is a clean end of stream.
        IFS= read -r -t "$AFK_HEARTBEAT_SECS" -u "$sfd" line
        rc=$?
        if [[ $rc -gt 128 ]]; then
            exec {sfd}<&-
            kill "$CLAUDE_PID" 2> /dev/null
            wait "$CLAUDE_PID" 2> /dev/null
            CLAUDE_PID=""
            rm -rf "$dir"
            die "claude produced no output for ${AFK_HEARTBEAT_SECS}s; session killed"
        fi
        # A final line without its newline still arrives, with status 1.
        if [[ -n $line ]]; then
            typ=$(printf '%s' "$line" | jq -r 'try .type catch empty' 2> /dev/null)
            case "$typ" in
                result) result=$line ;;
                assistant)
                    if [[ ${AFK_VERBOSE:-0} == 1 ]]; then
                        text=$(printf '%s' "$line" | jq -r 'try ([.message.content[]? | select(.type=="text") | .text] | join("\n")) catch empty')
                        [[ -z $text ]] || printf '%s\n' "$text" | sed 's/^/| /'
                    fi
                    ;;
            esac
        fi
        [[ $rc -eq 0 ]] || break
    done

    exec {sfd}<&-
    wait "$CLAUDE_PID"
    rc=$?
    CLAUDE_PID=""

    if [[ $rc -ne 0 ]]; then
        err "$(tail -5 "$dir/err" 2> /dev/null)"
        rm -rf "$dir"
        die "claude exited with status $rc"
    fi
    rm -rf "$dir"

    [[ -n $result ]] || die "claude ended without a terminal result event"

    # A rate limit comes back as subtype "success" with is_error true, so the
    # error test is is_error plus the exit status, never the subtype.
    if [[ $(printf '%s' "$result" | jq -r 'try .is_error catch "true"') == true ]]; then
        die "claude reported an error result: $(printf '%s' "$result" | jq -r 'try (.result // .error // "unknown") catch "unknown"')"
    fi

    RESULT_TEXT=$(printf '%s' "$result" | jq -r 'try (.result // "") catch ""')
}

parse_marker() {
    # Reads RESULT_TEXT; sets MARKER_STATUS, MARKER_ID and MARKER_REASON.
    local marker
    marker=$(printf '%s\n' "$RESULT_TEXT" |
        grep -E '^AFK [A-Z_]+ [0-9]{8}-[0-9]{6}([[:space:]].*)?$' | tail -1)
    if [[ -z $marker ]]; then
        MARKER_STATUS=""
        MARKER_ID=""
        MARKER_REASON=""
        return 1
    fi
    read -r _ MARKER_STATUS MARKER_ID MARKER_REASON <<< "$marker"
    return 0
}

# ------------------------------------------------------------------ run cmd --

report_commits() {
    # $1: task ID  $2: main HEAD before  $3: feature HEAD before.
    # Commits are reported from git, not from what the session said it did.
    local after
    after=$(ref_head "refs/heads/$(feature_branch "$1")")
    if [[ -n $after && $after != "$3" ]]; then
        say "COMMIT ${after:0:7} $(git -C "$main_worktree" log -1 --format=%s "$after")"
    fi
    after=$(ref_head HEAD)
    if [[ -n $after && $after != "$2" ]]; then
        say "COMMIT ${after:0:7} $(git -C "$main_worktree" log -1 --format=%s "$after")"
    fi
}

require_step() {
    # $1: task ID  $2: expected FLOW STEP  $3: what claimed it.
    local actual
    actual=$(flow_step "$1") || die "cannot read the flow state of $1"
    [[ $actual == "$2" ]] ||
        die "$3 but $1 is in $actual, not $2"
}

gate() {
    # $1: task ID  $2: marker status  $3: the exact gates.md approve label.
    # One resume, one label. The session is disposable afterwards either way.
    say ""
    say "RESUME CLAUDE SESSION $SESSION_UUID"
    say "AUTO_APPROVE $2"
    run_claude resume "$SESSION_UUID" "$3"
    if parse_marker && [[ $MARKER_ID != "$1" ]]; then
        die "the $2 gate answered for task $MARKER_ID, not $1"
    fi
}

lifecycle_gate() {
    # $1: marker status  $2: the FLOW STEP the gate is only legal from
    # $3: the exact gates.md approve label  $4: the FLOW STEP it must produce.
    # Both ends are checked against tatr: a gate afk cannot see land in the
    # record is a gate afk must not build on.
    local before_main before_feat
    require_step "$TASK_ID" "$2" "the session reported $1"
    before_main=$(ref_head HEAD)
    before_feat=$(ref_head "refs/heads/$(feature_branch "$TASK_ID")")
    gate "$TASK_ID" "$1" "$3"
    require_step "$TASK_ID" "$4" "the $1 gate was approved"
    say "FLOW $(flow_step "$TASK_ID")"
    report_commits "$TASK_ID" "$before_main" "$before_feat"
}

cmd_run() {
    [[ $# -eq 1 && -n ${1:-} ]] ||
        die "run takes exactly one argument: a goal string or a task ID"
    [[ -n $main_worktree ]] || die "not inside a git repository"

    local input=$1 goal="" prompt
    TASK_ID=""
    if [[ $input =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
        TASK_ID=$input
    else
        goal=$input
    fi

    cd "$main_worktree" || die "cannot enter $main_worktree"

    say "AFK RUN START"
    say "REPO $main_worktree"
    if [[ -n $TASK_ID ]]; then
        [[ -n $(flow_step "$TASK_ID") ]] || die "no task $TASK_ID in $main_worktree/tasks"
        say "TASK $TASK_ID"
    else
        say "GOAL $goal"
    fi

    local session=0 prev_fp="" fp main_before feat_before branch landed
    while true; do
        session=$((session + 1))
        if [[ $session -gt ${AFK_MAX_SESSIONS} ]]; then
            die "reached AFK_MAX_SESSIONS=${AFK_MAX_SESSIONS} without finishing"
        fi

        SESSION_UUID=$(uuidgen)
        say ""
        say "CREATE CLAUDE SESSION $SESSION_UUID"
        if [[ -n $TASK_ID ]]; then
            prompt="/flow $TASK_ID"
        else
            prompt="/flow \"$goal\""
        fi
        say "RUN $prompt"

        main_before=$(ref_head HEAD)
        feat_before=$(ref_head "refs/heads/$(feature_branch "${TASK_ID:-none}")")
        run_claude fresh "$SESSION_UUID" "$prompt"

        parse_marker ||
            die "the session ended with no AFK control marker; last line: $(printf '%s\n' "$RESULT_TEXT" | tail -1)"
        if [[ -z $TASK_ID ]]; then
            TASK_ID=$MARKER_ID
            [[ -n $(flow_step "$TASK_ID") ]] ||
                die "the session reported task $TASK_ID, but no such record exists"
            say "TASK CREATED $TASK_ID"
        elif [[ $MARKER_ID != "$TASK_ID" ]]; then
            die "the session reported task $MARKER_ID, not $TASK_ID"
        fi

        say "FLOW $(flow_step "$TASK_ID")"
        report_commits "$TASK_ID" "$main_before" "$feat_before"
        say "$MARKER_STATUS $TASK_ID"

        case "$MARKER_STATUS" in
            ROTATE)
                fp=$(fingerprint "$TASK_ID") || die "cannot fingerprint $TASK_ID"
                if [[ -n $prev_fp && $fp == "$prev_fp" ]]; then
                    die "no durable progress across two consecutive sessions"
                fi
                prev_fp=$fp
                ;;
            PLAN_READY)
                lifecycle_gate PLAN_READY PLANNING "Approve plan - move to PLANNED" PLANNED
                prev_fp=""
                ;;
            WORK_DONE)
                lifecycle_gate WORK_DONE WORKING "Approve review - move to REVIEWING" REVIEWING
                prev_fp=""
                ;;
            LAND_READY)
                require_step "$TASK_ID" DONE "the session reported LAND_READY"
                branch=$(feature_branch "$TASK_ID")
                [[ -n $branch ]] ||
                    die "$TASK_ID has no sprout worktree, so there is no branch to land"
                main_before=$(ref_head HEAD)
                gate "$TASK_ID" LAND_READY "Approve landing - land the branch"
                landed=$(ref_head HEAD)
                [[ $landed != "$main_before" ]] ||
                    die "the landing gate was approved but $branch produced no commit on $(git -C "$main_worktree" symbolic-ref --quiet --short HEAD)"
                ! git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch" ||
                    die "the landing gate was approved but branch $branch still exists"
                say "LAND COMMIT ${landed:0:7} $(git -C "$main_worktree" log -1 --format=%s)"
                say "WORKTREE REMOVED $branch"
                break
                ;;
            DONE)
                branch=$(feature_branch "$TASK_ID")
                [[ -z $branch ]] ||
                    die "the session reported DONE but branch $branch is not landed"
                break
                ;;
            BLOCKED)
                die "the flow is blocked: ${MARKER_REASON:-no reason given}"
                ;;
            SPIKED)
                # A spike answers what to build and seeds new tasks; which of
                # them to run, and in what order, is the user's call.
                die "the flow spiked $TASK_ID; pick one of the tasks it seeded and run afk on that"
                ;;
            *)
                die "unknown control status '$MARKER_STATUS'"
                ;;
        esac

        say ""
        say "CLOSE CLAUDE SESSION $SESSION_UUID"
    done

    say ""
    say "GOAL DONE $TASK_ID"
    say "CLAUDE SESSIONS $session"
    printf 'ELAPSED %dm%02ds\n' $((SECONDS / 60)) $((SECONDS % 60))
    say "AFK RUN COMPLETE"
}

AFK_HEARTBEAT_SECS=${AFK_HEARTBEAT_SECS:-900}
AFK_MAX_SESSIONS=${AFK_MAX_SESSIONS:-40}
trap on_signal INT TERM

cmd=${1:-}
if [[ $# -gt 0 ]]; then
    shift
fi

case "$cmd" in
    run) cmd_run "$@" ;;
    help | -h | --help) usage ;;
    "") usage ;;
    *)
        err "afk: unknown command '$cmd'"
        usage >&2
        exit 1
        ;;
esac
