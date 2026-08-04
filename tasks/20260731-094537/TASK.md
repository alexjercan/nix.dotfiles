# Widen absence-proof grep guidance to exclude prose about the removal

- PRIORITY: 55
- TAGS: feature, skills, lessons
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

As a plan author, I want absence-proving greps to exclude prose ABOUT a
removal as well as the task records, so a proof that a mechanism is gone is
not defeated by the comment explaining that it is gone.

## Steps

- [x] Rewrite `## Absence proofs must exclude the records` (line 38) in
      `home/modules/agents/skills/plan/proofs.md` per DECISION.md: retitle it
      so it covers prose about the code, state BOTH halves of the self-match
      (the record quoting the string, and the comment or NOTE the same diff
      writes about the removal), and replace the two-line example block with
      the pipe-free form
      ``(cmd: `grep -rn --exclude-dir=tasks -E '^[^#]*oldname' .`)``.
- [x] In the same section, state where `^[^#]*` holds and where it lies, and
      WHY it is one command rather than a `| grep -v` tail, so a reader does
      not reinvent the form DECISION.md rejected. The `## Proofs must be able
      to fail` no-pipe rule stays as is; this section must not contradict it.
      Amended after round 1: the step planned a `^[^/]*` variant for `//`
      languages, which review showed to be wrong, so the section warns against
      inventing one instead of offering it (R1.1).
- [x] Re-point anything citing the old heading by name:
      `grep -rn "exclude the records" home/modules/agents/skills`.
- [x] Fold the ledger entry: delete the `## Pending promotions` entry
      (LESSONS.md line 195) and rewrite the `## Process lessons` entry (line
      142) so ONE entry remains, carrying an applied marker and dropping its
      "see Pending promotions" pointer. `promotion-stalled` fires on an entry
      outside Pending with no marker, so `(x6, PROMOTED 2026-07-31 -> plan
      skill DoD guidance)` is the shape to keep (verified at tatr.c:6571).
- [x] Run the gates below, plus the bare `nix flake check` (AGENTS.md: the
      `--no-build` form only evaluates checks, it does not run them).

## Definition of Done

- The worked command in the code fence filters comments by pattern and applies
  it only to files whose `#` starts a comment
  (cmd: ``grep -n "include='\*.<ext>' -E '\^\[\^#\]\*oldname'" home/modules/agents/skills/plan/proofs.md``).
- That same command skips `.git`
  (cmd: `grep -n exclude-dir=.git home/modules/agents/skills/plan/proofs.md`).
- The prose tells the author to cross-check the filter with the bare token, so
  a hidden real hit is caught
  (cmd: ``grep -n "bare token" home/modules/agents/skills/plan/proofs.md``).
- The prose says what to do when the cross-check fires
  (cmd: ``grep -n "wrong for that token" home/modules/agents/skills/plan/proofs.md``).
- The prose warns against inventing the `//` equivalent instead of offering one
  (cmd: ``grep -n "Do not invent the equivalent" home/modules/agents/skills/plan/proofs.md``).
- The prose says why it is one command rather than a pipeline
  (cmd: ``grep -n "reads as absent" home/modules/agents/skills/plan/proofs.md``).
- Its heading no longer scopes the rule to the records alone
  (cmd: ``grep -n "^## Absence proofs must exclude prose" home/modules/agents/skills/plan/proofs.md``).
- One ledger entry for the slug remains and it is outside Pending promotions
  (cmd: `grep -c dod-grep-excludes-task-records LESSONS.md` prints 1).
- The skill suite still conforms, budgets included
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository conformance passes with the ledger folded
  (cmd: `tatr check --ledger LESSONS.md`).

## Notes

- Promoted from the `dod-grep-excludes-task-records` (x6) ledger lesson,
  disposition PROMOTE recorded 2026-07-31. This WIDENS the existing
  2026-07-20 promotion rather than adding a new rule.
- Cost two grep rewrites in 20260730-190929; see DECISION.md for the two
  false reds and why the ledger's own `| grep -vE` form was rejected.
- Proofs run against base at plan time and again in the worktree before the
  edit: the pattern greps are red (rc=1, the guidance is not there yet), the
  heading grep prints the old line-38 title, and `grep -c` prints 2 - so each
  one moves for the right reason. The single pattern proof planned here became
  four over work and round 1; see `## Close-out`.
- The `test: dod_grep_excludes_comments` proof this record used to carry was
  dropped: it assumed `home/modules/agents/skills/fixtures/`, deleted in
  20260730-154955. check.sh has no per-file content rule to extend, so the
  DoD is pinned on greps over the reference file itself.
- The pattern was dry-run in a scratch tree (see DECISION.md); it excludes
  both a leading `#` comment and a trailing one, honours `--exclude-dir`, and
  returns rc=1 with no output when the mechanism is genuinely gone. Round 1
  found the cases that dry-run missed - markdown headings, URLs, `#` inside a
  string - which is why the section now frames it as a filter to cross-check
  rather than a rule to trust.
- proofs.md was 508 words of its 1000-word `reference-budget` on master and is
  710 on this branch, so the added lines are affordable.
- The change is prose in a reference file; it still takes the normal
  out-of-context round-1 review before landing.

## Close-out

**What changed.** `plan/proofs.md`'s absence-proof section is retitled
"must exclude prose about the code" and now names both halves of the
self-match. The second fence command carries
`--exclude-dir=.git -E '^[^#]*oldname'`, followed by four bullets framing the
pattern as a filter rather than a rule: where it holds (`#` must START a
comment, so a markdown heading is a real hit it hides) and the unfiltered
cross-check that catches what it drops, scoping doc trees by directory
instead, why not to invent the `//` equivalent, and why it stays one command.
In LESSONS.md the two `dod-grep-excludes-task-records` entries fold into one
under `## Process lessons`, marked `PROMOTED 2026-07-31 -> plan skill DoD
guidance`; `## Pending promotions` is now empty.

Code diff, excluding the records
(`git diff --cached --stat -- . ':!tasks'` against 56b386b):

```
 LESSONS.md                                | 19 ++++-------------
 home/modules/agents/skills/plan/proofs.md | 35 ++++++++++++++++++++++++++-----
 2 files changed, 34 insertions(+), 20 deletions(-)
```

**Alternatives.** DECISION.md holds the three: the ledger's own
`| grep -vE ":[0-9]+: *#"` pipeline (rejected - it would report the filter's
exit code, contradicting the no-pipe rule 12 lines below in the same file),
principle-without-a-command (rejected - that is what the ledger already said,
and 20260730-190929 still got it wrong twice), and retiring the lesson.

**Difficulties.** The planned DoD proof
`grep -n "\^\[\^#\]\*" proofs.md` matched TWO lines - the fence and the prose
caveat - so deleting either alone left it green. Caught by sabotaging it
rather than by reading it (`proof-must-cover-its-conjunct`). Split into three
single-purpose greps, each re-sabotaged: removing `-E` from the fence turns
the first red while the other two stay green.

**Round 4.** APPROVE, with one MINOR: the cross-check said how to detect a
hidden hit but not what to do about one. The bullet now ends with the fallback
- the pattern is wrong for that token, so scope by directory and pin a
narrower one. Asked outright whether the pattern still earns its five bullets
against just scoping by directory, the reviewer said keep it: directory
scoping cannot exclude a comment INSIDE a source file, which is the case that
started the lesson, and a `cmd:` proof needs an exit code, not a human reading
hits.

**Round 3.** Two MAJOR, both created by the round-2 fixes and both mine: the
cross-check "re-run without `-E`" is a no-op, since `^[^#]*oldname` is the same
expression as a BRE, so the check could never surface a hidden hit; and
`--include='*.nix'` silently skipped every other file type, hiding a real
`src/deploy.sh` reference. The cross-check now uses the bare token and says why
dropping `-E` is not enough, and the glob is a `<ext>` placeholder the reader
must fill with every extension in play. Also repinned the heading proof, which
had matched the OLD heading too since plan time.

**Round 2.** It confirmed all five round-1 findings resolved and
added three of its own, all MINOR or NIT and all fixed: the `//` proof passed
on both the warning and its inverted form (repinned onto
`Do not invent the equivalent`), the copyable fence still greped `.` while the
bullet under it forbade exactly that (it now carries `--include='*.nix'`), and
the cross-check dropped the exclusions the fence had just set. Adding
`--include` broke the fence's own proof, which is how the eight-proof list
ended up split between the pattern and the `.git` exclusion.

**Round 1.** Three MAJOR findings, all about the guidance being wrong as
advice rather than about the diff's mechanics: the `^[^/]*` variant hides real
code behind any path or URL slash, the `#` pattern silently drops markdown
headings, and its false-green half was stated as a benefit. Each was
re-derived here from scratch files before being adopted. The fix reframes the
pattern as a filter whose output must be checked against the unfiltered
search, and refuses to offer a `//` regex at all. The DoD proofs over the prose
moved with the wording they pin.

**Evidence.** Each proof was run red on the base in the worktree before the
edit, then green after; the pattern itself was dry-run in a scratch tree
(leading `#` comment, trailing `#` comment, real declarations, plus the
mechanism-gone case returning rc=1 with no output). Gates: `check.sh` clean at
22 rules, `tatr check --ledger LESSONS.md` clean, `sprout-test.sh` 14/14, and
`nix flake check` bare - not `--no-build`, per AGENTS.md - all checks passed.

**Self-reflection.** Writing guidance is not the same as writing a rule that
survives being followed literally, and this task shipped the first as if it
were the second three times over. Every defect in four rounds was a command
written by analogy and never run: `^[^/]*` invented as the `//` twin of a
pattern that had been tested; "re-run without `-E`", which cannot filter
anything differently because `^[^#]*oldname` is the same expression as a BRE;
and `--include='*.nix'`, this repository's extension pasted into advice meant
for any reader. The dry-run that did happen covered the cases the author had
in mind - leading and trailing `#` comments - and none a reader would meet:
markdown headings, URLs, strings, shell scripts. The rule that follows: in a
document whose content IS commands, every command and every variant of one is
an untested claim until it has been run, and the cases have to come from the
file types the reader will point it at rather than from the example that
prompted the rule. The four-round cost of learning that here was entirely
avoidable by running six greps at plan time.

The plan's own DoD proof was the weakest artifact in the
task, and the plan-time baseline run did not expose it: a proof that is red
before and green after can still be blind to half its criterion. Sabotage
belongs at plan time for greps too, not only at work time. The other pull was
to make proofs.md argue the case at length; the section gained 8 lines against
a 1000-word budget now at 614, and the reasoning that does not fit belongs in
DECISION.md, where it went.
