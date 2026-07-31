# Add tatr-native wayfinding, web research, and retained prototypes

- STATUS: CLOSED
- PRIORITY: 70
- TAGS: feature, skills, flow, spike
- KIND: STORY
- FLOW STEP: DONE
- PLAN STATUS: APPROVED
- PARENT: 20260730-153122

## Story

As the flow-suite maintainer, I want large or uncertain work to use a
tatr-backed Epic index, cited research, and retained executable prototypes, so
each Story fits one context and decisions are based on evidence.

## Steps

All paths are relative to `home/modules/agents/skills/`.

- [x] Add `--fixture <name>` to `check.sh`: run only the fixture cases whose
      `name:` matches, print `fixture <name>: ok` when clean, and exit 2 with a
      message when no case matches. Route it through `fixtures/run.sh`
      (`run_fixtures` gains an optional name filter). No new `fail` slug, so
      `RULES` is unchanged by this step. Each DoD proof below is then a real
      runnable command.
- [x] Add the `content` fixture kind under `fixtures/content/`, handled in
      `fixtures/run.sh` beside `disclosure`/`invocation`/`output`. A case names
      `skill:`, a `file:` inside that skill, an optional `section:` heading, and
      a comma-separated `requires:` list of substrings that must appear there;
      an optional `forbids:` list must not. New rules
      `missing-content-element`, `forbidden-content-element` and the existing
      `bad-fixture` (unknown skill or file) go in `check.sh`'s `RULES`, with one
      sabotage case per new rule in `fixtures/selftest.sh`.
- [x] Write the five failing fixtures FIRST, then make them pass. All five are
      `fixtures/content/` cases - `wayfinder_context_index`,
      `wayfinder_web_research`, `prototype_location_resolution`,
      `retained_prototype_smoke`, `spike_decision_routing` - because each
      criterion is about what a file STATES, and the disclosure half of the
      wayfinding criterion is already covered by `flow-epic.fixture`. The three
      new reference files still need disclosure cases of their own to satisfy
      `no-disclosure-fixture`: `spike-research`, `spike-prototype` and
      `spike-mixed` (mixed evidence reaches both). Confirm each is red for the
      right reason before writing the prose it asserts.
- [x] Extend `flow/epic.md` into the Epic index (the "context map"): a
      `## Destination`, `## Decisions`, `## Frontier`, `## Fog` and
      `## Out of Scope` section list, resume via `tatr frontier <epic-id>`, and
      an explicit rule that a wayfinding run opens the index plus ONE selected
      Story or discovery task, never every child body. Confirm first that
      `tatr check` tolerates sections beyond its required `## Done Means` and
      `## Child Tasks` (run it against a scratch Epic carrying a `## Fog`
      section), then write the template. Stay inside the 1000-word reference
      budget.
- [x] Rewrite `spike/SKILL.md` as a concise mode router: frame, then route to
      research, logic prototype, UI prototype, or mixed evidence. Modes get two
      conditional references, not four - `research.md` and `prototype.md` -
      because logic and UI prototypes share every storage and retention rule
      and a third file would trip `duplicated-paragraph`. The router's
      `## Load on demand` conditions must name all four mode words, and mixed
      evidence must reach both files. Body stays at or under 800 words.
- [x] Write `spike/research.md`: browse when the question turns on external or
      current facts, prefer primary sources over summaries, record cited
      findings in the owning task folder, and put only a one-line answer plus a
      pointer in the Epic index. At or under 1000 words.
- [x] Write `spike/prototype.md`: the storage resolution order (AGENTS.md
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
- [x] Sweep the doc surface: update `README.md` (the new `content` fixture
      kind, `--fixture`, and the spike mode router) and the lifecycle
      cross-references in `flow/SKILL.md` and `plan/SKILL.md` that name spike
      or the Epic index. Grep `--exclude-dir=tasks` for stale descriptions of
      the old single-file spike.
- [x] Record the structural-proof boundary on the parent Epic: append the
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

## Close-out

At the round-1 fix commit 0343f8b, `git diff ecd57cf..0343f8b --shortstat`
reports 20 files changed, 600 insertions, 102 deletions. The round-2 fix and
the records committed after it are not in that number.

### What changed and why

- `check.sh --fixture <case>` runs one fixture and prints `ok`. The gate only
  ever printed FINDINGS, so a passing case was invisible and no single
  criterion could be named as a `cmd:` proof. Its dispatch sits above the rule
  sections and below the helpers, so a per-criterion proof cannot go red for a
  finding somewhere else in the suite.
- A fourth fixture kind, `content/`. The three existing kinds prove a
  reference is reachable, conditionally guarded and inside its budget - all of
  which a file that kept its pointer and lost its rule still passes. A content
  case names the file, optionally one `##` section, and the `requires:` /
  `forbids:` substrings the rule is made of. Two new rules,
  `missing-content-element` and `forbidden-content-element`, each with a
  sabotage case written before the rule.
- `section_of` strips a leading step number, so `## 5. Route the result` is
  found by `Route the result`. Renumbering a workflow would otherwise orphan
  the fixture into a `bad-fixture` that reads like a missing section.
- `flow/epic.md` gained `## The Epic index`: Destination, Decisions, Frontier,
  Fog, Out of Scope, and the rule that a wayfinding run reads the index plus
  ONE Story. `## Fog` and `## Out of Scope` were added to the container
  template; `tatr check` was confirmed to accept them (scratch tasks tree,
  exit 0) before the template was written.
- `spike/SKILL.md` became a mode router with a `## 5. Route the result`
  section, over two references - `spike/research.md` (primary sources, cited
  findings in the owning task folder, one-line answer in the Epic index) and
  `spike/prototype.md` (storage resolution order, supported artifact vs
  retained evidence, no accidental graduation to production).

### Alternatives considered

- Four references, one per mode, as the Steps first suggested. Logic and UI
  prototypes share every storage and retention rule, so the third and fourth
  files would have been copies - and `duplicated-paragraph` would have said
  so. Two references with a router naming four modes carries the same
  distinction without the duplication; `spike-mixed.fixture` proves mixed
  evidence reaches both.
- Making `wayfinder_context_index` a disclosure case, as planned. The
  disclosure half is already `flow-epic.fixture`; the criterion is about what
  the index SAYS, so it became a content case. Step 3 was amended in place.

### Difficulties

`nix flake check` failed in the worktree with
`error: path '7mbv708...-modules' is not valid` while master passed. Not a
skills problem: `home/alex/default.nix` had `modulesPath = ../modules`, and
every use interpolates it into a string, so the path literal was coerced into
a floating `<hash>-modules` store root with no GC root - LESSONS.md
`flake-path-literal-string-coercion`, which `flake/home-configurations.nix`
already fixed for `../home` and this file never did. Diagnosed by bisecting
(a clean base worktree passed, so it was content-dependent, and `nix store
add-path home/modules` made the failure disappear), then fixed with
`"${inputs.self}/home/modules"` and verified by DELETING the floating path
first: the check now passes without recreating it. Master passes today only
because its copy has not been GC'd yet, so this was latent, not new.

That one-line fix is outside the task's stated scope. It is in this diff
because the task's own `nix flake check --no-build` proof cannot be green
without it, and a proof that needs a manual `nix store add-path` first is not
a proof.

### Self-reflection

The plan's fixture-location guess (disclosure for two of the five) was made
before looking hard at what each criterion actually asserts; one step needed
amending during work. Reading the criterion and asking "is this about
reachability or about content?" would have caught it at plan time - the same
shape as `read-the-callee-not-the-name`, applied to a proof rather than a
function.

`retained_prototype_smoke` also deserves naming honestly: it proves the
RECORD names a command, observations, a verdict and its limitations. It does
not prove the command runs. That gap is the Epic's manual acceptance item, and
the fixture name still sounds like a smoke test - a reader could take the
green as more than it is.
