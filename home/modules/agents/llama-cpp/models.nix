{pkgs}: let
  qwen36 = pkgs.fetchurl {
    name = "Qwen3.6-35B-A3B-Q8_0.gguf";
    url = "https://huggingface.co/ggml-org/Qwen3.6-35B-A3B-GGUF/resolve/main/Qwen3.6-35B-A3B-Q8_0.gguf";
    hash = "sha256-2NeELMZX1yDzlUaHjkMZN8hEc6oTDDY3FmmsF8gMc2E=";
  };
  # Only eight of its layers use full attention, so a 32K context stays cheap
  # enough to hold the Q4_K_M weights and the KV cache on the 8 GiB GPU.
  qwen35 = pkgs.fetchurl {
    name = "Qwen3.5-9B-Q4_K_M.gguf";
    url = "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q4_K_M.gguf";
    hash = "sha256-A7dHJ6hgpWM44ELEQguz8Esv7Fc0F19MufqFPa9St+g=";
  };
  gemma26b = pkgs.fetchurl {
    name = "gemma-4-26B-A4B-it-Q8_0.gguf";
    url = "https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF/resolve/main/gemma-4-26B-A4B-it-Q8_0.gguf";
    hash = "sha256-tRCP0TFH0chmu1lSlbydVvX+dE1yCfGEIQMdDMRwCcY=";
  };
  # Quantization-aware training keeps Q4_0 quality close to the unquantized
  # weights while allowing most weights to remain on the 8 GiB GPU.
  gemma12b = pkgs.fetchurl {
    name = "gemma-4-12b-it-qat-q4_0.gguf";
    url = "https://huggingface.co/google/gemma-4-12B-it-qat-q4_0-gguf/resolve/main/gemma-4-12b-it-qat-q4_0.gguf";
    hash = "sha256-k1Z+V6j+ELI1abnZ7DjNAF3u33HilHfEIaS4P0GKU4s=";
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
        model = toString qwen36;
        alias = "ggml-org/Qwen3.6-35B-A3B";
        fit = "on";
      };
    "Qwen3.5-9B" =
      generation
      // {
        model = toString qwen35;
        alias = "unsloth/Qwen3.5-9B-GGUF";
        fit = "on";
      };
    "gemma-4-26B-A4B-it" =
      generation
      // {
        model = toString gemma26b;
        alias = "ggml-org/gemma-4-26B-A4B-it-GGUF";
        fit = "on";
      };
    "gemma-4-12B-it-qat" =
      generation
      // {
        model = toString gemma12b;
        alias = "google/gemma-4-12B-it-qat-q4_0-gguf";
        fit = "on";
      };
  });
in {
  inherit gemma12b gemma26b preset qwen35 qwen36;
}
