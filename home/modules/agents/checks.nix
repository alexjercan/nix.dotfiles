{
  pkgs,
  homeModule,
  i3Module,
  scufrisModule,
  scufrisRevision,
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
      pi.extensions.plannotator.enable = true;
      pi.themes.gruber-darker.enable = true;
    };
    piConfig = {
      settings.theme = "test-theme";
    };
  };
  minimal = mkHome {
    enable = true;
    pi.enable = false;
  };
  quickReviewEnabled = mkHome {
    enable = true;
    pi.extensions.quick-review.enable = true;
  };
  sttEnabled = mkHome {
    enable = true;
    pi.extensions.voice-stt = {
      enable = true;
      settings.provider = {
        type = "openai-compatible";
        endpoint = "http://127.0.0.1:9000/inference";
      };
    };
  };
  localWhisperEnabled = mkHome {
    enable = true;
    pi.extensions.voice-stt = {
      enable = true;
      localWhisper.enable = true;
      settings.keybind = "ctrl+r";
    };
  };
  voiceDisabled = mkHome {
    enable = true;
    pi.extensions.voice-stt.enable = false;
  };
  popupEnabled = mkHomeWith {
    moduleConfig = {
      enable = true;
      pi.extensions.voice-stt = {
        enable = true;
        localWhisper.enable = true;
      };
    };
    extraModules = [scufrisModule i3Module];
    extraConfig = {
      programs.scufris = {
        enable = true;
        piPackage = packages.pi;
        delegation.enable = false;
        widgets.enable = false;
        voice = {
          enable = true;
          popup.enable = true;
        };
      };
      xsession.windowManager.i3.scufrisPopup.enable = true;
    };
  };
  popupDisabled = mkHomeWith {
    moduleConfig = {
      enable = true;
      pi.extensions.voice-stt.enable = true;
    };
    extraModules = [scufrisModule i3Module];
    extraConfig.programs.scufris = {
      enable = true;
      delegation.enable = false;
      widgets.enable = false;
    };
  };
  conflictingWhisper = builtins.tryEval (builtins.deepSeq
    (mkHome {
      enable = true;
      pi.extensions.voice-stt = {
        enable = true;
        localWhisper.enable = true;
        settings.provider.endpoint = "http://127.0.0.1:9000/inference";
      };
    }).activationPackage
    true);
  invalidPopupConsumer = builtins.tryEval (builtins.deepSeq
    (mkHomeWith {
      moduleConfig = {enable = true;};
      extraModules = [scufrisModule i3Module];
      extraConfig = {
        programs.scufris = {
          enable = true;
          delegation.enable = false;
          widgets.enable = false;
        };
        xsession.windowManager.i3.scufrisPopup.enable = true;
      };
    }).activationPackage
    true);
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
  quickReviewConfig = quickReviewEnabled.config;
  sttEnabledConfig = sttEnabled.config;
  localWhisperConfig = localWhisperEnabled.config;
  voiceDisabledConfig = voiceDisabled.config;
  popupConfig = popupEnabled.config;
  popupDisabledConfig = popupDisabled.config;
  expectedSkills = ["extra"];
  deployed = root: name: enabledConfig.home.file."${root}/${name}";
  popupVoiceConfig = popupConfig.programs.scufris.voice.popup;
  popupI3Config = popupConfig.xsession.windowManager.i3.scufrisPopup;
  popupUnit = popupConfig.systemd.user.services.${popupVoiceConfig.serviceName};

  moduleAssertions = assert !invalidName.success;
  assert !missingSkill.success;
  assert enabledConfig.programs.pi.coding-agent.enable;
  assert enabledConfig.programs.pi.coding-agent.package == packages.pi;
  assert (enabledConfig.programs.pi.coding-agent.settings.theme or null) == null;
  assert enabledConfig.programs.pi.coding-agent.finalArgs == [];
  assert builtins.toString configuredConfig.home.file."AGENTS.md".source == builtins.toString (sourceRoot + "/AGENTS.md");
  assert configuredConfig.programs.pi.coding-agent.settings.theme == "test-theme";
  assert builtins.length configuredConfig.programs.pi.coding-agent.finalArgs == 4;
  assert lib.count (arg: arg == "--theme") configuredConfig.programs.pi.coding-agent.finalArgs == 1;
  assert lib.count (arg: arg == "--extension") configuredConfig.programs.pi.coding-agent.finalArgs == 1;
  assert builtins.map builtins.toString configuredConfig.programs.pi.coding-agent.themes
  == [(builtins.toString (sourceRoot + "/themes/gruber-darker.json"))];
  assert enabledConfig.programs.pi.coding-agent.themes == [];
  assert lib.elem enabledConfig.programs.pi.coding-agent.finalPackage enabledConfig.home.packages;
  assert lib.all (package: !(lib.elem package enabledConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.opencode
    packages.plannotator
  ];
  assert lib.elem packages.plannotator configuredConfig.home.packages;
  assert lib.elem extensions.plannotator configuredConfig.programs.pi.coding-agent.extensions;
  assert !(lib.elem extensions.plannotator enabledConfig.programs.pi.coding-agent.extensions);
  assert !conflictingWhisper.success;
  assert !invalidPopupConsumer.success;
  assert lib.elem extensions.voice-stt sttEnabledConfig.programs.pi.coding-agent.extensions;
  assert builtins.hasAttr ".pi/agent/stt.json" sttEnabledConfig.home.file;
  assert !(builtins.hasAttr "PI_STT_CONFIG" sttEnabledConfig.home.sessionVariables);
  assert !(builtins.hasAttr "whisper-server" sttEnabledConfig.systemd.user.services);
  assert lib.elem extensions.voice-stt localWhisperConfig.programs.pi.coding-agent.extensions;
  assert builtins.hasAttr ".pi/agent/stt.json" localWhisperConfig.home.file;
  assert !(builtins.hasAttr "PI_STT_CONFIG" localWhisperConfig.home.sessionVariables);
  assert localWhisperConfig.programs.agents.pi.extensions.voice-stt.ffmpegPackage == pkgs.ffmpeg;
  assert localWhisperConfig.programs.agents.pi.extensions.voice-stt.localWhisper.package == pkgs.whisper-cpp-vulkan;
  assert localWhisperConfig.programs.agents.pi.extensions.voice-stt.localWhisper.model.name == "ggml-large-v3-turbo-q5_0.bin";
  assert localWhisperConfig.programs.agents.pi.extensions.voice-stt.localWhisper.host == "127.0.0.1";
  assert localWhisperConfig.programs.agents.pi.extensions.voice-stt.localWhisper.port == 10301;
  assert builtins.hasAttr "whisper-server" localWhisperConfig.systemd.user.services;
  assert lib.hasInfix "--host 127.0.0.1" (builtins.head localWhisperConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert lib.hasInfix "--port 10301" (builtins.head localWhisperConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert lib.hasInfix "--inference-path /inference" (builtins.head localWhisperConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert lib.hasInfix "--language auto" (builtins.head localWhisperConfig.systemd.user.services.whisper-server.Service.ExecStart);
  assert localWhisperConfig.systemd.user.services.whisper-server.Service.Restart == "no";
  assert !(lib.elem extensions.voice-stt voiceDisabledConfig.programs.pi.coding-agent.extensions);
  assert !(builtins.hasAttr ".pi/agent/stt.json" voiceDisabledConfig.home.file);
  assert !(builtins.hasAttr "PI_STT_CONFIG" voiceDisabledConfig.home.sessionVariables);
  assert !(builtins.hasAttr "whisper-server" voiceDisabledConfig.systemd.user.services);
  assert popupVoiceConfig.class == "Scufris";
  assert popupVoiceConfig.instance == "scufris-popup";
  assert popupVoiceConfig.serviceName == "scufris-popup";
  assert popupI3Config.mark == "scufris-popup";
  assert popupUnit.Service.Restart == "no";
  assert !(popupUnit ? Install);
  assert popupUnit.Service.ExecStart == [(lib.getExe popupVoiceConfig.finalLauncher)];
  assert builtins.hasAttr "Mod4+s" popupConfig.xsession.windowManager.i3.config.keybindings;
  assert builtins.hasAttr "Print" popupConfig.xsession.windowManager.i3.config.keybindings;
  assert builtins.hasAttr "Shift+Print" popupConfig.xsession.windowManager.i3.config.keybindings;
  assert lib.hasInfix "mark --add scufris-popup" popupConfig.xsession.windowManager.i3.extraConfig;
  assert lib.hasInfix "resize set 1000 720" popupConfig.xsession.windowManager.i3.extraConfig;
  assert !(lib.hasInfix "title=" popupConfig.xsession.windowManager.i3.extraConfig);
  assert lib.elem popupConfig.programs.scufris.finalPackage popupConfig.home.packages;
  assert !(lib.elem popupConfig.programs.scufris.voice.piper.package popupConfig.home.packages);
  assert !(builtins.hasAttr "scufris-popup" popupDisabledConfig.systemd.user.services);
  assert !(builtins.hasAttr "Mod4+s" popupDisabledConfig.xsession.windowManager.i3.config.keybindings);
  assert lib.all (name: (deployed ".claude/skills" name).recursive) expectedSkills;
  assert lib.all (name: (deployed ".agents/skills" name).recursive) expectedSkills;
  assert builtins.toString (deployed ".agents/skills" "extra").source == builtins.toString extraSkill;
  assert !(builtins.hasAttr "AGENTS.md" enabledConfig.home.file);
  assert !(builtins.hasAttr ".claude/CLAUDE.md" enabledConfig.home.file);
  assert !(builtins.hasAttr ".codex/AGENTS.md" enabledConfig.home.file);
  assert builtins.hasAttr "AGENTS.md" configuredConfig.home.file;
  assert builtins.hasAttr ".claude/CLAUDE.md" configuredConfig.home.file;
  assert builtins.hasAttr ".codex/AGENTS.md" configuredConfig.home.file;
  assert minimalConfig.programs.agents.finalSkills == {};
  assert lib.all (package: !(lib.elem package minimalConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
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
    packages.opencode
    packages.pi
    packages.plannotator
  ];
  assert !(builtins.hasAttr "AGENTS.md" disabledConfig.home.file);
  assert !(builtins.hasAttr ".agents/skills/extra" disabledConfig.home.file);
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
  quick-review = assert lib.assertMsg
  (lib.elem extensions.quick-review quickReviewConfig.programs.pi.coding-agent.extensions)
  "enabling Quick Review must add its package to Pi";
  assert lib.assertMsg
  (quickReviewConfig.programs.agents.pi.extensions.quick-review.package == extensions.quick-review)
  "the Quick Review module must default to the pinned package";
  assert lib.assertMsg
  (!(lib.elem extensions.quick-review enabledConfig.programs.pi.coding-agent.extensions))
  "Quick Review must remain disabled by default in the reusable module";
  assert lib.assertMsg (extensions.quick-review.version == "0.1.0")
  "Quick Review must remain pinned at 0.1.0";
    pkgs.runCommand "quick-review-smoke" {
      nativeBuildInputs = [pkgs.jq];
    } ''
      test -f ${extensions.quick-review}/package.json
      test -f ${extensions.quick-review}/extensions/quick-review/index.ts
      test -f ${extensions.quick-review}/docs/contract.md
      test ! -e ${extensions.quick-review}/tests
      test ! -e ${extensions.quick-review}/node_modules
      jq -e '
        .version == "0.1.0" and
        .pi.extensions == ["./extensions/quick-review/index.ts"]
      ' ${extensions.quick-review}/package.json > /dev/null
      touch "$out"
    '';

  voice-stt = assert lib.assertMsg (extensions.voice-stt.version == "0.6.0")
  "pi-voice-stt must remain pinned at 0.6.0";
    pkgs.runCommand "pi-voice-stt-smoke" {} ''
      test -f ${extensions.voice-stt}/package.json
      test -f ${extensions.voice-stt.nodeModules}/node_modules/pi-voice-stt/src/index.ts
      grep -E '"version"[[:space:]]*:[[:space:]]*"0\.6\.0"' ${extensions.voice-stt.nodeModules}/node_modules/pi-voice-stt/package.json
      touch "$out"
    '';

  local-whisper =
    pkgs.runCommand "local-whisper-composition" {
      nativeBuildInputs = [pkgs.jq];
      activationPackage = localWhisperEnabled.activationPackage;
      disabledActivationPackage = voiceDisabled.activationPackage;
      sttActivationPackage = sttEnabled.activationPackage;
      sttConfig = localWhisperConfig.home.file.".pi/agent/stt.json".source;
      customSttConfig = sttEnabledConfig.home.file.".pi/agent/stt.json".source;
    } ''
      test -e "$activationPackage"
      test -e "$disabledActivationPackage"
      test -e "$sttActivationPackage"
      jq -e '
        .keybind == "ctrl+r" and
        .provider.type == "openai-compatible" and
        .provider.endpoint == "http://127.0.0.1:10301/inference" and
        .provider.model == "whisper-1" and
        .provider.language == "auto" and
        .provider.apiKeyEnv == ""
      ' "$sttConfig"
      jq -e '
        .provider.type == "openai-compatible" and
        .provider.endpoint == "http://127.0.0.1:9000/inference"
      ' "$customSttConfig"
      touch "$out"
    '';

  scufris-popup =
    pkgs.runCommand "scufris-popup-i3-consumer" {
      nativeBuildInputs = [pkgs.gnugrep];
      activationPackage = popupEnabled.activationPackage;
      disabledActivationPackage = popupDisabled.activationPackage;
    } ''
      test -e "$activationPackage"
      test -e "$disabledActivationPackage"
      popup=${lib.getExe popupVoiceConfig.finalLauncher}
      toggle=${lib.getExe popupI3Config.finalToggle}
      owned=${lib.getExe popupI3Config.finalOwnerQuery}

      grep -F 'export SCUFRIS_SPEECH=1' "$popup"
      grep -F 'export SCUFRIS_CALM=1' "$popup"
      grep -F -- '--class Scufris' "$popup"
      grep -F -- '--name scufris-popup' "$popup"
      grep -F 'systemctl --user start scufris-popup.service' "$toggle"
      grep -F 'class="^Scufris$"' "$toggle"
      grep -F 'instance="^scufris-popup$"' "$toggle"
      grep -F 'con_mark="^scufris-popup$"' "$toggle"
      ! grep -F 'PI_STT_CONFIG' "$popup" "$toggle" "$owned"
      ! grep -F 'title=' "$toggle" "$owned"
      ! grep -E 'pkill|killall|tmux' "$toggle" "$owned"

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
      touch "$out"
    '';

  scufris-revision = assert lib.assertMsg (scufrisRevision == "794561a0b912138c732131cd83df0ecf5ab3960d")
  "Scufris must remain pinned at v0.2.0 release revision 794561a";
    pkgs.runCommand "scufris-v0.2.0-revision" {} ''
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
