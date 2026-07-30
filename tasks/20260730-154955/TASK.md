# Integrate guarded flow lifecycle and lesson decisions

- STATUS: OPEN
- PRIORITY: 75
- TAGS: feature, skills, flow, lessons
- KIND: STORY
- FLOW STEP: PLANNING
- PLAN STATUS: DRAFT
- PARENT: 20260730-153122

## Story

As a flow user, I want the orchestrator and phase skills to use tatr's
transactional lifecycle and mandatory lesson decision gate, so prompt prose
cannot bypass plan, review, retro, close, or promotion requirements.

## Steps

- [ ] Replace direct TASK.md flow-marker/status edits with the new tatr plan,
      start, advance, review-loop, and close commands across flow, plan, work,
      review, compound, lessons, and the tatr skill surface.
- [ ] Keep work tasks IN_PROGRESS through implementation, review, and
      compound; close atomically only after APPROVE, RETRO, and DONE.
- [ ] Update resume behavior to derive the next phase from structured tatr
      state and request only the phase context packet.
- [ ] Change compound so it records/counts lessons but never promotes a lesson
      directly into a tool, template, AGENTS.md, or skill.
- [ ] At Pending promotion, use the platform user-input mechanism when
      available or ask directly for PROMOTE, DEFER, RETIRE, or ABSORBED; record
      the disposition through tatr before Finish can pass.
- [ ] Route PROMOTE to a normal planned tatr task and require the usual
      out-of-context review before the target change lands.
- [ ] Add flow fixtures for legal transitions, review fixes, interrupted
      resume, rejected bypasses, each lesson disposition, and a promoted
      lesson's reviewed child task.
- [ ] Update AGENTS.md guidance and all affected skill cross-references.

## Definition of Done

- No live flow-family skill directly edits STATUS, FLOW STEP, PLAN STATUS, or
  lesson disposition text (test: `flow_no_direct_state_edits`).
- Flow cannot enter work without approval or finish without review and retro
  (test: `flow_transactional_lifecycle`).
- An interrupted flow resumes from tatr state with only its phase packet
  (test: `flow_phase_resume`).
- A threshold lesson blocks Finish until the user disposition is recorded
  (test: `flow_lesson_decision_gate`).
- PROMOTE creates/references a reviewed task; DEFER/RETIRE/ABSORBED cache the
  answer and do not ask again (test: `flow_lesson_dispositions`).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).

## Notes

- Parent Epic: 20260730-153122.
- Depends on tatr: 20260730-154657, 20260730-154745, 20260730-154756.
- Depends on nix.dotfiles: 20260730-142533.
