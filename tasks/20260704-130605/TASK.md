# Add the spike skill for ideation and research

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: feature,skills,docs,historical

## Goal

Add a `spike` skill that sits at the front of the plan-work-review-compound
lifecycle. A spike takes a fuzzy idea or open question, explores and
brainstorms it (diverge then converge), writes a durable research artifact to
`docs/spikes/`, and spawns one or more tatr tasks that reference that artifact
so multiple later `/flow` runs can build on the same research instead of
re-deriving it.

## Steps

- [x] Create `home/modules/agents/skills/spike/SKILL.md` with YAML frontmatter
      (`name: spike`, a `description` that follows the sibling-skill style and
      makes clear it triggers on `/spike`, ideation, brainstorming, research
      spikes, and reducing uncertainty before planning).
- [x] Write the workflow section: (1) frame the question / uncertainty and set
      a rough time-box; (2) explore - read relevant code, research options,
      brainstorm approaches divergently; (3) converge on a recommended
      direction with tradeoffs and explicit open questions; (4) write the
      research doc to `docs/spikes/<YYYYMMDD-HHMMSS>-<slug>.md`, creating
      `docs/spikes/` if absent (mirror how compound treats `docs/retros/`);
      (5) turn the recommendation into one or more tatr tasks whose Notes link
      back to the spike doc; (6) report back.
- [x] Include a "Spike Doc Format" section: Question, Context, Options
      considered (with tradeoffs), Recommendation, Open questions, Proposed
      next steps (the tatr tasks it spawned). Keep it a fenced markdown
      template like plan/compound do.
- [x] Add a "Relationship to the Other Skills" section positioning spike
      before `/plan`: spike explores an undefined problem and produces a
      durable research doc + tasks; plan mechanically breaks a defined feature
      into steps; the spike doc is referenced by multiple tasks/flows.
- [x] Add guidelines: time-box and stay exploratory, a spike may conclude
      "not worth doing", do not write production code in a spike, keep the doc
      durable and self-contained so a future flow needs only the doc.
- [x] Verify the skill file matches sibling conventions (ASCII punctuation per
      AGENTS.md, `~72`-col prose, exact frontmatter shape) by diffing tone
      against plan/compound SKILL.md.

## Implementation log

- Wrote `home/modules/agents/skills/spike/SKILL.md` modeled on plan (produces
  tatr tasks) and compound (writes to a `docs/<kind>/` subfolder, created on
  demand). Six-step workflow: frame -> diverge -> converge -> write doc ->
  seed tasks -> report. Doc format has a `STATUS` of RECOMMENDED /
  INCONCLUSIVE / DROPPED so a negative spike is a first-class outcome.
- Verified wiring end to end rather than assuming: `nix build` of
  `homeConfigurations."alex".activationPackage` succeeds and the built
  `home-manager-files` output contains
  `.claude/skills/spike/SKILL.md -> .../hm_skills/spike/SKILL.md`. The
  `recursive = true` source needs no change for a new sibling dir.
- ASCII-only (grep for non-ASCII clean), prose wrapped to ~72 cols to match
  siblings.
- Decisions: no `docs/spike.md` design doc (only the sprout CLI has one, since
  it has real code); `docs/spikes/` is created by the skill on first use like
  compound does with `docs/retros/`, so no empty dir is committed.

## Notes

- Skills live in `home/modules/agents/skills/<name>/SKILL.md` and are linked
  into `~/.claude/skills` by `home/modules/agents/default.nix`
  (`recursive = true`), so a new folder needs no wiring change.
- Model the file closely on `plan/SKILL.md` (produces tatr tasks) and
  `compound/SKILL.md` (writes to a `docs/<kind>/` subfolder, creating it if
  absent). Both are the nearest precedents.
- `docs/` is where all project docs live; existing subfolders: `docs/retros/`.
  New research artifacts go under `docs/spikes/`. Follow compound's
  "create it if it does not exist" pattern rather than committing an empty dir.
- No CLI/code change; this is a documentation skill. No `docs/spike.md` design
  doc is needed (only the sprout CLI has one because it has real code).
