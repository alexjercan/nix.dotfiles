# Deployment check for the agent skills.
#
# `home/modules/agents/skills/check.sh` proves the skill TEXTS conform - budgets,
# reference graph, invocation policy, output contracts. It says nothing about
# whether those files reach an agent. That is this check's job, and the two
# halves fail differently: a skill can be perfectly written and still invisible
# because the home-manager module never listed it, or because a reference file
# beside its SKILL.md was left out of the deployed tree.
#
# The seam is `localSkills` in home/modules/agents/default.nix: an explicit list
# that must stay in step with the directories on disk. Adding a skill folder and
# forgetting the list leaves a skill nobody ever loads, and nothing else in the
# build notices.
{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    home = inputs.self.homeConfigurations.alex.config;
    source = "${inputs.self}/home/modules/agents/skills";

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
    # `--self-test` runs first: a gate that cannot fail would make the green
    # run below meaningless.
    checks.skills-conformance =
      pkgs.runCommand "skills-conformance" {
        inherit source;
        nativeBuildInputs = [pkgs.bash pkgs.gnugrep pkgs.coreutils pkgs.gawk pkgs.gnused pkgs.perl];
      } ''
        cp -r "$source" skills
        chmod -R u+w skills
        bash skills/check.sh --self-test
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

        # 1. Every directory holding a SKILL.md is deployed, and every deployed
        #    name is a real skill directory. `fixtures/` has no SKILL.md and
        #    must NOT appear; it is a test asset, not a skill.
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
        if grep -qx fixtures deployed-claude || grep -qx fixtures deployed-agents; then
          fail "the fixtures/ test assets are deployed as a skill"
        fi

        # 2. Each deployed entry points at ITS OWN source directory and is
        #    recursive. A `recursive = false` entry becomes a single directory
        #    symlink, which the agent tools can no longer merge their own
        #    skills into; a mismatched `source` deploys one skill's files under
        #    another skill's name. Both build cleanly.
        printf '%s' "$deployedDetail" > detail.json
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
  };
}
