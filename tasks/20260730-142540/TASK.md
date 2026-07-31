# Add tatr-native wayfinding, web research, and retained prototypes

- STATUS: OPEN
- PRIORITY: 70
- TAGS: feature, skills, flow, spike
- KIND: STORY
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED
- PARENT: 20260730-153122

## Story

As the flow-suite maintainer, I want large or uncertain work to use a
tatr-backed Epic index, cited research, and retained executable prototypes, so
each Story fits one context and decisions are based on evidence.

## Steps

All paths are relative to `home/modules/agents/skills/`.

- [ ] Add `--fixture <name>` to `check.sh`: run only the fixture cases whose
      `name:` matches, print `fixture <name>: ok` when clean, and exit 2 with a
      message when no case matches. Route it through `fixtures/run.sh`
      (`run_fixtures` gains an optional name filter). No new `fail` slug, so
      `RULES` is unchanged by this step. Each DoD proof below is then a real
      runnable command.
- [ ] Add the `content` fixture kind under `fixtures/content/`, handled in
      `fixtures/run.sh` beside `disclosure`/`invocation`/`output`. A case names
      `skill:`, a `file:` inside that skill, an optional `section:` heading, and
      a comma-separated `requires:` list of substrings that must appear there;
      an optional `forbids:` list must not. New rules
      `missing-content-element`, `forbidden-content-element` and the existing
      `bad-fixture` (unknown skill or file) go in `check.sh`'s `RULES`, with one
      sabotage case per new rule in `fixtures/selftest.sh`.
- [ ] Write the five failing fixtures FIRST, then make them pass:
      `fixtures/disclosure/wayfinder_context_index.fixture`,
      `fixtures/disclosure/wayfinder_web_research.fixture`,
      `fixtures/content/prototype_location_resolution.fixture`,
      `fixtures/content/retained_prototype_smoke.fixture`,
      `fixtures/content/spike_decision_routing.fixture`. Confirm each is red for
      the right reason before writing the prose it asserts.
- [ ] Extend `flow/epic.md` into the Epic index (the "context map"): a
      `## Destination`, `## Decisions`, `## Frontier`, `## Fog` and
      `## Out of Scope` section list, resume via `tatr frontier <epic-id>`, and
      an explicit rule that a wayfinding run opens the index plus ONE selected
      Story or discovery task, never every child body. Confirm first that
      `tatr check` tolerates sections beyond its required `## Done Means` and
      `## Child Tasks` (run it against a scratch Epic carrying a `## Fog`
      section), then write the template. Stay inside the 1000-word reference
      budget.
- [ ] Rewrite `spike/SKILL.md` as a concise mode router: frame, then route to
      research, logic prototype, UI prototype, or mixed evidence. Modes get two
      conditional references, not four - `research.md` and `prototype.md` -
      because logic and UI prototypes share every storage and retention rule
      and a third file would trip `duplicated-paragraph`. The router's
      `## Load on demand` conditions must name all four mode words, and mixed
      evidence must reach both files. Body stays at or under 800 words.
- [ ] Write `spike/research.md`: browse when the question turns on external or
      current facts, prefer primary sources over summaries, record cited
      findings in the owning task folder, and put only a one-line answer plus a
      pointer in the Epic index. At or under 1000 words.
- [ ] Write `spike/prototype.md`: the storage resolution order (AGENTS.md
      `## Agent workflow` cache, then an established repo-native
      `examples/`/`scripts/`/`demos/` convention, then `tasks/<id>/prototype/`),
      ask the user only when more than one placement has meaningful
      consequences and cache the answer back into AGENTS.md; a repo-native
      prototype is a supported artifact with a documented run command covered
      by a build/smoke check, a task-local prototype is retained evidence
      recording its command, observations, verdict and limitations; and the
      routing rule that an ACCEPTED result enters normal plan/work/review via
      `DECISION.md` and planned Stories while a DROPPED spike seeds none and
      exploratory code is never presented as production surface. At or under
      1000 words.
- [ ] Sweep the doc surface: update `README.md` (the new `content` fixture
      kind, `--fixture`, and the spike mode router) and the lifecycle
      cross-references in `flow/SKILL.md` and `plan/SKILL.md` that name spike
      or the Epic index. Grep `--exclude-dir=tasks` for stale descriptions of
      the old single-file spike.
- [ ] Record the structural-proof boundary on the parent Epic: append the
      manual acceptance item from this task's `DECISION.md` to
      `tasks/20260730-153122/TASK.md` `## Manual Acceptance`.

## Definition of Done

- A wayfinding run loads the Epic index and one selected child, not every
  Story body
  (cmd: `bash home/modules/agents/skills/check.sh --fixture wayfinder_context_index`).
- Web research records primary-source citations and a bounded Epic answer
  (cmd: `bash home/modules/agents/skills/check.sh --fixture wayfinder_web_research`).
- The recorded storage resolution order names the AGENTS.md cache, the
  repo-native convention, the task folder, and the ask-once-then-cache rule
  (cmd: `bash home/modules/agents/skills/check.sh --fixture prototype_location_resolution`).
- A retained prototype records its run command, observations, verdict and
  limitations, so it stays runnable after the spike closes
  (cmd: `bash home/modules/agents/skills/check.sh --fixture retained_prototype_smoke`).
- Accepted decisions seed planned work while DROPPED spikes seed none
  (cmd: `bash home/modules/agents/skills/check.sh --fixture spike_decision_routing`).
- Every rule the gate can report still has a sabotage case proving it fires,
  including the two new content rules
  (cmd: `bash home/modules/agents/skills/check.sh --self-test`).
- The whole suite and the repository conform
  (cmd: `bash home/modules/agents/skills/check.sh && tatr check --ledger LESSONS.md && nix flake check --no-build`).
- A real spike run records a prototype that still runs from its recorded
  command afterwards - the gate proves the record's shape, never that the
  command works (manual: tracked on the parent Epic's Manual Acceptance list).

## Notes

- Parent Epic: 20260730-153122.
- Spike: tasks/20260730-142052/SPIKE.md
- Refinement: tasks/20260730-142540/NOTES.md
- Decision: tasks/20260730-142540/DECISION.md - all five criteria are proved
  structurally over the skill texts; the gate executes nothing.
- Depends on tatr: 20260730-153325, 20260730-154657, 20260730-154740.
- Depends on nix.dotfiles: 20260730-142533.
- Discovered at plan time: `check.sh` reports fixture failures only, printing
  nothing per passing case, so a per-criterion proof was impossible before the
  `--fixture` step. That is why it leads the plan.
- Budget headroom on the base branch: `flow/epic.md` 429 words (limit 1000),
  `spike/SKILL.md` body 629 (limit 800), flow-family descriptions 179 of 200.
  Rewriting spike's body must not grow its description.
- Assumption to double-check: `tatr check` accepts an Epic TASK.md carrying
  sections it does not require. Step 4 verifies this before the template is
  written rather than assuming it.
- Kept as ONE task: the fixture kind, the fixtures and the prose they assert
  are not independently committable without a shim (a runner with no cases, or
  cases with no runner).
