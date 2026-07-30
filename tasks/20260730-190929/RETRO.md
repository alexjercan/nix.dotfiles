# Retro: Share one sops secret between the scufris user service and the root scufris-hostd unit

- TASK: 20260730-190929
- BRANCH: fix/scufris-sops-single-source
- REVIEW ROUNDS: 3 (APPROVE at every round; 4 MINOR + 1 NIT, all fixed)

## What went well

- **Reading the consuming code before planning changed the plan.** The four
  reasons the WIP could not work were derived from `scufris/hostd/main.py`,
  `sops-install-secrets/main.go` and the two flake evaluations, not from the
  error message alone. The error message showed reason 1; reasons 2-4 would
  each have produced a second broken iteration if the fix had been aimed at
  what the compiler complained about.
- **The seam got an assertion instead of a comment.** The chosen architecture
  has one real weakness: a path string duplicated across two evaluations. The
  instinct to write "keep these in sync" in a comment was replaced by a flake
  check that fails the build. Every subsequent review finding was an
  improvement to that check rather than a defect in the configuration - the
  check became the place where correctness was argued.
- **The out-of-context reviewer earned its cost three times over.** Round 1
  falsified a claim in my own comment (sops-nix does NOT validate key names at
  eval time). Round 2 caught that the recipient assertion was broader than
  sops's actual policy semantics. Round 3 caught two sops file shapes the
  resolver mis-parsed, one of which it demonstrated by construction. None of
  these were visible from inside the implementing context.

## What went wrong

- **A confident comment asserted a mechanism I never tested** (R1.1). I wrote
  that sops-nix validates key names at eval time because it was the behaviour
  that *would* make the design safe, and it was plausible enough that I did not
  check. Root cause: the comment was written while designing the mechanism,
  when its truth was still a hope rather than an observation. A one-line
  experiment (add a bogus name, evaluate) falsified it in under a minute.
- **The absence-proving DoD greps caught their own documentation, twice**
  (during work, not review). First the plan's `grep -rn "sops" home/alex` hit
  the comments explaining the new arrangement; then the narrowed
  declaration-syntax grep hit the NOTE explaining why the module is absent.
  Root cause: an absence-proving grep written at plan time cannot anticipate
  that the same task will write prose *about* the absence, and prose about an
  absence necessarily names the thing that is absent.
- **A sabotage harness ended in `head`, so it reported passes as failures.**
  `run() { nix build ... | grep ... | head -2 }` returns head's status, which is
  always 0, so `run && echo BAD || echo PASS` printed BAD unconditionally. I
  briefly believed two working assertions were broken. Root cause: exactly the
  pipe-eats-the-exit-code rule in this repo's own AGENTS.md, applied to a
  throwaway test harness rather than to the build command it warns about.
- **A restore-after-sabotage used `git checkout --` after `git add -A`**, which
  restores from the poisoned INDEX rather than HEAD, leaving `.sops.yaml`
  sabotaged for the following test. Caught by a `git status` that should not
  have shown a modification. Root cause: the helper function staged files as a
  side effect, which the restore was not written to expect.

## What to improve next time

- Any comment asserting that a tool validates, rejects, or guards something is
  a testable claim. Test it in the same edit, or write it as "should" rather
  than "does".
- When a task's own diff will discuss a mechanism it removes, write the
  absence-proving grep to exclude comment lines FROM THE START - the same way
  DoD greps already exclude `tasks/`. The generalisation: an absence proof must
  distinguish code from prose about the code.
- In a throwaway test harness, capture the exit code into a variable on the
  line that produces it (`cmd > out.txt 2>&1; e=$?`) before any pipeline
  touches it. The AGENTS.md rule is about build commands; it applies with equal
  force to the scaffolding that judges them.
- Restore sabotages with `git checkout HEAD -- <file>`, not `git checkout --`,
  so a stray `git add` cannot make the restore a no-op.

## Action items

- [x] Ledger: bumped `sops-dotenv-decrypts-whole-file` with the per-key
      resolution and added `absence-proof-excludes-prose`,
      `test-harness-exit-code`, `checkout-head-not-index` and
      `untested-guarantee-comment`.
- [x] `AGENTS.md`: recorded that `nix flake check --no-build` evaluates the new
      checks without RUNNING them, so the bare form is the one that verifies.
- No follow-up code tasks. The three `manual:` DoD items remain pending user
  confirmation on the real machine and gate the land, not a new task.
