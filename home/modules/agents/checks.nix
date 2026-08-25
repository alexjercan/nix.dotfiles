{
  pkgs,
  homeModule,
  i3Module,
  scufrisI3Module,
  scufrisModule,
  scufrisRevision,
  packages,
  extensions,
  home-manager,
  sourceRoot,
}: let
  lib = pkgs.lib;

  mkHomeWith = {
    moduleConfig,
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
            }
            // extraConfig)
        ]
        ++ extraModules;
    };

  mkHome = moduleConfig: mkHomeWith {inherit moduleConfig;};

  enabled = mkHome {enable = true;};
  disabled = mkHome {enable = false;};
  configured = mkHome {
    enable = true;
    agentsFile = sourceRoot + "/AGENTS.md";
    pi.extensions.plannotator.enable = true;
    pi.themes.gruber-darker.enable = true;
    pi.settings.theme = "test-theme";
  };
  minimal = mkHome {
    enable = true;
    pi.enable = false;
    pi.settings.theme = "gruber-darker";
  };
  toolsEnabled = mkHome {
    enable = true;
    agentBrowser.enable = true;
    claudeCode.enable = true;
    codex.enable = true;
    opencode.enable = true;
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
    extraModules = [scufrisModule scufrisI3Module i3Module];
    extraConfig.programs.scufris = {
      enable = true;
      piPackage = packages.pi;
      dashboard.enable = false;
      voice = {
        enable = true;
        popup.enable = true;
      };
    };
  };
  popupDisabled = mkHomeWith {
    moduleConfig = {
      enable = true;
      pi.extensions.voice-stt.enable = true;
    };
    extraModules = [scufrisModule scufrisI3Module i3Module];
    extraConfig.programs.scufris = {
      enable = true;
      dashboard.enable = false;
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
  enabledConfig = enabled.config;
  disabledConfig = disabled.config;
  configuredConfig = configured.config;
  minimalConfig = minimal.config;
  toolsConfig = toolsEnabled.config;
  quickReviewConfig = quickReviewEnabled.config;
  sttEnabledConfig = sttEnabled.config;
  localWhisperConfig = localWhisperEnabled.config;
  voiceDisabledConfig = voiceDisabled.config;
  popupConfig = popupEnabled.config;
  popupDisabledConfig = popupDisabled.config;
  popupVoiceConfig = popupConfig.programs.scufris.voice.popup;
  popupToggle =
    lib.removePrefix "exec --no-startup-id "
    popupConfig.xsession.windowManager.i3.config.keybindings."Mod4+s";
  popupUnit = popupConfig.systemd.user.services.${popupVoiceConfig.serviceName};

  moduleAssertions = assert enabledConfig.programs.agents.pi.enable;
  assert enabledConfig.programs.agents.pi.package == packages.pi;
  assert enabledConfig.programs.agents.pi.settings == {};
  assert enabledConfig.programs.agents.pi.finalArgs == [];
  # No resource flags means no wrapper: the bare package is installed.
  assert enabledConfig.programs.agents.pi.finalPackage == packages.pi;
  assert builtins.toString configuredConfig.home.file."AGENTS.md".source == builtins.toString (sourceRoot + "/AGENTS.md");
  assert configuredConfig.programs.agents.pi.settings.theme == "test-theme";
  assert builtins.length configuredConfig.programs.agents.pi.finalArgs == 4;
  assert lib.count (arg: arg == "--theme") configuredConfig.programs.agents.pi.finalArgs == 1;
  assert lib.count (arg: arg == "--extension") configuredConfig.programs.agents.pi.finalArgs == 1;
  assert lib.elem (builtins.toString (sourceRoot + "/pi/themes/gruber-darker.json"))
  configuredConfig.programs.agents.pi.finalArgs;
  # Settings reach pi through an activation merge, never a read-only symlink.
  assert builtins.hasAttr "piSettings" configuredConfig.home.activation;
  assert !(builtins.hasAttr ".pi/agent/settings.json" configuredConfig.home.file);
  assert !(builtins.hasAttr "piSettings" enabledConfig.home.activation);
  assert lib.elem enabledConfig.programs.agents.pi.finalPackage enabledConfig.home.packages;
  assert lib.all (package: !(lib.elem package enabledConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.opencode
    packages.plannotator
  ];
  assert lib.all (package: lib.elem package toolsConfig.home.packages) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.opencode
  ];
  assert lib.elem packages.plannotator configuredConfig.home.packages;
  assert lib.elem "${extensions.plannotator}" configuredConfig.programs.agents.pi.finalArgs;
  assert !(lib.elem "${extensions.plannotator}" enabledConfig.programs.agents.pi.finalArgs);
  assert !conflictingWhisper.success;
  assert lib.elem "${extensions.voice-stt}" sttEnabledConfig.programs.agents.pi.finalArgs;
  assert builtins.hasAttr ".pi/agent/stt.json" sttEnabledConfig.home.file;
  assert !(builtins.hasAttr "PI_STT_CONFIG" sttEnabledConfig.home.sessionVariables);
  assert !(builtins.hasAttr "whisper-server" sttEnabledConfig.systemd.user.services);
  assert lib.elem "${extensions.voice-stt}" localWhisperConfig.programs.agents.pi.finalArgs;
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
  assert !(lib.elem "${extensions.voice-stt}" voiceDisabledConfig.programs.agents.pi.finalArgs);
  assert !(builtins.hasAttr ".pi/agent/stt.json" voiceDisabledConfig.home.file);
  assert !(builtins.hasAttr "PI_STT_CONFIG" voiceDisabledConfig.home.sessionVariables);
  assert !(builtins.hasAttr "whisper-server" voiceDisabledConfig.systemd.user.services);
  assert popupVoiceConfig.class == "Scufris";
  assert popupVoiceConfig.instance == "scufris-popup";
  assert popupVoiceConfig.serviceName == "scufris-popup";
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
  assert !(builtins.hasAttr "AGENTS.md" enabledConfig.home.file);
  assert !(builtins.hasAttr ".claude/CLAUDE.md" enabledConfig.home.file);
  assert !(builtins.hasAttr ".codex/AGENTS.md" enabledConfig.home.file);
  assert builtins.hasAttr "AGENTS.md" configuredConfig.home.file;
  assert builtins.hasAttr ".claude/CLAUDE.md" configuredConfig.home.file;
  assert builtins.hasAttr ".codex/AGENTS.md" configuredConfig.home.file;
  assert lib.all (package: !(lib.elem package minimalConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.opencode
    packages.pi
    packages.plannotator
  ];
  assert !minimalConfig.programs.agents.pi.enable;
  assert !(builtins.hasAttr "piSettings" minimalConfig.home.activation);
  assert !(builtins.hasAttr "AGENTS.md" minimalConfig.home.file);
  assert !(builtins.hasAttr ".claude/CLAUDE.md" minimalConfig.home.file);
  assert !(builtins.hasAttr ".codex/AGENTS.md" minimalConfig.home.file);
  assert !(builtins.hasAttr "piSettings" disabledConfig.home.activation);
  assert lib.all (package: !(lib.elem package disabledConfig.home.packages)) [
    packages.agent-browser
    packages.claude-code
    packages.codex
    packages.opencode
    packages.pi
    packages.plannotator
  ];
  assert !(builtins.hasAttr "AGENTS.md" disabledConfig.home.file);
    pkgs.runCommand "agents-home-module" {} ''
      touch "$out"
    '';
in {
  quick-review = assert lib.assertMsg
  (lib.elem "${extensions.quick-review}" quickReviewConfig.programs.agents.pi.finalArgs)
  "enabling Quick Review must add its package to Pi";
  assert lib.assertMsg
  (quickReviewConfig.programs.agents.pi.extensions.quick-review.package == extensions.quick-review)
  "the Quick Review module must default to the pinned package";
  assert lib.assertMsg
  (!(lib.elem "${extensions.quick-review}" enabledConfig.programs.agents.pi.finalArgs))
  "Quick Review must remain disabled by default in the reusable module";
  assert lib.assertMsg (extensions.quick-review.version == "0.1.1")
  "Quick Review must remain pinned at 0.1.1";
    pkgs.runCommand "quick-review-smoke" {
      nativeBuildInputs = [pkgs.jq];
    } ''
      test -f ${extensions.quick-review}/package.json
      test -f ${extensions.quick-review}/extensions/quick-review/index.ts
      test -f ${extensions.quick-review}/docs/contract.md
      test ! -e ${extensions.quick-review}/tests
      test ! -e ${extensions.quick-review}/node_modules
      jq -e '
        .version == "0.1.1" and
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
      toggle=${popupToggle}
      owned=$(grep -oE '/nix/store/[^[:space:]"]*/bin/scufris-popup-owned-window' "$toggle" | head -n1)
      test -x "$owned"

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

  home-module = moduleAssertions;
}
