{
  lib,
  pkgs,
  ...
}: {
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override {cudaSupport = true;};
    openFirewall = false;
    settings = {
      host = "0.0.0.0";
      port = 11433;
      ctx-size = 128000;
      models-preset =
        pkgs.writeText "llama-cpp-models-preset.ini"
        (lib.generators.toINI {} {
          "Qwen3.6-35B-A3B" = {
            hf-repo = "ggml-org/Qwen3.6-35B-A3B-GGUF";
            hf-file = "Qwen3.6-35B-A3B-Q8_0.gguf";
            alias = "ggml-org/Qwen3.6-35B-A3B";
            fit = "on";
            seed = "3407";
            temp = "0.2";
            top-p = "0.9";
            min-p = "0.05";
            top-k = "20";
            repeat-penalty = "1.05";
            repeat-last-n = "256";
            dry-multiplier = "0.5";
            dry-base = "1.75";
            dry-allowed-length = "8";
            dry-penalty-last-n = "4096";
            jinja = "on";
          };
          "gemma-4-26B-A4B-it" = {
            hf-repo = "ggml-org/gemma-4-26B-A4B-it-GGUF";
            hf-file = "gemma-4-26B-A4B-it-Q8_0.gguf";
            alias = "ggml-org/gemma-4-26B-A4B-it-GGUF";
            fit = "on";
            seed = "3407";
            temp = "0.2";
            top-p = "0.9";
            min-p = "0.05";
            top-k = "20";
            repeat-penalty = "1.05";
            repeat-last-n = "256";
            dry-multiplier = "0.5";
            dry-base = "1.75";
            dry-allowed-length = "8";
            dry-penalty-last-n = "4096";
            jinja = "on";
          };
        });
    };
  };

  systemd.services.cache-cleanup = {
    description = "Prune llama-cpp model cache";
    serviceConfig.Type = "oneshot";
    path = [pkgs.python3Packages.huggingface-hub];
    script = ''
      hf cache prune --cache-dir /var/cache/private/llama-cpp
    '';
  };

  systemd.timers.cache-cleanup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };
}
