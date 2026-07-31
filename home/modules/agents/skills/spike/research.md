# Research mode

The question turns on facts this repository does not hold: what a dependency
actually does, what an API returns today, whether a standard says what someone
remembers it saying, what changed in a version nobody here has run.

Answering from memory is the failure this mode exists to prevent. A model's
recollection of an interface is a hypothesis with no citation attached, and it
ages silently. Browse.

## Prefer primary sources

Rank what you find, and say which rank you used:

1. The thing itself - the source, the shipped binary's strings, the spec, the
   release notes, the vendor's own reference.
2. The maintainers speaking - issue threads, changelogs, commit messages.
3. Everything else - blog posts, tutorials, answers, summaries.

A tier-3 source is a lead, not evidence. Follow it to the tier-1 artifact and
cite that. When only tier-3 exists, the finding is explicitly marked as
uncorroborated rather than quietly promoted.

Where a claim is about a tool you can run, the tool is the primary source:
execute it and record the output. A local reproduction beats any document
about the tool.

## Record the findings

Cited findings live in the owning task folder - `tasks/<id>/SPIKE.md`, or a
sibling notes file when the raw material is bulky. Each finding is:

- the claim, in one line;
- its source, as a URL, a `file:line`, or the exact command that produced it;
- the date it was checked, because a current fact is only current on a date;
- what it does NOT say, when the gap matters.

Quote enough of the source that a later reader can tell whether you read it
right, and never paraphrase a normative sentence - copy it.

Contradiction between two sources is a finding too. Record both, say which one
you believe and why, and leave the disagreement visible rather than picking
one silently.

## Index only the answer

Research output is bulky and the Epic index is not the place for it. The Epic
carries a one-line answer plus a pointer to the record that argued it; the
task folder carries the citations, the quotes, and the rejected leads. The
same rule holds for a Fog line the research settled: it becomes one Decisions
line, not a summary.

If the research opens a NEW question rather than closing one, that is a Fog
line, not a Story. Do not seed work for a question you have not answered.

## Bound it

- Set the time-box before browsing, and stop at it. An unbounded search always
  finds one more page.
- Enough is when a further source would not change the recommendation. Say so
  explicitly; "no more sources changed the answer" is a finding.
- `INCONCLUSIVE` is a real verdict. Record what was searched, what was not
  found, and what would settle it. That saves the next session the same hours.
- Independent research questions are safe to run in parallel, each in its own
  task; questions that feed each other are not.
