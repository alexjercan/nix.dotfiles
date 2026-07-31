# Decision: Prove the no-hand-edit rule with a check.sh rule, not fixtures alone

- DATE: 20260731-091429
- STATUS: ACCEPTED
- TASK: 20260730-154955
- TAGS: skills, checker, proofs

## Context

The Definition of Done asserts a NEGATIVE over a whole family: no live
flow-family skill tells an agent to hand-edit `STATUS`, `FLOW STEP`,
`PLAN STATUS` or a lesson disposition annotation. `tatr flow` and `tatr ledger`
are the only writers.

The suite already has two mechanisms that could carry it, and they have
different reach. A content fixture (`skills/fixtures/run.sh`) names ONE file
and asserts `requires:`/`forbids:` substrings over it or one `##` section.
A check.sh rule iterates the `FLOW_FAMILY` array, and `--self-test` refuses to
count a rule as covered until a sabotage case proves it can fire.

The constraint that separates them: a fixture set enumerates files, so a
marker edit introduced into a file no fixture names is invisible to it. The
family is exactly what the criterion quantifies over, and only the rule
quantifies over the family.

## Decision

Both, each doing the job it can do.

`direct-state-edit` becomes a check.sh rule over every `FLOW_FAMILY` skill's
`*.md`, with a sabotage case in `fixtures/selftest.sh`. It owns the
family-wide guarantee and extends to files that do not exist yet.

The content fixtures named by the DoD stay, and own the POSITIVE half the rule
cannot state: that `lessons/ledger.md` reaches for `tatr ledger` and names the
four dispositions, that Finish gates on a recorded decision, that PROMOTE
routes to a reviewed task. Several fixture files may share one `name:` -
`fx_skip` matches by equality and `--fixture` reports the case count - so one
DoD `test:` name stays singly runnable while spanning several files.

## Alternatives considered

- **Content fixtures only.** Cheapest, and it keeps every proof singly
  runnable via `--fixture`. Rejected: it cannot see a new file, so the
  criterion would quietly narrow from "no live flow-family skill" to "none of
  the eight files someone remembered to enumerate". That is precisely the
  drift `unclassified-skill` was added to catch elsewhere in the gate.
- **A check.sh rule only.** Full family coverage and falsifiable by
  construction. Rejected: rules are not individually runnable, so all six DoD
  items would collapse into one `cmd: bash check.sh` and a failure would not
  say which criterion broke. It also cannot assert the positive vocabulary -
  a rule that greps for absence says nothing about `tatr ledger` being the
  documented verb.
- **A fifth fixture kind with a file glob.** Would unify the two. Rejected as
  new harness machinery for one criterion, when `FLOW_FAMILY` already exists
  in check.sh and is already the authority on family membership.
- **Do nothing; trust the prose.** The ledger reference TODAY documents three
  hand-written annotation forms, which is the live violation this task fixes.
  Deferring costs the regression guard on the fix.

## Consequences

Easier: the family-wide claim is checked over the family, and adding a
flow-family skill inherits the guard with no fixture to remember. The
self-test's uncovered-rules report keeps every rule paired with a sabotage
case - though coverage is not the same as non-vacuity, and round 1 proved the
difference: the first version of this rule fired on all five of its
hand-picked sabotages while being blind to 17 of the 39 real
marker sentences in the tree. The `expect_clean` cases added in round 1 are
the other half of that, and they exist because nothing in the suite had ever
tested a rule's QUIET direction.

Harder: the criterion is proven by two artifacts in two files, so a future
session changing the ledger grammar must update both the rule's pattern and
the fixtures' substrings. The rule matches text, so it inherits
`line-breaks-are-load-bearing` - hence the whitespace join before clause
splitting.

The rule ships WITH an exemption path, not needing one later: prose that
describes the markers without ordering an edit is legal, which
`flow/resume.md` and `plan/decision.md` both rely on. Its terms are narrow on
purpose - the tool must be the clause SUBJECT (`tatr <verb>` at the head or
after a comma) or the named INSTRUMENT (`with|via|using|through tatr <verb>`),
and a negation must attach to the edit verb itself. A bare `tatr` or a bare
`never` anywhere in the clause is NOT an exemption, because the likeliest real
violation - "if `tatr flow` is unavailable, set FLOW STEP by hand" - contains
both. That narrowness is the rule's known cost: it decides agency from surface
grammar, so an unusual construction (a violation written as a continuation
line of a bullet, where the clause head is the bullet's own text) can still
read as descriptive prose and pass.
