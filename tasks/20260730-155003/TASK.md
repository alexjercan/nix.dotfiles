# Adopt tatr v2 and revalidate nix task history

- PRIORITY: 50
- TAGS: feature, flow, tatr, migration, testing
- KIND: STORY
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE
- PARENT: 20260730-153122

## Story

As the nix.dotfiles maintainer, I want to adopt the completed tatr v2 release
and revalidate every local task and skill against it, so the deployed tool and
workflow finish the Epic in one coherent state.

## Steps

- [x] Write the proof artifacts first: `tasks/20260730-155003/tatr-rev.py`
      (resolve the root `tatr` node through `flake.lock`'s root inputs map -
      NOT by node name, since `scufris` pulls a second, older `tatr` node - and
      compare it to `git -C /home/alex/personal/tatr rev-parse origin/master`),
      and confirm each DoD `cmd:` is red for the right reason on `master`.
- [x] Confirm the adoption already landed rather than redoing it: `flake.lock`
      root `tatr` is `cd8b33d`, `~/.claude/skills/tatr/SKILL.md` equals
      `/home/alex/personal/tatr/skills/tatr/SKILL.md`, and the profile `tatr`
      exposes the v2 subcommands (`flow`, `frontier`, `context`, `claim`,
      `scaffold`, `proofs`, `ledger`). Record what was confirmed, not redone.
- [x] Confirm the migration already landed: all 55 records under `tasks/`
      carry v2 `KIND`/`FLOW STEP`/`PLAN STATUS` fields, pre-Epic ones tagged
      `historical`, and `tatr check --ledger LESSONS.md` exits 0. Classify, do
      not invent, any record that still fails. None did. The count is still 55
      after this Story, which retired one record and seeded another; the 10
      `historical` ones are the whole 2026-07-03/04 pre-tatr era. Evidence in
      VERIFICATION.md.
- [x] Rewrite `tasks/20260730-153122/TASK.md` `## Done Means` onto proofs that
      still have a runner: drop criterion 5 (`test: parallel_lane_selection`,
      runner deleted with `skills/fixtures/` in 20260730-154955) and renumber
      6-7 to 5-6; restate criterion 4's "skill evaluation harness" clause as a
      manual read (AMENDED after R1.5: it states both the research and the
      prototype half itself, rather than delegating to the `## Manual
      Acceptance` item, which covers only prototypes); leave
      criteria 1, 2, 3, 6 and 7 substantively alone, adding to old 3 and old 6
      only the file holding their runners
      (`/home/alex/personal/tatr/checker.sh`) so Finish can find them. Old 1, 2
      and 7 are byte-identical.
- [x] Fold 20260731-104819 in. AMENDED: the plan said `tatr edit --status
      CLOSED`, which does not exist - `tatr edit` has no `--status`, and the
      only route from BACKLOG to CLOSED runs through a COMPOUNDING gate that
      demands an APPROVE verdict in REVIEW.md. Retire the record with
      `tatr rm` instead, after copying its content and provenance into
      DECISION.md, and seed a task for the missing terminal state. Its step
      "rewrite criterion 3, the fixture suite is gone" rested on a wrong
      premise - `test_epic_frontier` DOES still have a runner - so record that
      correction rather than acting on it.
- [x] Update the Epic index: tick this Story in `## Child Tasks` with its
      close-out annotation, add this DECISION.md to `## Decisions`, and fold
      the lanes and retained-prototype acceptance the dropped and rewritten
      criteria used to carry into `## Manual Acceptance` so nothing is lost by
      the rewrite.
- [x] Record `tasks/20260730-155003/VERIFICATION.md`: every canonical check
      with its command and exit code, the resolved tatr revision, the record
      count, and the two ledger entries already dispositioned PROMOTE.
- [x] Note in the Epic that `tatr flow <epic> --to DONE` refuses while any
      child is not CLOSED (verified in a scratch repo: "child <id> is not
      CLOSED"), so open child 20260731-010900 must be resolved or dropped from
      the Epic before Finish. Do not resolve it here.

## Definition of Done

- The root `tatr` flake input resolves to the published tatr default-branch
  tip (cmd: `python3 tasks/20260730-155003/tatr-rev.py`).
- Every nix.dotfiles task and ledger passes v2 conformance
  (cmd: `tatr check --ledger LESSONS.md`).
- The Epic's acceptance criteria name no deleted fixture runner
  (cmd: `! grep -n "flow_v3_end_to_end\|parallel_lane_selection" tasks/20260730-153122/TASK.md`).
- Every `test:` proof the Epic still cites names a function that exists
  (cmd: `grep -n "^test_epic_frontier()\|^test_ledger_pending_requires_disposition()" /home/alex/personal/tatr/checker.sh`).
- 20260731-104819 is retired and its content preserved where a reader will
  look (cmd: `test ! -e tasks/20260731-104819/TASK.md && grep -n "20260731-104819" tasks/20260730-155003/DECISION.md tasks/20260730-153122/TASK.md`).
- The Epic index ticks this Story
  (cmd: `grep -n "\[x\] 20260730-155003" tasks/20260730-153122/TASK.md`).
- The verification record names every canonical check with its result
  (cmd: `bash tasks/20260730-155003/verification-rows.sh`).
- Skill and sprout integration suites pass
  (cmd: `bash home/modules/agents/skills/check.sh && bash home/modules/scripts/sprout-test.sh`).
- Flake evaluation passes (cmd: `nix flake check --no-build`).
- Representative final reports meet the agreed output budgets (manual: user
  approves them).

## Notes

- Parent Epic: 20260730-153122. Decision record: `DECISION.md` here.
- The external prerequisite is met: tatr `master` is published at `cd8b33d`,
  local and `origin/master` are level, and `flake.lock`'s root `tatr` input is
  already that revision (bumped in `456e3ec`; `495073f` bumped it only as far
  as the intermediate `aeeac3d`). The old `4de04d5` node still in
  the lock belongs to `scufris`, not the root.
- Every canonical check was green on `master` at plan time: `tatr check`,
  `tatr check --ledger LESSONS.md`, `check.sh` (9 skills, 22 rules),
  `sprout-test.sh` (14/14), `nix flake check --no-build`. This cycle is record
  reconciliation, not adoption work; the DoD is written so each item is red on
  `master` only where a record actually needs changing.
- The dropped criterion 5's substance lives in the Epic's `## Manual
  Acceptance` lanes item (20260730-154958), now marked as the only acceptance
  covering that feature. Criterion 4 keeps its own substance: R1.5 showed that
  pointing it at the 20260730-142540 prototype item lost the research half, so
  it states both halves itself rather than delegating.
- `tatr proofs` reads `## Definition of Done`, not an Epic's `## Done Means`,
  so it returns nothing for 20260730-153122 and cannot serve as a proof there.
  This is why the Epic rewrite is proved by grep instead.
- Open question deferred to Finish, not to this task: 20260731-010900 is an
  open Epic child and will block `tatr flow 20260730-153122 --to DONE`.

## Close-out

### What changed and why

The adoption this Story was named for had already landed: `456e3ec` pinned the
root `tatr` input to the published `cd8b33d`, the deployed skill is identical
to the released one, and every record already carried its v2 fields. So the
diff went to the two things that were actually wrong.

1. **A proof for the pin, not another pin.** `tasks/20260730-155003/tatr-rev.py`
   resolves the root `tatr` node through `flake.lock`'s root input map and
   compares it to `origin/HEAD` of the tatr checkout, then asserts each of the
   five prerequisite tatr Stories is CLOSED at that revision. The node-map
   detour is load-bearing: `flake.lock` holds two tatr nodes, and the one named
   `tatr` is the older revision `scufris` pulls in. A by-name lookup reads
   `4de04d5` and passes for the wrong reason.

2. **Epic acceptance criteria rewritten onto runnable proofs.** Two criteria
   named runners that the fixture-suite removal in 20260730-154955 deleted. The
   parallel-lanes criterion is dropped, and criterion 4's "skill evaluation
   harness" clause is restated as a manual read that states both the
   cited-research and the retained-prototype halves itself, rather than
   delegating to the 20260730-142540 item, which covers prototypes only.
   Criteria 3 and 5 keep their `test:` proofs and now name
   `/home/alex/personal/tatr/checker.sh`, where those runners actually live -
   they were never fixture cases. The Epic also gains the Finish blocker it was
   missing, and this Story's own DoD 3 (`test: flow_v3_end_to_end`, a runner
   that never existed) is gone. The argument is in DECISION.md.

Along the way 20260731-104819 was folded in and its record retired, and
20260731-112502 was seeded for the lifecycle gap that retirement exposed.

### Alternatives considered

DECISION.md carries the full argument: a recorded manual end-to-end run
(rejected - trades an unrunnable proof for an unrepeatable one, and duplicates
pending manual acceptance), rebuilding a `flow_v3_end_to_end` shell test
(rejected - revives a suite the user deliberately deleted, and could only
exercise tatr's mechanics, never skill behavior), and running 20260731-104819
as its own cycle (rejected - two cycles editing the same Epic file).

### Difficulties

**The plan's close path for 20260731-104819 did not exist.** It said `tatr edit
--status CLOSED`. `tatr edit` has no `--status`; STATUS is owned by `tatr flow`,
and the only route from BACKLOG to CLOSED is the full lifecycle walk. Diagnosed
by copying the record into a scratch repository and walking it: it reached
REVIEWING and then refused COMPOUNDING with "there is no REVIEW.md", and after
scaffolding one, with "the latest REVIEW.md verdict is 'REQUEST_CHANGES', not
APPROVE". Closing it that way meant fabricating an approving review for work
nobody did. Since the task was a duplicate rather than abandoned work, `tatr rm`
is the honest answer; its content and provenance were copied into DECISION.md
first, and 20260731-112502 now carries the missing terminal state.

**Two of 20260731-104819's premises were wrong.** It claimed criterion 3's
`test_epic_frontier` had lost its runner - it never had one in the fixture
suite, it is in tatr's `checker.sh` and still passes. And its own DoD proposed
`cmd: tatr proofs 20260730-153122`, which cannot fail: `tatr proofs` reads
`## Definition of Done`, which an Epic does not have, so it prints nothing and
exits 0 whatever the Epic says. Acting on that task unread would have deleted a
working proof and added an unfailable one.

**Self-matching absence proof.** The DoD item proving the Epic names no deleted
fixture runner has to quote those runner names. Scoping the grep to the Epic
file alone keeps the item's own text out of its search space; the Epic's Notes
then had to describe the drop without naming the runner.

### Self-reflection

The plan's baseline pass was worth more than usual here. Running every `cmd:`
proof against `master` at plan time is what revealed that eight of this Story's
nine mechanical criteria were already green, which turned a re-do into a
confirm-and-reconcile and kept the diff honest about what this cycle actually
did.

What to do differently: the plan asserted a close mechanism (`tatr edit
--status`) without checking the CLI's own help, in a cycle whose whole subject
was adopting that CLI. `tatr edit --help` costs one call and would have moved
the `tatr rm` decision, and the seeded 20260731-112502, into the plan gate where
the user could weigh them, instead of into the work phase where I decided them
alone. The lesson `dry-run-in-a-scratch-repo` was applied to git and nix
semantics but not to the task tool itself - it belongs there too.

Second: a seeded task's body is a hypothesis, not a spec. 20260731-104819 was
written by a review round under time pressure and got two facts wrong. Verifying
its premises before folding it in cost a few greps and prevented deleting a
working proof.

### Verification

`tasks/20260730-155003/VERIFICATION.md` records every canonical check with its
exit status, the resolved tatr revision, the migration counts and the ledger
state. All nine `cmd:` proofs from `tatr proofs 20260730-155003` were re-run
bare from the worktree and exited 0. The `manual:` proof - that representative
final reports meet the agreed output budgets - stays PENDING for the user at
the Epic's Finish.

Diff stat for this branch: `git diff --shortstat master...HEAD` (run it rather
than trust a number retyped here; the number changes as this block is written).

### Round 1 addendum

Five findings, no BLOCKERs, all addressed on the branch.

R1.1 was the one that mattered and the close-out above is corrected in place:
the pin to `cd8b33d` landed in `456e3ec`, not `495073f`, which had only moved
the input as far as the intermediate `aeeac3d`. The claim came from reading
`git log --oneline -- flake.lock` and taking the commit whose SUBJECT said
"bump tatr to the v2 rev" - a subject line is not a revision. `git log -S<rev>
-- flake.lock` answers the actual question and was what the reviewer used.
This is `counts-come-from-the-diff` wearing a different hat: a fact about a
diff, retyped from a summary of the diff rather than derived from it.

R1.4 replaced a proof that could not fail. `grep -c "exit=0" VERIFICATION.md`
stayed green with five of the six canonical rows deleted, so it never proved
"names every canonical check with its result". It is now
`tasks/20260730-155003/verification-rows.sh`, one anchored regex per check -
anchored so the `tatr check` row cannot be satisfied by the `tatr check
--ledger` row - plus a guard that a recorded `exit=` other than 0 fails too.
Both branches were sabotaged and observed red before being trusted.

R1.3 made the offline path honest. `tatr-rev.py` fetched with `check=True`, so
with no network the proof died in a traceback rather than reporting - against
this repository's rule that no check requires the network. The fetch is now
best effort and degrades to a WARNING over the remote-tracking ref; a missing
`refs/remotes/origin/HEAD` is a real failure and names its fix. Exercised
against a clone repointed at a nonexistent origin.

R1.2 was raised on the user's behalf and put back to them, because it reopened
a decision they had already made without this option on the table: restate the
dropped criterion as a grep over `plan/lanes.md` and `review/lanes.md`. They
chose to keep it dropped; DECISION.md now carries the fourth alternatives
bullet explaining why a grep over the skill's own prose is the deleted `content`
fixture pattern returning as a DoD proof, and why a criterion satisfied by
prose is weaker than an honest `manual:` item - it stops anyone looking.

R1.5 fixed a scope mismatch: Epic criterion 4 covers research AND prototypes
but pointed at a manual item covering only prototypes. It now states both
halves itself.

Re-verified after the fixes: the full canonical suite green, and all nine
`cmd:` proofs re-run bare and exiting 0. The `manual:` proof stays pending.
