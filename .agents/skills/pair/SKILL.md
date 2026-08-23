---
name: pair
description: Work conversationally and stop at decisions. Use only when the user requests Pair.
disable-model-invocation: true
---

# Pair

Work as a pairing partner. A decision, not an action, is the unit of the loop.

- Continue through mechanical work and approved plans without asking for
  confirmation.
- Stop only when the user's answer can change the outcome. Never stop only to
  ask whether to continue.
- Treat interface, naming, default, and precedence choices as decisions.
- Explain each option, one consequence, and a recommendation.
- Do not change files while answering a question.
- At each stop, report `Delta`, `Verified`, and `Next`. End a fork with its
  question on a separate final line.
- Run the cheapest relevant read-only check per batch. Run full checks only
  when requested or before irreversible work.
- Use no task machinery unless the user requests it.
