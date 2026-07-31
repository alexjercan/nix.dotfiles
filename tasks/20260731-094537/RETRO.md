# Retro: Widen absence-proof grep guidance to exclude prose about the removal

- TASK: 20260731-094537
- BRANCH: feature/absence-proof-comments
- REVIEW ROUNDS: 5

## What went well

- Asking the user which command form to document, BEFORE planning, killed the
  form the ledger had proposed. The ledger's `| grep -vE` tail contradicted a
  rule twelve lines below the section being edited, and that contradiction was
  visible from reading the file rather than from any run. The question was
  cheap and it changed the artifact.
- Sabotaging each DoD proof rather than only running it caught a proof that
  matched two lines and so discriminated neither. The same habit, applied by
  the reviewer to inversions rather than deletions, caught two more.
- The out-of-context reviewer was worth five rounds. Its findings were about
  whether the ADVICE is true, which is the only question that matters for a
  file whose content is commands, and every one of them was reproducible in a
  scratch tree in under a minute. An in-session round would have re-checked
  that the words were present.

## What went wrong

- Nine of the thirteen findings, including all five MAJORs, were commands
  written by analogy and never run. Root cause, one sentence: in prose about
  commands, a command reads as an illustration rather than as an artifact, so
  the habit that would have made each one falsifiable - run it - never fired.
  Concretely: `^[^/]*` was invented as the `//` twin of a `#` pattern that had
  been tested; "re-run without `-E`" cannot filter differently, because
  `^[^#]*oldname` is the same expression as a BRE; `--include='*.nix'` was
  this repository's extension pasted into advice for any reader.
- The plan-time dry-run happened and still missed everything, because its
  cases came from the example that prompted the rule (leading and trailing `#`
  comments in nix) instead of from the file types a reader would aim it at
  (markdown, shell, URLs, string literals). A dry-run scoped to the author's
  own example only confirms the author.
- Two of the three round-2 fixes created the round-3 MAJORs. Fixing a finding
  in a document of commands means writing new commands, which inherit the same
  untested status as the ones they replace; nothing in the loop treated a FIX
  as needing its own run until round 4.
- The heading proof `grep -n "^## Absence proofs"` matched the pre-change
  heading, so it was green before the work started. It survived plan, work and
  two review rounds because everyone read it as naming the right section
  rather than as discriminating the change.

## What to improve next time

- In any document whose content is commands, treat each command and each
  VARIANT of one as an untested claim: run it, and run it again after a fix
  rewrites it. The cheap version is a scratch directory holding one file per
  file-type the reader might point the command at, reused across rounds.
- Derive dry-run cases from the READER's inputs, not from the example that
  produced the rule. Here that was four file types and cost six greps.
- Sabotage a `cmd:` proof at PLAN time, not at work time. Three of this
  cycle's proofs were green against the base or blind to their own criterion,
  and plan-time sabotage would have caught all three before a branch existed.

## Action items

- No follow-up task. The one generalizable rule is prose for the plan skill's
  proofs reference and the work skill, and both are ledger entries below rather
  than code.
