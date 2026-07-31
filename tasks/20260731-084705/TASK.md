# Make content fixture matching insensitive to line breaks

- STATUS: OPEN
- PRIORITY: 40
- TAGS: skills,tooling,flow
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a fixture author, I want a `content` assertion to match a rule regardless of
where the prose wraps, so a case is red only when the rule is actually missing.

## Steps

- [ ] Normalize whitespace on BOTH sides of the comparison in
      `home/modules/agents/skills/fixtures/run.sh`'s content section: collapse
      runs of whitespace (including newlines) in the section text and in each
      `requires:`/`forbids:` element before the substring test.
- [ ] Write the degenerate case first: a fixture whose asserted phrase is
      deliberately split across a line break must be RED before the change and
      GREEN after, and a fixture whose phrase is absent must stay red.
- [ ] Check no existing case silently changes meaning: a `forbids:` element
      that was passing only because of a line break becomes a real failure.
      Run the whole gate and read every new finding before adjusting anything.
- [ ] Consider the same treatment for `pointer_condition`, which reads only the
      arrow's own line: decide whether to join a wrapped condition or to keep
      the one-line rule and fail loudly on a condition whose bullet wraps.
      Record the decision either way.

## Definition of Done

- A content assertion matches across a line break
  (cmd: `bash home/modules/agents/skills/check.sh --fixture wrapped_phrase_matches`).
- The gate and its self-test still pass
  (cmd: `bash home/modules/agents/skills/check.sh --self-test && bash home/modules/agents/skills/check.sh`).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).

## Notes

- Found in 20260730-154958: `share the checkout` and `rejected alternative`
  were each absent only because the prose wrapped between the words, and the
  prose was reflowed to satisfy the matcher. That is backwards - the matcher
  should not care.
- Ledger: `line-breaks-are-load-bearing`.
