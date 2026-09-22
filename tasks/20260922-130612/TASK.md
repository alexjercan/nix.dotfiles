# Review llama.cpp model for RTX 3060 8GB

- STATUS: CLOSED
- PRIORITY: 50
- TAGS: research, llama-cpp

Review the local llama.cpp and model configuration for an NVIDIA RTX 3060 with 8 GB VRAM.

Plan:
1. Trace the repository's llama.cpp, CUDA, model, context, and serving configuration.
2. Verify the effective hardware and runtime assumptions.
3. Research current smaller Gemma-family and comparable models, including quantized memory needs and llama.cpp support.
4. Compare expected quality, speed, context, and CPU-offload tradeoffs against the configured 27B model.
5. Recommend a model and concrete configuration changes, but do not edit configuration without approval.

## Findings

- The machine has an NVIDIA GeForce RTX 3060 Ti with 8 GiB VRAM and 32 GiB RAM.
- The service uses llama.cpp build 10121 with CUDA, router mode, automatic fitting,
  and a 128K context. The active override is CUDA even though the reusable module
  defaults to Vulkan.
- The configured Gemma 4 26B A4B Q8_0 file is 26.86 GB. It loads by moving many
  tensors to CPU RAM. Measured generation starts near 10 tokens/s and declines
  to about 4 tokens/s during a long session.
- Gemma 4 12B QAT Q4_0 is 6.98 GB and is the best same-family compromise. It
  should mostly fit on this GPU with automatic fitting, but a 32K context gives
  safer display and KV-cache headroom than 128K.
- Gemma 4 E4B Q4_K_M is 4.98 GB and fits comfortably, but official Gemma 4
  benchmarks show a substantial loss on difficult reasoning and coding tasks.
- Qwen3.5 9B Q4_K_M is 5.68 GB and is another strong hardware fit, but changing
  model families is not needed for the first test.

## Recommendation

Test Gemma 4 12B QAT Q4_0 with a 32K context first. Keep the 26B model as an
optional slow quality tier if useful. Do not replace it with E4B unless latency
and VRAM headroom matter more than difficult reasoning and coding quality.

## Implementation follow-up

Add Gemma 4 12B IT QAT Q4_0 as the Pi-facing model. Use a 32K context in both
llama.cpp and Pi. Preserve the existing larger router models unless removing
them is required by the implementation. Format and run the cheapest relevant
Home Manager checks.

## Implementation

Applied on 2026-09-22. Not activated.

- `home/modules/agents/llama-cpp/models.nix`: added `gemma12b`, the official
  `google/gemma-4-12B-it-qat-q4_0-gguf` file (6,975,879,296 bytes,
  `sha256-k1Z+V6j+ELI1abnZ7DjNAF3u33HilHfEIaS4P0GKU4s=`), and a matching router
  section `gemma-4-12B-it-qat`. Renamed `gemma` to `gemma26b` to separate the
  two Gemma entries. Qwen3.6 35B and Gemma 4 26B stay in the router.
- `home/modules/agents/default.nix`: set `services.llama-cpp.contextSize` to
  32768 and added the 12B model to the Pi `gemma` provider with a 32768 context
  window. Corrected the 26B entry from 128000 to 32768, because the router
  applies one `--ctx-size` to every model.

Checks:

- `nix build .#homeConfigurations.alex.activationPackage` succeeds. The model
  hash verified against the real download.
- ExecStart resolves to `--ctx-size 32768`. The generated `llama-models.ini`
  and `pi-models.json` agree on the id `gemma-4-12B-it-qat`.
- `nix flake check` fails for an unrelated reason: `flake/default.nix` imports
  `home/modules/agents/checks.nix`, which commit 141ee88 deleted.

Remaining: run a Home Manager switch, then measure the 12B model on the GPU.
