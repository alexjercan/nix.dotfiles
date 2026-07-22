# Retro: Add secrets/README.md multi-machine key runbook

- TASK: 20260722-220536
- BRANCH: docs/secrets-readme (landed 4d0a9b5)
- REVIEW ROUNDS: 1 (out-of-context, APPROVE)

## What went well

- Dry-ran the whole rekey flow in a throwaway scratch dir (two age keys, encrypt
  to A, `sops updatekeys` to add B, decrypt with B alone) BEFORE writing a single
  command into the runbook. The out-of-context reviewer independently reran the
  same flow and confirmed it - so the security-sensitive commands were proven
  twice, not asserted from memory. This is `dry-run-in-a-scratch-repo` paying off
  exactly where a wrong command could lock someone out.
- The dry-run surfaced the load-bearing subtlety that `sops updatekeys` must be
  run by a key that can CURRENTLY decrypt (it re-wraps the data key), which the
  runbook then states explicitly.

## What went wrong

- Nothing broke. The one gap the review caught was a safety-of-followability
  omission: the onboarding `age-keygen -o` step did not mention that age-keygen
  refuses to overwrite an existing key, so a reader hitting that error might `rm`
  the key and lock themselves out. Root cause: I documented the happy path and
  not the "you already have a key" path. Fixed with an explicit note.

## What to improve next time

- For a runbook, document the error/already-provisioned paths, not just the
  clean first-run path - especially where the tempting recovery action
  (`rm` the file) is the destructive one.

## Action items

- [x] Bumped ledger `dry-run-in-a-scratch-repo` with this task id (recurrence).
- (none) - documentation task, no code follow-up.
