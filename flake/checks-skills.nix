# Deployment check for the agent skills.
#
# `home/modules/agents/skills/check.sh` proves the skill TEXTS conform - budgets,
# reference graph, invocation policy, output contracts. It says nothing about
# whether those files reach an agent, nor about whether a reference still states
# the rule it carries; the first is this check's job, the second is review's.
# The two halves fail differently: a skill can be perfectly written and still
# invisible because the home-manager module never listed it, or because a
# reference file beside its SKILL.md was left out of the deployed tree.
#
# The seam is `localSkills` in home/modules/agents/default.nix: an explicit list
# that must stay in step with the directories on disk. Adding a skill folder and
# forgetting the list leaves a skill nobody ever loads, and nothing else in the
# build notices.
{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    home = inputs.self.homeConfigurations.alex.config;
    source = "${inputs.self}/home/modules/agents/skills";
    knowledgeSource = inputs.agent-knowledge.skills.knowledge;
    knowledgePackage = inputs.agent-knowledge.packages.${pkgs.system}.knowledge;

    # What the module actually deploys, read back out of the evaluated home
    # config rather than re-derived from the list - so this check cannot agree
    # with a list that the module stopped using.
    deployedFor = root:
      builtins.filter (n: n != null) (map (
          path: let
            m = builtins.match "${root}/([^/]+)" path;
          in
            if m == null
            then null
            else builtins.head m
        )
        (builtins.attrNames home.home.file));

    claudeSkills = deployedFor ".claude/skills";
    agentsSkills = deployedFor ".agents/skills";
  in {
    # The text half of the gate, wired into `nix flake check` so the budgets
    # and the reference graph cannot rot between hand runs. It is pure bash
    # plus coreutils and GNU grep, so it needs no repository and no network.
    checks.skills-conformance =
      pkgs.runCommand "skills-conformance" {
        inherit source;
        nativeBuildInputs = [pkgs.bash pkgs.gnugrep pkgs.coreutils pkgs.gawk pkgs.gnused];
      } ''
        cp -r "$source" skills
        chmod -R u+w skills
        bash skills/check.sh
        touch $out
      '';

    checks.skills-deployment-tree =
      pkgs.runCommand "skills-deployment-tree" {
        inherit source;
        claude = builtins.toString claudeSkills;
        agents = builtins.toString agentsSkills;
        # The activation script feeds codex real-file copies, because its
        # scanner ignores a symlinked SKILL.md. If a skill is deployed to
        # ~/.claude/skills but never copied into ~/.codex/skills, it exists for
        # one tool and not the other - exactly the drift this check exists for.
        codexScript = home.home.activation.codexSkills.data;
        # The deployed ENTRIES, not just their names: `recursive` decides
        # whether a skill lands as a per-file tree (so an agent can drop its
        # own files alongside) or as one opaque directory symlink, and `source`
        # decides which directory it actually points at. Both are silent
        # failures - the build succeeds either way.
        deployedDetail = builtins.toJSON (builtins.listToAttrs (map (
            path: {
              name = path;
              value = {
                inherit (home.home.file.${path}) recursive;
                source = builtins.toString home.home.file.${path}.source;
              };
            }
          )
          (builtins.filter
            (p: builtins.match "\\.(claude|agents)/skills/.+" p != null)
            (builtins.attrNames home.home.file))));
        nativeBuildInputs = [pkgs.jq];
      } ''
        fail() { echo "skills-deployment-tree: $1" >&2; exit 1; }

        # 1. Every directory holding a SKILL.md is deployed, and every entry
        #    deployed FROM this tree names a real skill directory.
        for d in "$source"/*/; do
          name="$(basename "$d")"
          [ -f "$d/SKILL.md" ] || continue
          echo "$name" >> on-disk
        done
        [ -s on-disk ] || fail "no skill directories found under $source"
        sort -o on-disk on-disk

        printf '%s\n' $claude | sort > deployed-claude
        printf '%s\n' $agents | sort > deployed-agents

        # The tatr skill comes from its own flake input, so it is deployed
        # without living in this source tree. Compare only the local ones.
        comm -23 on-disk deployed-claude > missing-claude
        comm -23 on-disk deployed-agents > missing-agents
        if [ -s missing-claude ]; then
          fail "skills present on disk but not deployed to ~/.claude/skills: $(tr '\n' ' ' < missing-claude)"
        fi
        if [ -s missing-agents ]; then
          fail "skills present on disk but not deployed to ~/.agents/skills: $(tr '\n' ' ' < missing-agents)"
        fi

        # The reverse direction. Until this task it was covered only by a guard
        # naming `fixtures/` specifically, which went with the fixtures - so a
        # typo in `localSkills`, or `check.sh` itself listed as a skill, built
        # green.
        #
        # The test is on-disk PRESENCE, not the entry's source path: the module
        # deploys `./skills + "/<name>"`, which nix copies to its own store path
        # per skill, so nothing in `deployedDetail` still points inside this
        # tree and a source-prefix filter would match nothing at all. A name
        # with no path here is a tool-owned skill (tatr) and is legitimate; a
        # name whose path EXISTS but is not a directory holding a SKILL.md is
        # the drift.
        while IFS= read -r name; do
          [ -n "$name" ] || continue
          if [ -e "$source/$name" ] && [ ! -f "$source/$name/SKILL.md" ]; then
            fail "$name is deployed but $source/$name is not a skill directory"
          fi
        done < deployed-claude

        printf '%s' "$deployedDetail" > detail.json

        # 2. Each deployed entry points at ITS OWN source directory and is
        #    recursive. A `recursive = false` entry becomes a single directory
        #    symlink, which the agent tools can no longer merge their own
        #    skills into; a mismatched `source` deploys one skill's files under
        #    another skill's name. Both build cleanly.
        for root in .claude/skills .agents/skills; do
          while IFS= read -r name; do
            entry="$(jq -r --arg k "$root/$name" '.[$k] // empty' detail.json)"
            [ -n "$entry" ] || continue   # external skills are checked by name only
            [ "$(printf '%s' "$entry" | jq -r .recursive)" = true ] ||
              fail "$root/$name is not deployed recursively"
            case "$(printf '%s' "$entry" | jq -r .source)" in
              */"$name") ;;
              *) fail "$root/$name deploys from $(printf '%s' "$entry" | jq -r .source)" ;;
            esac
          done < on-disk
        done

        # 3. Each skill's WHOLE tree is present at its source: the body, its
        #    conditional references, and the codex metadata file. The module
        #    deploys each skill as one recursive entry, so a file missing here
        #    is a file missing from every agent tool.
        while IFS= read -r name; do
          d="$source/$name"
          [ -f "$d/SKILL.md" ] || fail "$name has no SKILL.md"
          [ -f "$d/agents/openai.yaml" ] || fail "$name has no agents/openai.yaml"
          # Every arrow pointer in the body must resolve to a file that ships
          # beside it. A reference that only exists in the author's checkout is
          # a broken load at runtime, not a build error.
          grep -oE -- '->[^`]*`[a-z][a-z0-9-]*\.md`' "$d/SKILL.md" 2>/dev/null |
            grep -oE '`[a-z][a-z0-9-]*\.md`' | tr -d '`' | sort -u > refs || true
          while IFS= read -r ref; do
            [ -n "$ref" ] || continue
            [ -f "$d/$ref" ] || fail "$name/SKILL.md points at $ref, which is not in the deployed tree"
          done < refs
        done < on-disk

        # 4. Codex gets every one of them too.
        while IFS= read -r name; do
          case "$codexScript" in
            *"\$codexSkills/$name"*) ;;
            *) fail "the codex activation script never copies '$name'" ;;
          esac
        done < on-disk

        touch $out
      '';

    checks.knowledge-deployment-tree =
      pkgs.runCommand "knowledge-deployment-tree" {
        nativeBuildInputs = [pkgs.jq];
        knowledgeBin = "${knowledgePackage}/bin/knowledge";
        packageInstalled =
          if lib.elem knowledgePackage home.home.packages
          then "yes"
          else "no";
        knowledgeSourcePath = knowledgeSource;
        knowledgeSource = builtins.toString knowledgeSource;
        codexScript = home.home.activation.codexSkills.data;
        deployedDetail = builtins.toJSON (builtins.listToAttrs (map (
            path: {
              name = path;
              value = {
                inherit (home.home.file.${path}) recursive;
                source = builtins.toString home.home.file.${path}.source;
              };
            }
          )
          [
            ".claude/skills/knowledge"
            ".agents/skills/knowledge"
          ]));
      } ''
        fail() { echo "knowledge-deployment-tree: $1" >&2; exit 1; }

        [ "$packageInstalled" = yes ] || fail "knowledge package is not installed"
        [ -x "$knowledgeBin" ] || fail "knowledge executable missing: $knowledgeBin"
        [ -f "$knowledgeSourcePath/SKILL.md" ] || fail "external skill has no SKILL.md"
        [ -f "$knowledgeSourcePath/agents/openai.yaml" ] ||
          fail "external skill has no agents/openai.yaml"

        printf '%s' "$deployedDetail" > detail.json
        for root in .claude/skills .agents/skills; do
          entry="$(jq -r --arg k "$root/knowledge" '.[$k] // empty' detail.json)"
          [ -n "$entry" ] || fail "$root/knowledge is not deployed"
          [ "$(printf '%s' "$entry" | jq -r .recursive)" = true ] ||
            fail "$root/knowledge is not recursive"
          [ "$(printf '%s' "$entry" | jq -r .source)" = "$knowledgeSource" ] ||
            fail "$root/knowledge does not use the external skill source"
        done

        case "$codexScript" in
          *"\$codexSkills/knowledge"*) ;;
          *) fail "codex activation script never copies knowledge" ;;
        esac

        touch $out
      '';

    checks.compound_observation_failure_is_non_blocking =
      pkgs.runCommand "compound-observation-failure-is-non-blocking" {
        compound = "${source}/compound/SKILL.md";
        nativeBuildInputs = [pkgs.gnugrep];
      } ''
        fail() { echo "compound-observation-failure-is-non-blocking: $1" >&2; exit 1; }

        grep -q 'AGENTS.md reflection and knowledge instructions' "$compound" ||
          fail "compound does not defer reflection policy to AGENTS.md"
        ! grep -nE 'LESSONS\.md|tatr ledger|--ledger|Pending promotions|PROMOTE|DEFER|RETIRE|ABSORBED' "$compound" ||
          fail "compound still contains local ledger or disposition vocabulary"

        touch $out
      '';

    checks.knowledge_workflow_conformance =
      pkgs.runCommand "knowledge-workflow-conformance" {
        compound = "${source}/compound/SKILL.md";
        readme = "${source}/README.md";
        rootAgents = "${inputs.self}/AGENTS.md";
        globalAgents = "${inputs.self}/home/modules/agents/AGENTS.md";
        nativeBuildInputs = [pkgs.gnugrep];
      } ''
        fail() { echo "knowledge-workflow-conformance: $1" >&2; exit 1; }

        ! grep -nE 'LESSONS\.md|tatr ledger|--ledger|Pending promotions|PROMOTE|DEFER|RETIRE|ABSORBED' "$compound" ||
          fail "compound still contains local ledger or disposition vocabulary"
        grep -q 'Knowledge repository: /home/alex/personal/agent-knowledge' "$globalAgents" ||
          fail "global AGENTS.md does not name the central knowledge path"
        grep -q '^[-] Knowledge: .*project=nix\.dotfiles.*tags=' "$rootAgents" ||
          fail "repo AGENTS.md does not declare project ID and tags"
        grep -q 'knowledge' "$readme" ||
          fail "skills README does not name the tool-owned knowledge skill"

        touch $out
      '';
  };
}
