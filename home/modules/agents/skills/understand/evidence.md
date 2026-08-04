# Evidence for what reading cannot settle

Some questions do not yield to the tree. What a dependency actually does, what
an API returns today, whether an algorithm holds on real input, whether an
integration connects at all - answering those from memory is a hypothesis with
no citation, and it ages silently.

Bound it before you start: say what evidence would be enough, and stop there.
Enough is when one more source or one more run would not change the ranking.
"Nothing further changed the answer" is itself a finding.

## Facts from outside

Browse, and rank what you find:

1. The thing itself - source, spec, release notes, the vendor's reference, the
   installed artifact.
2. The maintainers speaking - issues, changelogs, commits.
3. Everything else - posts, tutorials, answers.

A tier-3 source is a lead, not evidence: follow it to the tier-1 artifact and
cite that one. Where only tier 3 exists, mark the finding uncorroborated
rather than quietly promoting it. Where the claim is about a tool you can run,
run it - a local reproduction outranks any document about the tool.

Every finding carries its claim in one line, its source as a URL, `file:line`
or exact command, the date checked, and what it does not say when that gap
matters. Copy normative sentences rather than paraphrasing them. Two sources
that disagree are both findings: record the disagreement and say which you
believe.

## Behavior you have to run

Build the smallest thing that answers the question, and keep it - deleting it
throws away the only support the ranking has. It lives where the repository's
`AGENTS.md` workflow cache says; failing that, an existing exercised
`examples/`, `scripts/` or `demos/` directory; failing that,
`tasks/<id>/prototype/`.

Anything landing in a repository-native directory is surface: it builds, it
has a documented run command, and a check guards it. Anything that cannot meet
that bar belongs in the task folder instead.

Record, while it is still in front of you: the verbatim run command with its
setup, what you observed rather than what you concluded, how far the verdict
reaches, and the limitations - the faked inputs, the single case, the skipped
error paths. The limitations are the honest half, and they never survive being
written from memory afterwards.

Exploratory code proves the behavior is achievable; it is not the
implementation. Reusing it later is fine, presenting it as done is not.

## Where it goes

Small evidence goes into `## Context` as a cited line. An investigation worth
its own record gets `tatr -r <task-root> scaffold <id> SPIKE` in this same
task - no separate task, no seeded work. Its `- STATUS:` is `RECOMMENDED`,
`INCONCLUSIVE` or `DROPPED`, and `INCONCLUSIVE` is a real answer: record what
was searched, what was not found, and what would settle it.

Evidence that opens a new question instead of closing one is an unknown in
`## Context`, not a reason to keep going.
