# Parallel review lanes

Round 1 already comes from outside the implementing session. Lanes split that
one fresh reader into two or three, each looking for a different class of
defect, and hand their findings to the primary reviewer to resolve into one
round.

## When to open lanes

The default is one reviewer: the single out-of-context round the review skill
already specifies. Most diffs get it and stop there.

Open lanes when the diff touches something whose failures are quiet, costly or
irreversible:

- authentication, authorization, or anything trust is decided by;
- secrets, credentials, tokens, or the files and templates that carry them;
- persistence: a schema, a stored format, or a migration over existing data;
- concurrency, locking, or ordering between processes;
- a public API, a CLI contract, or a wire format other code is written
  against;
- shared infrastructure a mistake would reach beyond this repository;
- a contract change broad enough that no single reading covers it.

Open only the lanes that apply. A migration with no concurrency has no
concurrency lane, and adding one produces confident noise about code the lane
had no reason to read. The user may also ask for lanes on any diff.

## The three lanes

- **Behavior and proofs.** Does the diff deliver the Story? Run every proof
  from `tatr proofs <id>` that only reads, and confirm each passes on its own
  stated criterion. A proof that builds, writes a lock file or touches a shared
  cache is not this lane's to run: skip it and report it as not verified, and
  the primary runs and judges it during aggregation. Re-read every ticked step
  against what the diff actually does.
- **Correctness, security and concurrency.** Edge cases, error paths,
  validation across every domain a value crosses, races, and what an attacker
  or a corrupt input reaches.
- **Design, standards and docs.** Conventions, needless complexity, missed
  reuse, the decision record a load-bearing choice owes, and the doc surfaces
  this diff invalidated.

## What a lane gets and gives back

A lane receives the same bounded handoff the single out-of-context reviewer
gets - task ID, branch, worktree path, default branch, dimensions, record
format - plus the one lane it owns, and no other lane's replies. Nothing from
the implementing session travels with it.

A lane returns at most 400 words outside its findings: findings in the record
format, most severe first, plus what it verified and what it could not. It
writes no file, edits no record, and makes no commit. Fixes are not its job
and neither is the verdict.

## Aggregation

The primary reviewer, the in-session pass the review skill's step 2 describes,
owns the round. Lane findings are input to it, never the round itself.

1. Runs the proofs the behavior lane skipped, and judges them.
2. Re-verifies each finding against the diff before it survives. A lane returns
   a claim and no artifact to inspect, so an unreproduced claim is dropped or
   demoted, not copied through.
3. Deduplicates: one defect found by two lanes is one finding, filed once,
   under whichever lane's framing is most actionable.
4. Assigns the canonical severity from the four the review skill defines.
   Lanes disagree about severity because each sees one class of harm; the
   primary decides, and effort to fix never moves it.
5. Writes one round and one verdict into `REVIEW.md`, numbered as the next
   round, with the findings ranked most severe first. The round's
   `- REVIEWER:` line records that lanes ran and which ones.

Three lanes must not become three concatenated reviews. If the round reads as
a list of who said what rather than as one review of one diff, the aggregation
step did not happen.

## Resources

Lanes read; they do not write. They share one worktree - the task's own,
already checked out - and open it read-only, so no lane needs a checkout of
its own and none can disturb another's reading.

Anything that mutates build output, a lock file, a result symlink or a shared
cache is run ONCE by the primary reviewer, serially, after the lanes report.
Two lanes running the same build concurrently in one tree produce failures that
belong to the race and not to the diff.

Writing stays where it already is: the implementer addresses findings in the
task's own sprout worktree, and the primary reviewer commits the round there.
A lane that believes it needs to edit a file has found something to write down
as a finding instead.
