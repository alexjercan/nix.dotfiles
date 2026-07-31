# Retro: Turn review and context overruns into planning lessons

- TASK: 20260731-174415
- BRANCH: feat/compound-planning-lessons
- REVIEW ROUNDS: 2

## What went well

Catching two unfalsifiable proofs before implementing rather than after.
`rg -q 'context'` missed the shipped text because the only occurrence was a
capitalised label, and `rg -q 'invent|recorded'` survived deleting the rule it
guarded outright, because `recorded` still matched two sections away. Both
were replaced with the literal rule text before any code was written.

Rejecting a `diagnose.md` reference for the same reason 20260731-174343
rejected a `sizing.md`: the diagnosis runs on every retro, so a conditional
reference would defer context cost rather than avoid it. Two Stories reaching
the same call independently is a sign the rule is real.

## What went wrong

I shipped a restatement in the file whose whole subject is not duplicating
records. The new closing line - "REVIEW owns findings, TASK owns change facts,
RETRO owns one-off process analysis, LESSONS owns recurring general lessons" -
restated the header, step 5's "Keep one-offs only in RETRO", and the
do-not-duplicate paragraph, all in the same file, all within two screens of
what I was typing. Only the LESSONS clause was new; it belonged in the header.

The failed decision was reading Step 5 of the plan ("Keep code findings in
REVIEW, change facts in TASK...") as an instruction to WRITE that sentence,
rather than as a criterion the file should already satisfy. A Step phrased as
content is easy to discharge by pasting the content, and the check that it was
already satisfied never happened.

Second, and subtler: inserting the `## Diagnose` heading silently reparented
the pre-existing "Do not duplicate prose across records" paragraph, which had
closed `## Workflow`. Nothing in the diff touched those lines, so no
line-oriented reading of the diff would show it - the paragraph's SCOPE
changed because a heading appeared above it. Only reading the file top to
bottom finds that.

Third, my round-1 process signal asserted that the plan skill lacked a
plan-time sabotage rule. The reviewer corrected it: `plan/proofs.md` already
mandates exactly that. I had inferred the gap from my own non-compliance
instead of reading the file.

## What to improve next time

A plan Step phrased as content is a criterion, not a dictation. Check whether
the file already satisfies it before adding a sentence.

Inserting a heading changes the scope of every paragraph below it, up to the
next heading. Re-read the whole section after adding one.

Before recording that a rule is missing, grep for it.

## Action items

- 20260731-205300 seeded: give a single owner to the three paraphrase
  restatements the Epic-wide sweep found, including the 120K/150K duplication
  this Epic itself introduced.
- `sweep-for-restatement-not-just-contradiction` reached x3 and the user chose
  PROMOTE into 20260731-205300: the review Docs sweep must ask what now
  RESTATES a rule, not only what contradicts it.
