# Decision: Use typed tatr v2 records and transactional lifecycle commands

- DATE: 20260730-153122
- STATUS: ACCEPTED
- TASK: 20260730-153122
- TAGS: decision, tatr, flow, schema

## Context

The current workflow stores important state partly in the TASK header, partly
in free-form sections, and partly in sibling files. `tatr edit -s` can write a
state that `tatr check` rejects later. Epic relationships, dependencies,
claims, context selection, and lesson dispositions are prose conventions. The
user explicitly permits a breaking tatr change and wants existing task history
revalidated instead of preserving compatibility at the expense of the design.

## Decision

Introduce a typed v2 task schema with KIND, FLOW STEP, PLAN STATUS, PARENT, and
dependencies alongside STATUS, PRIORITY, and TAGS. Drive it through
transactional lifecycle/graph commands and task-kind-aware artifact checks.
Migrate and revalidate existing tatr records in the schema task, reject legacy
records afterward, then migrate nix.dotfiles when it adopts the released tatr
revision.

## Alternatives considered

- **Keep parsing free-form sections** - rejected because each skill must repeat
  spelling and sequencing rules that the tool can own.
- **Add commands but retain unrestricted `tatr edit -s`** - rejected because
  it leaves a trivial bypass around every guard.
- **Maintain permanent legacy parsing** - rejected because the user prefers a
  clean target model and accepts migration.

## Consequences

Tatr and both repositories gain one enforceable source for lifecycle and graph
state, smaller skills, and deterministic context selection. The migration is a
breaking repository-wide change, requires deliberate classification of
historical records, and requires publishing tatr before nix.dotfiles can update
its GitHub flake input.
