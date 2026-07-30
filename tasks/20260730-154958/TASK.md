# Add conditional parallel planning and review lanes

- STATUS: OPEN
- PRIORITY: 65
- TAGS: feature,skills,flow,parallel,review

## Flow State

- FLOW STEP: PLANNING

## Story

As a flow user, I want bounded independent planning and review lanes only when
risk or uncertainty warrants them, so difficult work gains fresh perspectives
without paying parallel context cost on ordinary tasks.

## Steps

- [ ] Define deterministic lane-selection rules: one planner/reviewer for
      ordinary work; parallel planning for load-bearing forks, independent
      domains, over-context Epics, or explicit requests; parallel review for
      security/auth, secrets, persistence/migrations, concurrency, public APIs,
      shared infrastructure, or broad contracts.
- [ ] Add a parallel-planning reference that sends the same read-only tatr
      context packet to independent minimal-end-to-end, deep-interface, and
      migration/risk lanes with bounded outputs.
- [ ] Synthesize one selected plan and one DECISION.md; keep candidate scratch
      ephemeral and persist only concise rejected-alternative rationale.
- [ ] Extend review so high-risk work runs independent behavior/proofs,
      correctness/security/concurrency, and design/standards/docs lanes as
      applicable.
- [ ] Keep the local review contract: the primary reviewer re-verifies,
      deduplicates, assigns canonical severities, and writes one REVIEW.md
      round and one ship verdict.
- [ ] Add conflict/resource rules so parallel read-only lanes may share a
      checkout while writer tasks use distinct sprout worktrees and
      build-output-mutating checks are serialized.
- [ ] Add fixtures for ordinary, architectural, security, and cross-domain
      tasks, bounded lane responses, independent context, synthesis, and
      duplicate/conflicting findings.
- [ ] Document lane selection and output limits in the plan/review conditional
      references rather than the core flow body.

## Definition of Done

- Ordinary fixtures use one lane and high-risk fixtures select only applicable
  independent lanes (test: `parallel_lane_selection`).
- Planning candidates receive identical source context without each other's
  conclusions and each stays within its output budget
  (test: `parallel_plan_isolation`).
- Only the chosen plan and decision rationale persist
  (test: `parallel_plan_synthesis`).
- Parallel review produces one deduplicated severity-ranked REVIEW.md and one
  verdict after primary verification (test: `parallel_review_aggregation`).
- Conflicting writers/build checks are isolated or serialized
  (test: `parallel_resource_guards`).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).

## Notes

- Parent Epic: 20260730-153122.
- Depends on tatr: 20260730-154740, 20260730-154745.
- Depends on nix.dotfiles: 20260730-142533.
