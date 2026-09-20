{pkgs}: let
  qwen = pkgs.fetchurl {
    name = "Qwen3.6-35B-A3B-Q8_0.gguf";
    url = "https://huggingface.co/ggml-org/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-Q8_0.gguf";
    hash = "sha256-2NeELMZX1yDzlUaHjkMZN8hEc6oTDDY3FmmsF8gMc2E=";
  };
  gemma = pkgs.fetchurl {
    name = "gemma-4-26B-A4B-it-Q8_0.gguf";
    url = "https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF/resolve/main/gemma-4-26B-A4B-it-Q8_0.gguf";
    hash = "sha256-tRCP0TFH0chmu1lSlbydVvX+dE1yCfGEIQMdDMRwCcY=";
  };
  generation = {
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
  preset = pkgs.writeText "llama-models.ini" (pkgs.lib.generators.toINI {} {
    "Qwen3.6-35B-A3B" =
      generation
      // {
        model = toString qwen;
        alias = "ggml-org/Qwen3.6-35B-A3B";
        fit = "on";
      };
    "gemma-4-26B-A4B-it" =
      generation
      // {
        model = toString gemma;
        alias = "ggml-org/gemma-4-26B-A4B-it-GGUF";
        fit = "on";
      };
  });
in {
  inherit gemma preset qwen;
}
