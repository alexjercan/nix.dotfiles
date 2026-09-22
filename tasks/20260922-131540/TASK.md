# Research Qwen models for RTX 3060 Ti 8GB

- STATUS: CLOSED
- PRIORITY: 40
- TAGS: research, llama-cpp, qwen

Research open-source Qwen-family models suitable for llama.cpp on the local NVIDIA RTX 3060 Ti with 8 GiB VRAM and 32 GiB RAM.

Compare current instruct/reasoning/coding candidates by license, architecture, parameter count, GGUF availability and size, context support, expected fit, llama.cpp compatibility, and primary-source benchmark evidence. Recommend one default model and quantization. Do not change configuration.

## Findings

All candidates use Apache 2.0 and have current GGUF builds compatible with the
configured llama.cpp CUDA service.

- Qwen3.5 9B Q4_K_M is 5,680,522,464 bytes (5.29 GiB). Its hybrid architecture
  has only eight full-attention layers, making a 32K context practical in 8 GiB
  VRAM. This is the recommended default.
- Qwen3.5 4B Q5_K_M is 3,143,656,608 bytes (2.93 GiB). It leaves ample VRAM and
  is the speed and long-context alternative.
- Qwen3 8B Q4_K_M is 5,027,783,488 bytes (4.68 GiB), but it is older and its
  standard attention uses more context memory than Qwen3.5. It is not the first
  choice for this machine.
- Qwen3.5 9B Q5_K_M is 6,577,841,376 bytes (6.13 GiB). It is possible with a
  smaller or quantized KV cache, but Q4_K_M leaves safer display and runtime
  headroom.

The official Qwen3.5 comparison reports 9B versus 4B scores of 64.5 versus 59.2
on IFBench, 81.7 versus 76.2 on GPQA Diamond, 83.2 versus 74.0 on HMMT February
2025, and 81.2 versus 76.1 on MMMLU. Both support a native 262K context, but
that model maximum is not a practical VRAM target on this machine.

## Recommendation

Use Qwen3.5 9B Q4_K_M at 32K context for the best local balance. Use Qwen3.5 4B
Q5_K_M when latency and VRAM headroom matter more than reasoning quality. Keep
KV cache at f16 initially and test q8_0 only if measured VRAM requires it.

## Implementation and Qwen3.8 follow-up

Add Qwen3.5 9B Q4_K_M to the llama.cpp router and Pi model catalogue at the
existing 32K service context. Keep the existing models. Research the newer
Qwen3.8 family for models and quantizations that can run well on the RTX 3060 Ti
with 8 GiB VRAM. Do not add a Qwen3.8 model until the research is reviewed.

Qwen3.5 9B Q4_K_M is now in the router and the Pi catalogue.

- `home/modules/agents/llama-cpp/models.nix` adds a `qwen35` fetchurl and a
  `Qwen3.5-9B` preset section. The existing `qwen` binding is renamed `qwen36`
  because two Qwen generations now coexist.
- Source is `unsloth/Qwen3.5-9B-GGUF`. Neither `Qwen/Qwen3.5-9B-GGUF` nor
  `ggml-org/Qwen3.5-9B-GGUF` exists, so the unsloth build is the current
  first-party-derived option. It is Apache 2.0, built from `Qwen/Qwen3.5-9B`,
  and the single-file Q4_K_M blob is 5,680,522,464 bytes, which matches the
  research above.
- `nix store prefetch-file` on the exact URL returned
  `sha256-A7dHJ6hgpWM44ELEQguz8Esv7Fc0F19MufqFPa9St+g=`, which is the hash
  recorded in `models.nix`.
- `home/modules/agents/default.nix` exposes the model under a new Pi provider
  `qwen` instead of extending the `gemma` provider. Both providers share one
  `llamaCpp` attribute set for the router endpoint, so a Pi model name never
  claims the wrong family. Generated `models.json` keeps the gemma provider
  byte-identical.
- The entry advertises `contextWindow = 32768`, the service `--ctx-size`, not
  the 262K model maximum.

## Qwen3.8 result

Qwen3.8 is an official Qwen family, but it has no practical 8 GiB option today.
The smallest open-weight release is the Apache-2.0 Qwen3.8 27B dense model.
Its Unsloth GGUF sizes include:

- Q4_K_M: 16,464,440,224 bytes (15.33 GiB).
- IQ4_XS: 14,252,845,984 bytes (13.27 GiB).
- IQ2_XXS: 7,266,070,528 bytes (6.77 GiB).

Q4 requires substantial CPU offload. IQ2_XXS leaves too little room for the KV
cache and runtime allocations at 32K and incurs severe quantization loss. The
Qwen3.8 Flash-Next release is a 125B MoE model with 6B active parameters plus
large embedding and MTP components; low active parameters do not make its full
weights fit in this machine's RAM or VRAM budget.

The installed llama.cpp is build 10121. An upstream user report documents bad
Qwen3.8 DeltaNet CUDA output on an older build and success near build 10450.
This is another reason not to deploy Qwen3.8 here without first updating and
validating llama.cpp. Keep Qwen3.5 9B Q4_K_M as the recommended model.

Sources:

- https://huggingface.co/Qwen/Qwen3.8-27B
- https://huggingface.co/unsloth/Qwen3.8-27B-GGUF
- https://huggingface.co/Qwen/Qwen3.8-Flash-Next
- https://github.com/ggml-org/llama.cpp/discussions/27164

- https://huggingface.co/Qwen/Qwen3.5-9B
- https://huggingface.co/Qwen/Qwen3.5-4B
- https://huggingface.co/unsloth/Qwen3.5-9B-GGUF
- https://huggingface.co/unsloth/Qwen3.5-4B-GGUF
- https://huggingface.co/Qwen/Qwen3-8B-GGUF
