{
  pkgs,
  agentSkills,
  homeModule,
  localVoiceModule,
  packages,
  extensions,
  home-manager,
  sourceRoot,
}: let
  lib = pkgs.lib;
  extraSkill = sourceRoot + "/tests/fixtures/extra";

  mkHomeWith = {
    moduleConfig,
    piConfig ? {},
    extraModules ? [],
    extraConfig ? {},
  }:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules =
        [
          homeModule
          ({
              home.username = "agent-test";
              home.homeDirectory = "/tmp/agent-test-home";
              home.stateVersion = "24.05";
              programs.agents = moduleConfig;
              programs.pi.coding-agent = piConfig;
            }
            // extraConfig)
        ]
        ++ extraModules;
    };

  mkHome = moduleConfig: mkHomeWith {inherit moduleConfig;};

  enabled = mkHome {
    enable = true;
    skills.extra = extraSkill;
  };
  disabled = mkHome {enable = false;};
  configured = mkHomeWith {
    moduleConfig = {
      enable = true;
      agentsFile = sourceRoot + "/AGENTS.md";
      knowledge = {
        enable = true;
        directory = "/tmp/custom-agent-knowledge";
      };
      plannotator.enable = true;
      pi.themes = [(sourceRoot + "/tests/fixtures")];
    };
    piConfig = {
      settings.theme = "test-theme";
    };
  };
  minimal = mkHome {
    enable = true;
    skills = {
      review = extraSkill;
      understand = extraSkill;
    };
    knowledge = {
      enable = true;
      package = pkgs.hello;
    };
    pi.enable = false;
  };
  toolsEnabled = mkHome {
    enable = true;
    skills.knowledge = extraSkill;
    knowledge.enable = true;
  };
  voiceEnabled = mkHomeWith {
    moduleConfig = {
      enable = true;
      pi.voiceStt = {
        enable = true;
        settings.provider.endpoint = "http://127.0.0.1:10301/inference";
      };
    };
    extraModules = [localVoiceModule];
    extraConfig.services.localVoice = {
      enable = true;
      scufris.package = pkgs.hello;
    };
  };
  voiceDisabled = mkHomeWith {
    moduleConfig = {
      enable = true;
      pi.voiceStt.enable = false;
    };
    extraModules = [localVoiceModule];
    extraConfig.services.localVoice = {
      enable = false;
      scufris.package = pkgs.hello;
    };
  };
  invalidName = builtins.tryEval (builtins.deepSeq
    (mkHome {
      enable = true;
      skills."Bad Name" = extraSkill;
    }).config.programs.agents.finalSkills
    true);
  missingSkill = builtins.tryEval (builtins.deepSeq
    (mkHome {
      enable = true;
      skills.missing = sourceRoot + "/tests/fixtures";
    }).config.programs.agents.finalSkills
    true);

  enabledConfig = enabled.config;
  disabledConfig = disabled.config;
  configuredConfig = configured.config;
  minimalConfig = minimal.config;
  toolsEnabledConfig = toolsEnabled.config;
  voiceEnabledConfig = voiceEnabled.config;
  voiceDisabledConfig = voiceDisabled.config;
  expectedSkills = ["extra"];
  expectedToolSkills = ["knowledge"];
  deployed = root: name: enabledConfig.home.file."${root}/${name}";
  toolDeployed = root: name: toolsEnabledConfig.home.file."${root}/${name}";

  moduleAssertions = assert !invalidName.success;
  assert !missingSkill.success;
  assert enabledConfig.programs.pi.coding-agent.enable;
  assert enabledConfig.programs.pi.coding-agent.package == packages.pi;
  assert (enabledConfig.programs.pi.coding-agent.settings.theme or null) == null;
  assert enabledConfig.programs.pi.coding-agent.finalArgs == [];
  assert enabledConfig.programs.agents.knowledge.directory == "/tmp/agent-test-home/.local/share/agents/knowledge";
  assert !(builtins.hasAttr "AGENTS_KNOWLEDGE_DIR" enabledConfig.home.sessionVariables);
  assert configuredConfig.home.sessionVariables.AGENTS_KNOWLEDGE_DIR == "/tmp/custom-agent-knowledge";
  assert builtins.toString configuredConfig.home.file."AGENTS.md".source == builtins.toString (sourceRoot + "/AGENTS.md");
  assert configuredConfig.programs.pi.coding-agent.settings.theme == "test-theme";
  assert builtins.length configuredConfig.programs.pi.coding-agent.finalArgs == 2;
  assert lib.count (arg: arg == "--theme") configuredConfig.programs.pi.coding-agent.finalArgs == 1;
  assert lib.elem enabledConfig.programs.pi.coding-agent.finalPackage enabledConfig.home.packages;
  assert lib.all (package: !(lib.elem package enabledConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.knowledge
    packages.opencode
    packages.plannotator
  ];
  assert lib.elem packages.plannotator configuredConfig.home.packages;
  assert lib.elem extensions.voice-stt voiceEnabledConfig.programs.pi.coding-agent.extensions;
  assert voiceEnabledConfig.home.sessionVariables.PI_STT_CONFIG == "/tmp/agent-test-home/.config/pi-voice-stt/config.json";
  assert builtins.hasAttr ".config/pi-voice-stt/config.json" voiceEnabledConfig.home.file;
  assert builtins.hasAttr "whisper-server" voiceEnabledConfig.systemd.user.services;
  assert builtins.hasAttr "scufris-popup" voiceEnabledConfig.systemd.user.services;
  assert lib.hasInfix "--host 127.0.0.1" (builtins.head voiceEnabledConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert lib.hasInfix "--port 10301" (builtins.head voiceEnabledConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert lib.hasInfix "--inference-path /inference" (builtins.head voiceEnabledConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert lib.hasInfix "--language auto" (builtins.head voiceEnabledConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert voiceEnabledConfig.systemd.user.services.whisper-server.Service.Restart == "no";
  assert voiceEnabledConfig.systemd.user.services.scufris-popup.Service.Restart == "no";
  assert builtins.hasAttr "Mod4+s" voiceEnabledConfig.xsession.windowManager.i3.config.keybindings;
  assert lib.hasInfix "mark --add scufris-popup" voiceEnabledConfig.xsession.windowManager.i3.extraConfig;
  assert !(lib.hasInfix "title=" voiceEnabledConfig.xsession.windowManager.i3.extraConfig);
  assert !(lib.elem extensions.voice-stt voiceDisabledConfig.programs.pi.coding-agent.extensions);
  assert !(builtins.hasAttr "PI_STT_CONFIG" voiceDisabledConfig.home.sessionVariables);
  assert !(builtins.hasAttr "whisper-server" voiceDisabledConfig.systemd.user.services);
  assert !(builtins.hasAttr "scufris-popup" voiceDisabledConfig.systemd.user.services);
  assert lib.all (name: (deployed ".claude/skills" name).recursive) expectedSkills;
  assert lib.all (name: (deployed ".agents/skills" name).recursive) expectedSkills;
  assert builtins.toString (deployed ".agents/skills" "extra").source == builtins.toString extraSkill;
  assert !(builtins.hasAttr "AGENTS.md" enabledConfig.home.file);
  assert !(builtins.hasAttr ".claude/CLAUDE.md" enabledConfig.home.file);
  assert !(builtins.hasAttr ".codex/AGENTS.md" enabledConfig.home.file);
  assert builtins.hasAttr "AGENTS.md" configuredConfig.home.file;
  assert builtins.hasAttr ".claude/CLAUDE.md" configuredConfig.home.file;
  assert builtins.hasAttr ".codex/AGENTS.md" configuredConfig.home.file;
  assert builtins.attrNames minimalConfig.programs.agents.finalSkills == ["knowledge" "review" "understand"];
  assert builtins.toString minimalConfig.programs.agents.finalSkills.understand == builtins.toString extraSkill;
  assert builtins.toString minimalConfig.programs.agents.finalSkills.knowledge == builtins.toString agentSkills.knowledge;
  assert lib.elem pkgs.hello minimalConfig.home.packages;
  assert builtins.attrNames toolsEnabledConfig.programs.agents.finalSkills == expectedToolSkills;
  assert builtins.toString toolsEnabledConfig.programs.agents.finalSkills.knowledge == builtins.toString agentSkills.knowledge;
  assert lib.all (name: (toolDeployed ".claude/skills" name).recursive) expectedToolSkills;
  assert lib.all (name: (toolDeployed ".agents/skills" name).recursive) expectedToolSkills;
  assert lib.elem packages.knowledge toolsEnabledConfig.home.packages;
  assert lib.all (package: !(lib.elem package minimalConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.knowledge
    packages.opencode
    packages.pi
    packages.plannotator
  ];
  assert !minimalConfig.programs.pi.coding-agent.enable;
  assert !(builtins.hasAttr "AGENTS.md" minimalConfig.home.file);
  assert !(builtins.hasAttr ".claude/CLAUDE.md" minimalConfig.home.file);
  assert !(builtins.hasAttr ".codex/AGENTS.md" minimalConfig.home.file);
  assert !(disabledConfig.programs.pi.coding-agent.enable or false);
  assert lib.all (package: !(lib.elem package disabledConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.knowledge
    packages.opencode
    packages.pi
    packages.plannotator
  ];
  assert !(builtins.hasAttr "AGENTS_KNOWLEDGE_DIR" disabledConfig.home.sessionVariables);
  assert !(builtins.hasAttr "AGENTS.md" disabledConfig.home.file);
  assert !(builtins.hasAttr ".agents/skills/understand" disabledConfig.home.file);
    pkgs.runCommand "agents-home-module" {
      enabledCodex = enabledConfig.home.activation.agentsCodexSkills.data;
      disabledCodex = disabledConfig.home.activation.agentsCodexSkills.data;
      expected = lib.concatStringsSep " " expectedSkills;
    } ''
      for name in $expected; do
        case " $enabledCodex " in
          *" $name "*) ;;
          *) echo "enabled Codex activation omits $name" >&2; exit 1 ;;
        esac
        case " $disabledCodex " in
          *" $name "*) echo "disabled Codex activation retains $name" >&2; exit 1 ;;
          *) ;;
        esac
      done
      touch "$out"
    '';
in {
  knowledge = packages.knowledge;

  voice-stt = assert lib.assertMsg (extensions.voice-stt.version == "0.6.0")
  "pi-voice-stt must remain pinned at 0.6.0";
    pkgs.runCommand "pi-voice-stt-smoke" {} ''
      test -f ${extensions.voice-stt}/package.json
      test -f ${extensions.voice-stt.nodeModules}/node_modules/pi-voice-stt/src/index.ts
      grep -E '"version"[[:space:]]*:[[:space:]]*"0\.6\.0"' ${extensions.voice-stt.nodeModules}/node_modules/pi-voice-stt/package.json
      touch "$out"
    '';

  local-voice =
    pkgs.runCommand "local-voice-composition" {
      nativeBuildInputs = [pkgs.gnugrep voiceEnabledConfig.services.localVoice.piper.package];
    } ''
      popup=${voiceEnabledConfig.services.localVoice.finalPopupLauncher}/bin/scufris-popup-launch
      kitty=${voiceEnabledConfig.services.localVoice.finalKittyLauncher}/bin/scufris-popup-kitty
      toggle=${voiceEnabledConfig.services.localVoice.finalToggle}/bin/scufris-popup-toggle
      owned=${voiceEnabledConfig.services.localVoice.finalOwnerQuery}/bin/scufris-popup-owned-window

      grep -F 'export SCUFRIS_SPEECH=1' "$popup"
      grep -F 'export SCUFRIS_CALM=1' "$popup"
      grep -F -- '--session-dir /tmp/agent-test-home/.local/share/scufris-popup/sessions' "$popup"
      grep -F -- '--continue' "$popup"
      grep -F -- '--class Scufris' "$kitty"
      grep -F -- '--name scufris-popup' "$kitty"
      grep -F -- '--title Scufris' "$kitty"
      grep -F 'systemctl --user start scufris-popup.service' "$toggle"
      grep -F 'class="^Scufris$"' "$toggle"
      grep -F 'instance="^scufris-popup$"' "$toggle"
      grep -F 'con_mark="^scufris-popup$"' "$toggle"
      ! grep -F 'title=' "$toggle"
      ! grep -E 'pkill|killall|tmux' "$popup" "$kitty" "$toggle"

      cat > changed-title.json <<'EOF'
      {"nodes":[{"name":"Pi - changed at runtime","marks":["scufris-popup"],"window_properties":{"class":"Scufris","instance":"scufris-popup"}}]}
      EOF
      cat > near-class.json <<'EOF'
      {"nodes":[{"name":"Pi","marks":["scufris-popup"],"window_properties":{"class":"Scufris-other","instance":"scufris-popup"}}]}
      EOF
      cat > near-instance.json <<'EOF'
      {"nodes":[{"name":"Pi","marks":["scufris-popup"],"window_properties":{"class":"Scufris","instance":"scufris-popup-other"}}]}
      EOF
      cat > near-mark.json <<'EOF'
      {"nodes":[{"name":"Pi","marks":["scufris-popup-other"],"window_properties":{"class":"Scufris","instance":"scufris-popup"}}]}
      EOF
      "$owned" < changed-title.json
      ! "$owned" < near-class.json
      ! "$owned" < near-instance.json
      ! "$owned" < near-mark.json

      printf '%s\n' 'Local voice composition test.' | piper \
        --model ${voiceEnabledConfig.services.localVoice.piper.model} \
        --config ${voiceEnabledConfig.services.localVoice.piper.config} \
        --output-file fixture.wav
      test -s fixture.wav
      printf '%s\n' 'Piper standard output test.' | piper \
        --model ${voiceEnabledConfig.services.localVoice.piper.model} \
        --config ${voiceEnabledConfig.services.localVoice.piper.config} \
        --output-file - > stdout.wav
      test -s stdout.wav
      test "$(head -c 4 stdout.wav)" = RIFF
      touch "$out"
    '';

  plannotator = assert lib.assertMsg (packages.plannotator.version == extensions.plannotator.version)
  "Plannotator binary and Pi extension versions must match";
    pkgs.runCommand "plannotator-smoke" {
      nativeBuildInputs = [packages.plannotator pkgs.gnugrep];
    } ''
      plannotator --help | grep -Fx "Usage:"
      test "$(plannotator --version)" = "plannotator ${packages.plannotator.version}"
      touch "$out"
    '';

  knowledge-integration =
    pkgs.runCommand "knowledge-integration" {
      nativeBuildInputs = [pkgs.bash pkgs.coreutils pkgs.gnugrep];
      test = sourceRoot + "/scripts/knowledge-test.sh";
    } ''
      KNOWLEDGE=${lib.getExe packages.knowledge} bash "$test"
      touch "$out"
    '';

  codex-materialization =
    pkgs.runCommand "codex-materialization" {
      nativeBuildInputs = [pkgs.bash packages.deploy-codex-skills];
      test = sourceRoot + "/scripts/deploy-codex-skills-test.sh";
    } ''
      DEPLOY_CODEX_SKILLS=${lib.getExe packages.deploy-codex-skills} bash "$test"
      touch "$out"
    '';

  home-module = moduleAssertions;
}
