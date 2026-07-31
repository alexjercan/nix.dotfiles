# Parallel review lanes

Default: one out-of-context reviewer. Open only applicable lanes when failures
are quiet, costly, or irreversible: auth/trust, secrets, persistence/migration,
concurrency, public contracts, shared infrastructure, or a broad contract.
User may request lanes.

## Lanes

- Behavior/proofs: Story, literal Steps, independent read-only proofs.
  Report mutating/building proofs as skipped for primary execution.
- Correctness/security/concurrency: boundaries, errors, validation, races,
  hostile/corrupt inputs.
- Design/standards/docs: conventions, reuse, scope/YAGNI, complexity,
  decision records, invalidated documentation.

Give each the same task ID, branch/worktree, default, dimensions, record
format, and its lens. Exclude implementation context and other replies.
Returns: findings by severity plus verified/skipped items; at most 400 words
outside findings. No edits, commits, fixes, or verdict.

## Aggregate

The primary reviewer:

1. Runs skipped proofs serially.
2. Reproduces each finding; drops/demotes unverified claims.
3. Deduplicates defects.
4. Assigns canonical severity by impact.
5. Writes one ranked round/verdict and names the lanes in `- REVIEWER:`.

Never concatenate separate reviews. Lanes share the task worktree read-only.
Only the primary runs commands that mutate outputs, locks, result links, or
caches. Implementer fixes findings; primary commits the round.
