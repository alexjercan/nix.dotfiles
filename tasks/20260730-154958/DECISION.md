# Decision: Prove lanes structurally, one lanes reference per phase

- DATE: 20260731-080915
- STATUS: ACCEPTED
- TASK: 20260730-154958
- TAGS: skills, flow, parallel, review

## Context

Parallel planning and review lanes are agent BEHAVIOR: several independent
contexts read the same packet, answer within a cap, and one primary synthesizes
them. The suite's gate (`home/modules/agents/skills/check.sh`) is a
deterministic reader of the skill TEXTS. It can see that a rule is stated, is
reachable only on its branch, and fits its budget; it cannot see a model obey
it. 20260730-142533 and 20260730-142540 already met this same wall and chose
structural proof plus a manual acceptance item, and the fixtures under
`fixtures/` exist because of that choice.

Two structural constraints shape where the rules can live. A conditional
reference belongs to ONE skill directory and is resolved as
`<skill>/<name>.md`, so no file can be shared between `plan` and `review`. And
`duplicated-paragraph` fails any prose paragraph of 12+ words appearing
verbatim in two files, so a shared rule cannot simply be pasted into both.

## Decision

Lane behavior is specified in two per-phase conditional references,
`plan/lanes.md` and `review/lanes.md`, and proved structurally: `content`
fixtures assert each file still states its own rules, and `disclosure` fixtures
assert the `lanes.md` pointer fires on high-risk branches and not on ordinary
work. The live behavior - lanes actually staying inside their caps, the
primary's round actually reading as one deduplicated review - is a `manual:`
Definition of Done item, reported as pending rather than self-ticked.

Each lanes file states its own phase's resource rule in its own words:
planning lanes are read-only and never sprout; review lanes read one worktree
read-only and let the primary run the build-output-mutating checks once. The
worktree mechanics themselves stay owned by `sprout`.

## Alternatives considered

- **A lane-executing harness.** Have the gate spawn real agents, hand them the
  packet, and assert on their responses. This is the only thing that would
  prove obedience rather than shape. It loses because the gate runs inside
  `nix flake check` with no network and no credentials, and because its
  verdicts would be non-deterministic - a check that fails on a model's mood is
  worse than an honest manual item. Same reasoning as 20260730-142533.

- **One shared `lanes.md`.** A single file both skills point at would state the
  packet, cap and resource rules once. It loses on the reference graph: a
  pointer resolves inside the skill's own directory, so `plan` cannot reach
  `review/lanes.md` without either a symlink (two files on disk, and the gate
  would then see the same paragraphs twice) or a cross-skill pointer form that
  does not exist.

- **Put the rules in the SKILL.md bodies.** No new files, no disclosure cases
  needed. It loses because both bodies would carry lane prose on every ordinary
  run, which is exactly the context cost the Story exists to avoid, and because
  the Epic's own scoping asks for conditional references.

- **Do nothing.** Deferring costs the Epic its fifth Done Means item, and
  leaves the suite with the round-1 reviewer as its only shape for independent
  perspective - the shape that four ledger occurrences of
  `out-of-context-review-pass` say is worth extending, not the one to stop at.

## Consequences

- The proofs are cheap, deterministic and run under `nix flake check`, and a
  reference that keeps its pointer while losing its rule fails `content`
  immediately.
- Nothing in the repository proves a lane ran, stayed inside its cap, or that
  the primary deduplicated rather than concatenated. That gap is written into
  the Definition of Done as a `manual:` item and joins the Epic's existing
  manual acceptance list; a reader who mistakes the green gate for evidence of
  behavior will be wrong.
- The shared rules are stated twice, once per phase, in different words. A
  future change to the packet or the cap must be applied in both files, and the
  gate will not catch a drift that leaves both files individually valid.
- The `lanes.md` pointer conditions become load-bearing vocabulary: their
  wording is what the ordinary-work disclosure cases test against, so rewording
  a condition can turn the ordinary-work proof red. That is intended.
- A `forbids:` case guards WORDS, not reachability. It fails when a condition
  starts naming ordinary or routine work, and it stays green when a condition
  is widened in any other phrasing - appending "or any planning task at all"
  keeps the whole gate clean. Nothing in the repository bounds how permissive
  a lane trigger becomes; that is the same live-behavior gap the `manual:`
  item covers, and the criterion is worded as the word guard it is.
