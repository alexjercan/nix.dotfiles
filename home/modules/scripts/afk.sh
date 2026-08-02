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
# cross-checked against durable state - the task's ACTIVITY, its earned GATES
# and its RESOLUTION, plus git - and any disagreement stops the run.
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
    echo "  run <goal|task-id>..."
    echo "                   Drive each goal, or each existing task, from its"
    echo "                   current activity through to a landed commit,"
    echo "                   auto-approving the standard flow gates. Several"
    echo "                   arguments run sequentially, in the order given;"
    echo "                   the batch stops at the first one that fails and"
    echo "                   names the arguments it never started"
    echo "  help             Show this help message"
    echo
    echo "Starting a run IS the approval for the plan, review and landing"
    echo "gates. Everything else - a spike, a blocked flow, a marker that"
    echo "disagrees with tatr or git - stops the run non-zero, leaving the task"
    echo "and its worktree ready for 'afk run <task-id>'."
    echo
    echo "Environment:"
    echo "  AFK_HEARTBEAT_SECS  Stall timeout between stream events (default 900)"
    echo "  AFK_SOFT_TOKENS     Context size that arms a rotation, taken at the"
    echo "                      next completed tool call (default 180000)"
    echo "  AFK_HARD_TOKENS     Context size that rotates immediately, without"
    echo "                      waiting for a boundary (default 200000)"
    echo "  AFK_MAX_SESSIONS    Maximum fresh Claude sessions per item, not per"
    echo "                      run (default 40)"
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
  SPIKED      the flow answered a fuzzy question and seeded new tasks; the run
              stops here, and a human picks which seeded task to run next
  ROTATE      the flow asked for /clear then /flow <id>, or the phase advanced
              and needs a fresh context
  DONE        the branch is landed and the goal is finished
  BLOCKED     the flow must stop for a human decision; add a one-line reason

Never invent a task ID; use the one the flow is working on.
EOF

# ------------------------------------------------------------- presentation --
#
# One content stream, decoration gated on the terminal. Every permanent line is
# byte-identical whether or not stdout is a TTY; exactly two things are gated,
# the color constants (empty strings otherwise) and the transient spinner line
# (a no-op otherwise). That includes the `tokens` line: its VALUE is content -
# and load-bearing content, since the same count drives the rotation limits in
# the driver below - only its band color is gated, and the spinner's copy stays
# uncolored because the spinner is a bounded, truncated write and a halved
# escape sequence would bleed into the terminal. The spinner is written with
# autowrap disabled, so it always occupies exactly one row and `spin_clear`
# always erases all of it; the truncation is only a bound on the write.
# afk's PRINTED vocabulary is not its MARKER vocabulary:
# the `AFK <STATUS> <id>` protocol below is a contract with the model and does
# not follow this file's labels.

if [[ -t 1 ]]; then OUT_TTY=1; else OUT_TTY=0; fi
if [[ -t 2 ]]; then ERR_TTY=1; else ERR_TTY=0; fi

C_RESET=$'\033[0m'
C_AFK=$'\033[1;36m'
C_SESSION=$'\033[1;35m'
C_PROMPT=$'\033[2m'
C_PHASE=$'\033[36m'
C_COMMIT=$'\033[32m'
C_GATE=$'\033[33m'
C_LAND=$'\033[1;32m'
C_NEXT=$'\033[2m'
C_TOK_OK=$'\033[32m'
C_TOK_WARN=$'\033[33m'
C_TOK_HOT=$'\033[31m'
if [[ $OUT_TTY -eq 0 ]]; then
    C_RESET="" C_AFK="" C_SESSION="" C_PROMPT="" C_PHASE=""
    C_COMMIT="" C_GATE="" C_LAND="" C_NEXT=""
    C_TOK_OK="" C_TOK_WARN="" C_TOK_HOT=""
fi

E_RESET=$'\033[0m'
E_ERROR=$'\033[1;31m'
if [[ $ERR_TTY -eq 0 ]]; then
    E_RESET="" E_ERROR=""
fi

# Read once: a run that is resized mid-flight only mis-truncates a transient
# line. stdin is not necessarily the terminal, so ask /dev/tty for the size.
TERM_COLS=80
if [[ $OUT_TTY -eq 1 ]]; then
    # A pty with no size set reports 0; anything implausibly narrow would
    # truncate the spinner to nothing, so keep the fallback instead.
    _cols=$(stty size < /dev/tty 2> /dev/null | cut -d' ' -f2)
    [[ $_cols =~ ^[0-9]+$ && $_cols -ge 20 ]] && TERM_COLS=$_cols
fi

SPIN_FRAMES=$'|/-\\'
SPIN_INDEX=0
SPIN_LIVE=0
SPIN_PHASE=""
SPIN_MSG=""

# The context size of the claude invocation in flight, empty until one of its
# assistant events carries usage.
SESSION_TOKENS=""

fmt_tokens() {
    # $1: a token count -> '57.6K'. Truncated, never rounded: a count must not
    # be displayed above a threshold it has not actually crossed.
    printf '%d.%dK' $(($1 / 1000)) $((($1 % 1000) / 100))
}

tok_color() {
    # $1: a token count -> its band color. The hot band IS the soft limit, so
    # red never means "getting close": it means this session is being rotated.
    if [[ $1 -lt 120000 ]]; then
        printf '%s' "$C_TOK_OK"
    elif [[ $1 -lt $AFK_SOFT_TOKENS ]]; then
        printf '%s' "$C_TOK_WARN"
    else
        printf '%s' "$C_TOK_HOT"
    fi
}

report_tokens() {
    # Print the count for the claude invocation in flight, once, and forget it.
    # Every exit from run_claude passes through here, including the ones that
    # die: a session that stalled or blew up is exactly the one whose context
    # size is worth seeing. A session killed before its first assistant event
    # has no count at all, and a missing cosmetic field must not add a line
    # claiming zero.
    [[ -n $SESSION_TOKENS ]] || return 0
    spin_clear
    line "$(tok_color "$SESSION_TOKENS")" tokens "$(fmt_tokens "$SESSION_TOKENS")"
    SESSION_TOKENS=""
}

spin_clear() {
    # Erase a live spinner so no permanent line is ever printed on top of it.
    # Every erase also restores autowrap, so no exit path - including the
    # interrupt handler, which reaches here through `err` - can leave the
    # terminal with wrapping off.
    [[ $SPIN_LIVE -eq 1 ]] || return 0
    SPIN_LIVE=0
    printf '\r\033[K\033[?7h'
}

spin() {
    # $1: seconds since the session started. Transient and TTY-only: never
    # content, so nothing downstream may depend on it.
    [[ $OUT_TTY -eq 1 ]] || return 0
    local frame text tok=""
    frame=${SPIN_FRAMES:$SPIN_INDEX:1}
    SPIN_INDEX=$(((SPIN_INDEX + 1) % ${#SPIN_FRAMES}))
    [[ -z $SESSION_TOKENS ]] || tok="$(fmt_tokens "$SESSION_TOKENS")  "
    text=$(printf '%s working  %s  %dm%02ds  %s%s' \
        "$frame" "$SPIN_PHASE" $(($1 / 60)) $(($1 % 60)) "$tok" "$SPIN_MSG")
    # Autowrap off (DECAWM) for the write, on again straight after: a frame
    # wider than the terminal is CLIPPED at the right margin instead of
    # continuing on the next row, so the frame always occupies exactly one row
    # and `spin_clear`'s single-row erase always erases all of it. The
    # truncation is only a bound on the write, not the wrap guard - it counts
    # characters, which is not display columns. One printf, hence one write, so
    # no signal can land between disabling and restoring autowrap.
    printf '\r\033[K\033[?7l%s\033[?7h' "${text:0:$((TERM_COLS - 1))}"
    SPIN_LIVE=1
}

say() {
    spin_clear
    printf '%s\n' "$*"
}

err() {
    spin_clear
    printf '%s\n' "$*" >&2
}

head_line() {
    # $1: color  $2: label  $3: text. Run-level, flush left.
    say "$1$2$C_RESET  $3"
}

line() {
    # $1: color  $2: label  $3: text. Indented under the current session, with
    # the label padded so every text column lines up.
    say "$(printf '  %s%-7s%s %s' "$1" "$2" "$C_RESET" "$3")"
}

phase_gloss() {
    # $1: a phase_label -> a short human phrase, empty for an unknown label.
    # Keyed off the activity part alone, so the appended gates do not have to
    # be enumerated here.
    case "${1%%+*}" in
        OPEN) printf 'not started' ;;
        UNDERSTANDING) printf 'working out what to build' ;;
        PLANNING) printf 'writing the plan' ;;
        WORKING) printf 'building on the feature branch' ;;
        REVIEWING) printf 'reviewing the branch' ;;
        COMPOUNDING) printf 'writing the retro' ;;
        DONE) printf 'finished, ready to land' ;;
    esac
}

# The batch arguments the run has not started yet, space-joined. Empty before
# the queue exists - a bad argument count, or no git repository - and empty
# again once the last item is under way, so a stop with nothing left to do adds
# no line.
BATCH_REMAINING=""

report_remaining() {
    # Every stop passes through here. A batch that stops halfway must not lose
    # what it had left to do: the arguments are printed so a human can re-issue
    # them once the stop is understood.
    [[ -n $BATCH_REMAINING ]] || return 0
    err "not started: $BATCH_REMAINING"
}

die() {
    err "${E_ERROR}error${E_RESET}  $*"
    report_remaining
    err "afk run failed"
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
            err "${E_ERROR}error${E_RESET}  ${#roots[@]} worktrees claim task $1: ${roots[*]}"
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

task_field() {
    # $1: task ID  $2: field name -> that field of the authoritative record,
    # with tatr's '-' placeholder mapped to the empty string.
    local root value
    root=$(task_root "$1") || return 1
    value=$(tatr -r "$root" show "$1" 2> /dev/null | sed -n "s/^- $2: //p" | head -1)
    [[ $value == "-" ]] || printf '%s\n' "$value"
}

task_activity() { task_field "$1" ACTIVITY; }
task_gates() { task_field "$1" GATES; }
task_resolution() { task_field "$1" RESOLUTION; }

task_exists() {
    # $1: task ID. Existence is tatr's exit status, not a non-empty field: a
    # task that has not started carries no activity and is still a real task.
    local root
    root=$(task_root "$1") || return 1
    tatr -r "$root" show "$1" > /dev/null 2>&1
}

phase_label() {
    # $1: task ID -> the one word a human reads for its lifecycle position: a
    # resolved record reads its resolution, an open one reads its activity
    # with the earned gates appended in tatr's frontier style (WORKING+PLAN),
    # and a task with no activity yet reads OPEN.
    local resolution activity gates
    resolution=$(task_resolution "$1") || return 1
    if [[ -n $resolution ]]; then
        printf '%s\n' "$resolution"
        return 0
    fi
    activity=$(task_activity "$1")
    [[ -n $activity ]] || {
        printf 'OPEN\n'
        return 0
    }
    gates=$(task_gates "$1")
    printf '%s%s\n' "$activity" "${gates:+"+${gates// /+}"}"
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
    # matter what its prose claimed. All three lifecycle fields are hashed,
    # not just the cursor: earning a gate without moving the activity is
    # durable progress too.
    local id=$1 wt root verdict
    root=$(task_root "$id") || return 1
    wt=$(task_worktree "$id")
    verdict=$(sed -n 's/^- VERDICT: //p' "$root/tasks/$id/REVIEW.md" 2> /dev/null | tail -1)
    {
        printf '%s\n' "$(task_activity "$id")"
        printf '%s\n' "$(task_gates "$id")"
        printf '%s\n' "$(task_resolution "$id")"
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
#
# A session ends one of three ways: it finishes and reports a marker, it fails
# (and the run dies), or afk stops it on purpose because its context grew past
# a limit. That third outcome is not a failure, so it leaves KILL_REASON rather
# than RESULT_TEXT and the caller rotates instead of dying. The heartbeat kills
# through the same teardown but is a failure and stays one: a silent session is
# killed whether or not it is anywhere near a limit.

CLAUDE_PID=""

# Set when afk stopped the invocation in flight on purpose; empty otherwise.
KILL_REASON=""

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
    err "${E_ERROR}interrupted${E_RESET}  the run is resumable with 'afk run <task-id>'"
    report_remaining
    [[ $rc -ne 0 ]] || rc=130
    exit "$rc"
}

stop_claude() {
    # $1: the signal to send. Kills the invocation in flight and drains
    # everything run_claude opened for it - the stream fd, the child, the temp
    # dir, the context meter - reading $sfd and $dir from run_claude's scope.
    # This is that function's teardown, factored out so the heartbeat and both
    # limits cannot drift apart and leave an fd or a temp dir behind.
    exec {sfd}<&-
    kill -"$1" "$CLAUDE_PID" 2> /dev/null
    wait "$CLAUDE_PID" 2> /dev/null
    CLAUDE_PID=""
    rm -rf "$dir"
    report_tokens
}

run_claude() {
    # $1: 'fresh' or 'resume'  $2: session UUID  $3: prompt.
    # Streams the session, enforcing the heartbeat and the context limits, and
    # leaves the terminal result's text in RESULT_TEXT - or, when afk stopped
    # the session itself, the reason in KILL_REASON and RESULT_TEXT empty.
    local mode=$1 uuid=$2 prompt=$3
    KILL_REASON=""
    RESULT_TEXT=""
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

    local dir fifo line typ text used result="" rc sfd partial="" started last_event
    local soft_armed=0 pending_tools=0 drained
    dir=$(mktemp -d) || die "cannot create a temporary directory"
    fifo="$dir/stream"
    mkfifo "$fifo" || die "cannot create the event pipe"

    # Monitor mode ONLY for the launch: a shell without job control starts async
    # commands with SIGINT ignored, and an ignored disposition survives exec, so
    # the hard limit's CTRL+C would be silently discarded. Under `set -m` the
    # child gets its own process group with default dispositions. It is also no
    # longer in afk's, so a terminal CTRL+C reaches it only through on_signal -
    # which is exactly what on_signal already does.
    set -m
    claude "${args[@]}" > "$fifo" 2> "$dir/err" &
    CLAUDE_PID=$!
    set +m
    exec {sfd}< "$fifo"

    # The pipe is POLLED at spinner rate and the heartbeat is an explicit
    # budget since the last event - the same rule the old blocking read
    # expressed, separated from the read so the spinner can advance while the
    # model is silent. There is still no wall-clock cap: a long, productive
    # turn keeps emitting events and only a genuinely silent one is killed -
    # what bounds a productive turn is its CONTEXT, on the limits below.
    started=$SECONDS
    last_event=$SECONDS
    SPIN_MSG=""
    SESSION_TOKENS=""
    while true; do
        # '!' would reset $?, so the read status is captured on its own line:
        # >128 is a poll timeout, 1 is a clean end of stream.
        IFS= read -r -t 0.2 -u "$sfd" line
        rc=$?
        if [[ $rc -gt 128 ]]; then
            # A timeout mid-line leaves what did arrive in $line; keep it, or
            # the event is silently cut in half.
            if [[ -n $line ]]; then
                partial+=$line
                last_event=$SECONDS
            fi
            if [[ $((SECONDS - last_event)) -ge $AFK_HEARTBEAT_SECS ]]; then
                stop_claude TERM
                die "claude produced no output for ${AFK_HEARTBEAT_SECS}s; session killed"
            fi
            spin $((SECONDS - started))
            continue
        fi
        last_event=$SECONDS
        # A final line without its newline still arrives, with status 1.
        line="$partial$line"
        partial=""
        if [[ -n $line ]]; then
            typ=$(printf '%s' "$line" | jq -r 'try .type catch empty' 2> /dev/null)
            case "$typ" in
                result) result=$line ;;
                assistant)
                    # The context this turn was holding: everything the model
                    # read plus what it wrote. Absent usage leaves the last
                    # known count alone rather than resetting it to zero, and
                    # the LATEST count wins - after a compaction the context
                    # genuinely shrinks and the display should follow it down.
                    used=$(printf '%s' "$line" | jq -r 'try (if .message.usage then (.message.usage | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0) + (.output_tokens // 0)) else empty end) catch empty' 2> /dev/null)
                    if [[ $used =~ ^[0-9]+$ ]]; then
                        SESSION_TOKENS=$used
                        # Past the hard limit there is nothing left to wait
                        # for: stop the way CTRL+C would and let the rotation
                        # reconstruct the phase from durable state. The soft
                        # limit only ARMS a stop, and says nothing yet - the
                        # boundary below is what decides whether it fires.
                        if [[ $SESSION_TOKENS -ge $AFK_HARD_TOKENS ]]; then
                            KILL_REASON="hard context limit crossed at $(fmt_tokens "$SESSION_TOKENS")"
                            stop_claude INT
                            return 0
                        elif [[ $SESSION_TOKENS -ge $AFK_SOFT_TOKENS ]]; then
                            soft_armed=1
                        fi
                    fi
                    # A turn may issue several tools at once, so what is in
                    # flight is a COUNT, not a flag. Each tool_use raises it and
                    # each tool_result below lowers it; only zero means the
                    # model, not a tool, holds the session.
                    drained=$(printf '%s' "$line" | jq -r 'try ([.message.content[]? | select(.type=="tool_use")] | length) catch 0' 2> /dev/null)
                    if [[ $drained =~ ^[0-9]+$ ]]; then
                        pending_tools=$((pending_tools + drained))
                    fi
                    text=$(printf '%s' "$line" | jq -r 'try ([.message.content[]? | select(.type=="text") | .text] | join("\n")) catch empty')
                    if [[ -n $text ]]; then
                        # CR and ESC are flattened alongside the whitespace: a
                        # transient decoration line may not move the cursor or
                        # set a mode, and model text quoting terminal output
                        # carries both.
                        SPIN_MSG=$(printf '%s' "$text" | tr '\n\t\r\033' '    ' | tr -s ' ')
                        if [[ ${AFK_VERBOSE:-0} == 1 ]]; then
                            spin_clear
                            printf '%s\n' "$text" | sed 's/^/| /'
                        fi
                    fi
                    ;;
                user)
                    # The soft limit's safe boundary. Each tool_result arrives
                    # as its own user event, so a single one proves nothing
                    # while a parallel sibling is still writing: the boundary is
                    # the tool_use count reaching ZERO, which is the only point
                    # at which a SIGTERM cannot interrupt a half-written edit.
                    # An armed session that reaches its own result event first,
                    # or whose count never drains, is left alone and routed by
                    # its marker: the soft limit is best-effort by construction.
                    drained=$(printf '%s' "$line" | jq -r 'try ([.message.content[]? | select(.type=="tool_result")] | length) catch 0' 2> /dev/null)
                    if [[ $drained =~ ^[0-9]+$ ]] && [[ $drained -gt 0 ]]; then
                        pending_tools=$((pending_tools - drained))
                        if [[ $pending_tools -lt 0 ]]; then
                            pending_tools=0
                        fi
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
    wait "$CLAUDE_PID"
    rc=$?
    CLAUDE_PID=""
    report_tokens

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
        line "$C_COMMIT" commit "${after:0:7} $(git -C "$main_worktree" log -1 --format=%s "$after")"
    fi
    after=$(ref_head HEAD)
    if [[ -n $after && $after != "$2" ]]; then
        line "$C_COMMIT" commit "${after:0:7} $(git -C "$main_worktree" log -1 --format=%s "$after")"
    fi
}

report_phase() {
    # $1: task ID. The phase a human cares about, read from tatr, with a gloss
    # so a bare lifecycle word is not the only thing on screen.
    local label gloss
    label=$(phase_label "$1")
    SPIN_PHASE=$label
    gloss=$(phase_gloss "$label")
    if [[ -n $gloss ]]; then
        line "$C_PHASE" phase "$label  $gloss"
    else
        line "$C_PHASE" phase "$label"
    fi
}

require_activity() {
    # $1: task ID  $2: expected ACTIVITY  $3: what claimed it.
    local actual
    actual=$(task_activity "$1") || die "cannot read the activity of $1"
    [[ $actual == "$2" ]] ||
        die "$3 but $1 is in ${actual:-no activity}, not $2"
}

require_gate() {
    # $1: task ID  $2: gate that must be earned  $3: what claimed it.
    # GATES is an accumulating whitespace-delimited set, so this is a token
    # match and not a comparison against the whole field.
    local gates
    gates=$(task_gates "$1") || die "cannot read the gates of $1"
    [[ " $gates " == *" $2 "* ]] ||
        die "$3 but $1 has earned ${gates:-no gates}, not $2"
}

require_resolution() {
    # $1: task ID  $2: expected RESOLUTION  $3: what claimed it.
    local actual
    actual=$(task_resolution "$1") || die "cannot read the resolution of $1"
    [[ $actual == "$2" ]] ||
        die "$3 but $1 is resolved ${actual:-not at all}, not $2"
}

require_progress() {
    # $1: task ID. Every rotation passes through here: a session that left the
    # whole fingerprint identical made no durable progress, and giving it a
    # successor would only spend the session budget getting nowhere. Reads and
    # updates cmd_run's prev_fp, which is what "consecutive" means.
    local fp
    fp=$(fingerprint "$1") || die "cannot fingerprint $1"
    [[ -z $prev_fp || $fp != "$prev_fp" ]] ||
        die "no durable progress across two consecutive sessions"
    prev_fp=$fp
}

rotate_stopped() {
    # $1: task ID. The route for a session afk stopped on a context limit. It
    # emitted no marker, so durable state is all the next session gets - which
    # is exactly what /flow reads anyway - and the fingerprint is the only
    # thing standing between a stuck run and AFK_MAX_SESSIONS.
    require_progress "$1"
    line "$C_NEXT" next "$KILL_REASON; rotating to a fresh context"
}

gate() {
    # $1: task ID  $2: marker status  $3: the exact gates.md approve label
    # $4: the gate's human name.
    # One resume, one label. The session is disposable afterwards either way.
    # Returns non-zero when the resume was stopped on a context limit: a
    # half-answered gate is not an approved one, and a fresh /flow re-reaches
    # the same gate from durable state.
    line "$C_GATE" gate \
        "$4 - approved automatically, starting an afk run approves the flow gates"
    run_claude resume "$SESSION_UUID" "$3"
    [[ -z $KILL_REASON ]] || return 1
    if parse_marker && [[ $MARKER_ID != "$1" ]]; then
        die "the $4 gate answered for task $MARKER_ID, not $1"
    fi
}

lifecycle_gate() {
    # $1: marker status  $2: the ACTIVITY the gate is only legal from
    # $3: the exact gates.md approve label  $4: the postcondition kind, 'gate'
    # or 'activity'  $5: the postcondition value  $6: the gate's human name.
    # Both ends are checked against tatr: a gate afk cannot see land in the
    # record is a gate afk must not build on. The postcondition kind varies
    # because not every lifecycle edge earns a gate, and where one is earned
    # it - not the cursor - is the durable half: leaving PLANNING with a
    # blocked dependency records PLAN and holds the cursor, and calling that a
    # failed approval would be a lie. Returns non-zero when the gate was
    # stopped on a context limit, having reported what it did change.
    local before_main before_feat
    require_activity "$TASK_ID" "$2" "the session reported $1"
    before_main=$(ref_head HEAD)
    before_feat=$(ref_head "refs/heads/$(feature_branch "$TASK_ID")")
    if ! gate "$TASK_ID" "$1" "$3" "$6"; then
        report_phase "$TASK_ID"
        report_commits "$TASK_ID" "$before_main" "$before_feat"
        return 1
    fi
    case "$4" in
        gate) require_gate "$TASK_ID" "$5" "the $6 gate was approved" ;;
        activity) require_activity "$TASK_ID" "$5" "the $6 gate was approved" ;;
        *) die "internal error: unknown postcondition kind '$4'" ;;
    esac
    report_phase "$TASK_ID"
    report_commits "$TASK_ID" "$before_main" "$before_feat"
}

run_item() {
    # $1: one goal string, or one task ID that has already been verified to
    # exist. Drives it from its current activity to a landed commit and reports
    # its own summary. TASK_ID is a global because gate and lifecycle_gate read
    # it, and prev_fp is a local because require_progress reads it from here -
    # that is what "two consecutive sessions" means, and it is scoped to the
    # item so one item's history cannot judge the next one's. Leaves the
    # session count in ITEM_SESSIONS.
    local input=$1 goal="" prompt
    TASK_ID=""
    if [[ $input =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
        TASK_ID=$input
    else
        goal=$input
    fi

    if [[ -n $TASK_ID ]]; then
        head_line "$C_AFK" task "$TASK_ID"
    else
        head_line "$C_AFK" goal "$goal"
    fi

    local session=0 prev_fp="" main_before feat_before branch landed phase
    # $SECONDS is process-wide, so the item's own elapsed time is a difference
    # from where it started, not the counter itself.
    local item_started=$SECONDS
    while true; do
        session=$((session + 1))
        if [[ $session -gt ${AFK_MAX_SESSIONS} ]]; then
            die "reached AFK_MAX_SESSIONS=${AFK_MAX_SESSIONS} without finishing"
        fi

        SESSION_UUID=$(uuidgen)
        phase=""
        [[ -z $TASK_ID ]] || phase=$(phase_label "$TASK_ID")
        SPIN_PHASE=${phase:-starting}
        say ""
        head_line "$C_SESSION" "session $session" "$SESSION_UUID"
        if [[ -n $TASK_ID ]]; then
            prompt="/flow $TASK_ID"
        else
            prompt="/flow \"$goal\""
        fi
        line "$C_PROMPT" prompt "$prompt"

        main_before=$(ref_head HEAD)
        feat_before=$(ref_head "refs/heads/$(feature_branch "${TASK_ID:-none}")")
        run_claude fresh "$SESSION_UUID" "$prompt"

        if [[ -n $KILL_REASON ]]; then
            [[ -n $TASK_ID ]] ||
                die "$KILL_REASON, before the session recorded a task to resume from"
            report_phase "$TASK_ID"
            report_commits "$TASK_ID" "$main_before" "$feat_before"
            rotate_stopped "$TASK_ID"
            continue
        fi

        parse_marker ||
            die "the session ended with no AFK control marker; last line: $(printf '%s\n' "$RESULT_TEXT" | tail -1)"
        if [[ -z $TASK_ID ]]; then
            TASK_ID=$MARKER_ID
            task_exists "$TASK_ID" ||
                die "the session reported task $TASK_ID, but no such record exists"
            line "$C_PHASE" task "$TASK_ID created"
        elif [[ $MARKER_ID != "$TASK_ID" ]]; then
            die "the session reported task $MARKER_ID, not $TASK_ID"
        fi

        report_phase "$TASK_ID"
        report_commits "$TASK_ID" "$main_before" "$feat_before"

        case "$MARKER_STATUS" in
            ROTATE)
                require_progress "$TASK_ID"
                line "$C_NEXT" next "rotating to a fresh context"
                ;;
            PLAN_READY)
                if lifecycle_gate PLAN_READY PLANNING \
                    "Approve plan - earn the PLAN gate" gate PLAN "plan ready"; then
                    prev_fp=""
                else
                    rotate_stopped "$TASK_ID"
                fi
                ;;
            WORK_DONE)
                if lifecycle_gate WORK_DONE WORKING \
                    "Approve review - move to REVIEWING" activity REVIEWING "work done"; then
                    prev_fp=""
                else
                    rotate_stopped "$TASK_ID"
                fi
                ;;
            LAND_READY)
                require_resolution "$TASK_ID" DONE "the session reported LAND_READY"
                branch=$(feature_branch "$TASK_ID")
                [[ -n $branch ]] ||
                    die "$TASK_ID has no sprout worktree, so there is no branch to land"
                main_before=$(ref_head HEAD)
                feat_before=$(ref_head "refs/heads/$branch")
                if ! gate "$TASK_ID" LAND_READY "Approve landing - land the branch" landing; then
                    report_phase "$TASK_ID"
                    report_commits "$TASK_ID" "$main_before" "$feat_before"
                    rotate_stopped "$TASK_ID"
                    continue
                fi
                landed=$(ref_head HEAD)
                [[ $landed != "$main_before" ]] ||
                    die "the landing gate was approved but $branch produced no commit on $(git -C "$main_worktree" symbolic-ref --quiet --short HEAD)"
                ! git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch" ||
                    die "the landing gate was approved but branch $branch still exists"
                line "$C_LAND" landed "${landed:0:7} $(git -C "$main_worktree" log -1 --format=%s)"
                line "$C_LAND" cleanup "$branch worktree removed"
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
    done

    local elapsed=$((SECONDS - item_started))
    say ""
    head_line "$C_LAND" "done" "$TASK_ID landed"
    say "$(printf '      %d sessions, %dm%02ds' "$session" $((elapsed / 60)) $((elapsed % 60)))"
    ITEM_SESSIONS=$session
}

cmd_run() {
    [[ $# -ge 1 ]] ||
        die "run takes at least one argument: a goal string or a task ID"
    local arg
    for arg in "$@"; do
        [[ -n $arg ]] ||
            die "run takes goal strings or task IDs, not an empty argument"
    done
    [[ -n $main_worktree ]] || die "not inside a git repository"
    cd "$main_worktree" || die "cannot enter $main_worktree"

    # Validate the whole queue before the first session: a typo in the third
    # argument must not surface after the first two have landed. Only the
    # ID-shaped arguments can be checked - a goal string names nothing yet.
    for arg in "$@"; do
        [[ $arg =~ ^[0-9]{8}-[0-9]{6}$ ]] || continue
        task_exists "$arg" || die "no task $arg in $main_worktree/tasks"
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

    # One argument is not a batch: its report stays exactly what it was.
    [[ $total -gt 1 ]] || return 0
    local elapsed=$((SECONDS - started))
    say ""
    head_line "$C_LAND" batch "$total tasks landed"
    say "$(printf '      %d sessions, %dm%02ds' "$sessions" $((elapsed / 60)) $((elapsed % 60)))"
}

AFK_HEARTBEAT_SECS=${AFK_HEARTBEAT_SECS:-900}
# The context window these sessions run in is 200K, so the hard limit is the
# window itself and the soft limit leaves a turn's worth of room under it.
AFK_SOFT_TOKENS=${AFK_SOFT_TOKENS:-180000}
AFK_HARD_TOKENS=${AFK_HARD_TOKENS:-200000}
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
