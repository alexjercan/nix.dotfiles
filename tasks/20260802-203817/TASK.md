# afk spinner must never wrap to a second row

- STATUS: CLOSED
- PRIORITY: 70
- TAGS: agents, afk, ux
- KIND: TASK
- FLOW STEP: DONE
- PLAN STATUS: APPROVED

## Why

The afk runner's transient spinner line can exceed the terminal width and wrap
onto a second row. When it wraps, `spin_clear`'s `\r\033[K` only erases the
LAST row, so the head of the spinner stays on screen forever and the next
permanent line is printed under it instead of over it. The run's output stops
being a clean report and turns into a ladder of dead spinner fragments.

The current guard (`home/modules/scripts/afk.sh:187`) is
`${text:0:$((TERM_COLS - 1))}`. Bash substring extraction counts CHARACTERS in
a UTF-8 locale, not DISPLAY COLUMNS - confirmed in scratch: with
`LANG=en_US.UTF-8`, `text="ab😀cd"; ${#text}` is 5, while that string occupies
6 columns. `SPIN_MSG` is claude's assistant text verbatim (afk.sh:415), so it
routinely carries emoji, box drawing and CJK. A 79-character message of
double-width glyphs renders 158 columns wide and wraps on any terminal. Two
smaller variants of the same bug: `TERM_COLS` is sampled once at startup, so a
mid-run narrowing resize under-truncates; and `stty size < /dev/tty` failing
falls back to 80 on a terminal that may be narrower.

The fix is to stop predicting the width and let the terminal enforce it:
disable autowrap (DECAWM, `CSI ? 7 l`) for the spinner write and re-enable it
(`CSI ? 7 h`) immediately after. With autowrap off, a too-long write is CLIPPED
at the right margin instead of continuing on the next row, so the spinner
occupies exactly one row no matter what the payload measures - which makes the
fix cause-agnostic across all three variants above. DECAWM is VT100 and is
honored by xterm, VTE, kitty, alacritty, foot, tmux and screen.

Scope: `home/modules/scripts/afk.sh` (the `spin`/`spin_clear` pair, the
`SPIN_MSG` assembly, and the presentation comment that describes them) plus
`home/modules/scripts/afk-test.sh`. No `.md` doc surface outside the task
folders describes the spinner - `grep -rn spinner --include='*.md'` finds only
`tasks/`.

## Definition of Done

- Every spinner frame written to a terminal is written with autowrap disabled
  and re-enabled, so a frame wider than the terminal is clipped to one row
  instead of wrapping onto a second.
  (test: `test_spinner_never_wraps`)
- Erasing the spinner also restores autowrap, so no exit path - including the
  `INT`/`TERM` handler - can leave the terminal with wrapping off.
  (test: `test_spinner_never_wraps`)
- A spinner message carrying wide characters still leaves no residue: no
  spinner write contains a newline, and the run's permanent lines are
  unchanged from the piped run.
  (test: `test_spinner_never_wraps`, `test_spinner_and_color_only_on_a_tty`)
- The spinner's content and TTY gating are unchanged.
  (test: `test_spinner_and_color_only_on_a_tty`)
- The whole afk suite is green.
  (cmd: `bash home/modules/scripts/afk-test.sh`)

## Steps

- [x] `home/modules/scripts/afk-test.sh`: add `test_spinner_never_wraps`,
  registered in the `run_test` list at the bottom. Seed a planned task and
  `gen_work_to_land 0` as `test_spinner_and_color_only_on_a_tty` does, but make
  invocation 1 emit an assistant event whose text is a long run of
  double-width characters (e.g. 80 copies of a CJK glyph) before the
  `AFK WORK_DONE` marker, and use `reply_slow` so at least one spinner frame is
  drawn. Run it on a pty forced narrow:
  `script -qec "stty cols 40 < /dev/tty; bash '$AFK' run '$id'" /dev/null`.
  Confirm first that `stty cols` inside the `script` child actually resizes the
  pty afk reads (afk reads `stty size < /dev/tty` at startup); if it does not,
  drop the forced width - the wide-character payload alone already exceeds any
  plausible terminal - and record that in Notes.
  Assert on the RAW capture:
  1. every spinner segment (the text between a `\r\033[K` and the next `\r`)
     begins with `\033[?7l` and ends with `\033[?7h`;
  2. no spinner segment contains a newline;
  3. the capture's erase sequence re-enables autowrap, so the spinner is never
     left disabled;
  4. the report's permanent lines (`done  <id> landed`) are still present.
  Run it against unmodified `afk.sh` and confirm it fails - `?7` does not occur
  anywhere in `afk.sh` on the base branch (`grep -c '?7'` is 0), so assertions
  1 and 3 are red by construction.
- [x] `home/modules/scripts/afk.sh`, `spin()`: write the frame as
  `printf '\r\033[K\033[?7l%s\033[?7h' "$truncated"` - one `printf`, hence one
  `write`, so no signal can land between disabling and restoring autowrap.
  Keep the existing `${text:0:$((TERM_COLS - 1))}` truncation: it is no longer
  load-bearing for correctness but still bounds the write and keeps the frame
  readable when the terminal is wider than afk believes.
- [x] `home/modules/scripts/afk.sh`, `spin_clear()`: emit
  `\r\033[K\033[?7h` so every erase - including the one on the interrupt path
  via `err` - also restores autowrap.
- [x] `home/modules/scripts/afk.sh:415`: extend the `SPIN_MSG` sanitizer from
  `tr '\n\t' '  '` to also flatten `\r` and `\033`. Both are the same class of
  bug as the wrap: a raw CR makes the frame overwrite itself and a raw ESC from
  model text quoting terminal output can move the cursor or set a mode, and
  neither is something a transient decoration line may do.
- [x] `home/modules/scripts/afk.sh`, the presentation comment block at the top
  (currently "the spinner is truncated to the terminal width by byte count"):
  that sentence is false - the truncation counts characters - and it is now the
  wrong invariant anyway. Restate it as: the spinner is written with autowrap
  disabled, so it always occupies exactly one row and `spin_clear` always
  erases all of it; the truncation is only a bound on the write.
- [x] Re-read the `## Check suite` entry for `afk-test.sh` in `AGENTS.md`;
  update only if it now states something false.
- [x] Run `bash home/modules/scripts/afk-test.sh` and confirm the whole suite
  is green.

## Notes

- Root cause confirmed in scratch, not assumed: `LANG` is `en_US.UTF-8` here
  and `${#"ab😀cd"}` is 5 against 6 display columns, so the existing truncation
  under-counts exactly the input `SPIN_MSG` is made of.
- Rejected: measuring display width before truncating. There is no portable
  `wcswidth` in bash, so it means shelling out per frame (a subprocess every
  200ms) or hand-rolling an East Asian Width table - a large amount of new
  concept for something the terminal already knows how to do.
- Rejected: a `SIGWINCH` trap to re-read `TERM_COLS`. With autowrap off, a
  resize can no longer wrap the line - narrower clips, wider just leaves the
  frame short - so the trap has no requirement left to satisfy.
- The permanent lines are deliberately NOT wrapped in autowrap-off. They end in
  a newline, so wrapping them is harmless, and clipping real content would lose
  it.
- Sabotage check: reverting the `spin()` change alone turns
  `test_spinner_never_wraps` red while the rest of the suite stays green.

## Close-out

WHAT/WHY: `spin()` now writes its frame as
`\r\033[K\033[?7l<text>\033[?7h` and `spin_clear()` erases with
`\r\033[K\033[?7h`. With autowrap (DECAWM) off for the write, a frame wider
than the terminal is clipped at the right margin instead of continuing on the
next row, so the single-row erase always erases all of it - cause-agnostic
across all three width-prediction variants (character-vs-column counting, the
once-sampled `TERM_COLS`, the 80-column `stty` fallback). The `SPIN_MSG`
sanitizer also flattens CR and ESC, since a transient decoration line may not
move the cursor or set a mode. The presentation comment's "truncated by byte
count" claim was false and is replaced by the autowrap invariant.

ALTERNATIVES: as planned - measuring display width (no portable `wcswidth` in
bash: a subprocess per frame or a hand-rolled East Asian Width table) and a
`SIGWINCH` trap (no requirement left once wrapping is impossible). Neither was
revisited during implementation.

DIFFICULTIES: the forced-narrow pty was NOT the uncertain part - `stty cols 40
< /dev/tty` inside the `script` child does resize the pty afk reads (verified:
`stty size` reports `0 40`), so the width is forced as planned. What did cost a
cycle was the capture parser. The first version recognized a spinner erase by
EQUALITY against `\033[K\033[?7h`, on the assumption that every spinner write
is CR-terminated. Only the frames are: `spin_clear` is followed immediately by
the permanent line it made room for, with no CR between them, so the erase and
that line land in one chunk. The three autowrap assertions stayed red against
the fixed script until both kinds were recognized by PREFIX instead. Diagnosed
by dumping the raw capture and reading the actual bytes rather than trusting
the model of them.

EVIDENCE: `bash home/modules/scripts/afk-test.sh` - 13 passed, 0 failed.
Red-first confirmed on the unmodified script (`grep -c '?7'` was 0; the two
autowrap assertions and the erase assertion failed). Sabotage confirmed:
reverting the `spin()` line alone leaves 12 passing and only
`test_spinner_never_wraps` red. Also green: `nix flake check`,
`bash home/modules/agents/skills/check.sh`, `tatr check`. The `AGENTS.md`
`## Check suite` entry for `afk-test.sh` was re-read and states nothing the
change makes false, so it is unchanged.

REFLECTION: a test that asserts on a raw terminal byte stream is only as good
as its model of who emits CRs. Dumping the capture once, up front, would have
been cheaper than reasoning about the framing twice.
