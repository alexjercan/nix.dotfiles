---
name: knowledge
description: Manage durable lessons in the local knowledge store. Use for /knowledge.
disable-model-invocation: true
---

# Knowledge

Manage durable lessons with the `knowledge` CLI. Run only on explicit user
request.

## CLI

```bash
knowledge search "<terms>"
knowledge read <type>/<slug>
knowledge create <type>/<slug> --tag <tag> --body "<lesson>"
knowledge update <type>/<slug> [--tag <tag>] [--body "<lesson>"]
knowledge delete <type>/<slug>
knowledge list
knowledge check
```

`--body` accepts text, `-`, or `@PATH`. Use stable kebab-case IDs and tags.

## Rules

* Preserve only lessons that apply beyond one task. Zero writes is valid.
* Search before creating.
* Update only when the durable conclusion is the same; otherwise create a
  distinct lesson.
* Delete only when evidence proves a lesson wrong or obsolete.
* Do not edit store files directly. Run `knowledge check` after mutations.
* Report affected IDs or that no durable lesson was found.
