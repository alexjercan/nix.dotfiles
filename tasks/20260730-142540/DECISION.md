# Decision: Prove retained prototypes structurally, not by executing them

- DATE: 20260731-071025
- STATUS: ACCEPTED
- TASK: 20260730-142540
- TAGS: skills, fixtures, prototypes

## Context

The task's Definition of Done names a `retained_prototype_smoke` proof: "UI
and logic prototypes remain runnable from their recorded command after the
spike closes". The conformance gate this suite already has
(`home/modules/agents/skills/check.sh` plus `fixtures/`) inspects the skill
TEXTS only - budgets, the conditional-reference graph, the invocation policy,
the declared output contracts. It executes nothing. A literal reading of that
proof would require shipping runnable prototype artifacts in this repository
and running them from the gate, which the repository's own `## Agent workflow`
cache contradicts: "Examples and prototypes: none retained."

The two readings are mutually exclusive in what `check.sh` becomes: a text
inspector, or a harness that executes fixture code inside `nix flake check`.

## Decision

Prove all five of this task's criteria structurally, over the skill texts.
`retained_prototype_smoke` becomes a fixture asserting that the retained
prototype record template names its run command, observations, verdict and
limitations, and that the spike branch that writes it is reachable only on its
stated condition. The gate continues to execute nothing.

"A real prototype recorded by a real spike still runs afterwards" moves to the
parent Epic's `## Manual Acceptance` list, alongside the equivalent item from
20260730-142533.

## Alternatives considered

- **Executing gate.** Ship a task-local HTML prototype and an `examples/`-style
  script as fixtures and have `check.sh` run each recorded command. It would
  prove retention end to end, but it puts runtime dependencies and executed
  fixture code inside `nix flake check`, and it proves that OUR fixture runs,
  not that a prototype a future spike writes will. Rejected: cost in the gate,
  little transfer to the property we care about.

## Consequences

- The gate stays deterministic, dependency-free and fast.
- It continues to prove SHAPE, never obedience - the same boundary
  20260730-142533 drew. The Epic carries the behavioral half.
- If retained prototypes later drift (a recorded command that never worked),
  no automated check will catch it. The manual acceptance item is the only
  guard, and it is stated as such rather than implied.
