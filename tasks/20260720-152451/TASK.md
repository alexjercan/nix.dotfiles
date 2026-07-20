# Flow skill: step 1 creates an umbrella task with GOAL.md

- STATUS: IN_PROGRESS
- PRIORITY: 90
- TAGS: feature, skills

## Story

As a flow run, I want the goal pinned on disk at step 1, so an interrupted
flow really can be resumed from the files alone and Finish has an artifact to
verify against. Evidence: flow's own guideline claims file-only resumability,
but the goal and its done-definition lived only in conversation;
nova-protocol improvised release-tracker tasks to hold exactly this.

## Steps

- [x] flow SKILL.md step 1: create an umbrella tatr task (tag `goal`,
      priority 0) whose folder holds GOAL.md with: goal statement,
      done-definition (observable), landing scope, a Tasks list (updated as
      tasks land) and a Manual acceptance section (fed by DoD `manual:`
      items). The umbrella stays OPEN for the whole run.
- [x] flow SKILL.md step 3.7: after each land, tick the task in GOAL.md's
      Tasks list with a one-line status (like a spike's Fix record).
- [x] flow Finish: verify the delivered work against GOAL.md's
      done-definition, present the batched Manual acceptance list to the
      user, close the umbrella task, commit.
- [x] Add a short GOAL.md format block to the flow skill.
- [x] tatr SKILL.md sibling-records line gains GOAL.md; plan SKILL.md notes
      that under /flow the plan appends its tasks to the umbrella's Tasks
      list.

## Definition of Done

- flow SKILL.md creates, updates and closes the umbrella + GOAL.md at the
  named points and contains the format block (cmd: grep -n "GOAL.md" home/modules/agents/skills/flow/SKILL.md)
- tatr and plan skills cross-reference it (cmd: grep -n "GOAL.md" home/modules/agents/skills/tatr/SKILL.md home/modules/agents/skills/plan/SKILL.md)
- manual: this flow's own GOAL.md matches the prescribed format (reconcile
  both ways if review disagrees)

## Notes

- This flow dogfoods the artifact: the umbrella GOAL.md exists before this
  task is implemented; align the format in whichever direction review favors.
