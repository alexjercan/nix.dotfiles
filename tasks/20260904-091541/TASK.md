# Deploy ai-tools-api v0.2.1

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: ai,llm

## Goal

Pin ai-tools-api v0.2.1 and activate the Home Manager generation so normal
non-streaming LLM requests use the configured backend timeout.

## Decisions

- Update only the root ai-tools-api input. Its followed inputs remain shared.
- Keep all service, model, network, and timeout settings unchanged.

## Verification

- The lock resolves v0.2.1 to commit
  `f05191a507c4ac834d90ac67ef5da03bf1f424aa`.
- `alejandra --check flake.nix home hosts` and `git diff --check` passed.
- `nix flake check -L` passed.
- `nix build .#homeConfigurations.alex.activationPackage -L` passed.
- `home-manager switch --flake .#alex -L` completed and restarted only the
  changed API service and its Scufris consumer.
- `ai-tools-api.service` is active from the 0.2.1 store path. The unchanged
  llama.cpp backend stayed active.
- A non-streaming Gemma `hello` request without a completion-token limit passed
  through port 10300 with HTTP 200 and 79 completion tokens.

