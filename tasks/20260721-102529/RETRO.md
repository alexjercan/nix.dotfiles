# Retro: deploy the agents skills to codex

## What went well

- Refused to design from memory of codex's mechanism (verify-api-in-source /
  dry-run-in-a-scratch-repo). Probed the real tool: `codex debug prompt-input`
  renders the model-visible prompt, so a probe skill at ~/.agents/skills/zzprobe
  proved codex discovers user-scope skills from `~/.agents/skills` using the
  identical SKILL.md format - before writing a line of nix.
- The research paid off twice: it ruled OUT the wrong mechanism (`~/.codex/prompts`
  slash commands are deprecated by OpenAI in favor of skills) and confirmed the
  right one (skills, implicit description-matched invocation - true parity with
  Claude Code). The SKILL.md format being identical made the change a 6-line
  symlink, not a translation layer.
- Verified without touching the live system: built the home activationPackage
  (build-just-the-package) and confirmed ~/.agents/skills materializes with all
  skills AND that both trees resolve to the SAME store path (one source of truth,
  no duplication). The reviewer re-ran the same build independently.

## What went wrong

- Nothing material. The only cost was the up-front research, which was the point.

## What to improve next time

- For "make X work in tool Y", the first move is to verify how tool Y actually
  consumes X (its real discovery path + format), not to assume it mirrors the
  tool you know. Here that turned a potentially-wrong plugin/prompts detour into
  a trivial, correct symlink.

## Action items

- [x] Skills deploy to ~/.agents/skills (codex) + ~/.claude/skills (Claude) from
      one ./skills source; landed c8ef0a2.
- On the next `home-manager switch`, ~/.agents/skills goes live and the flow
  skills appear in codex (`codex debug prompt-input` will list plan/work/flow/...).
- Possible follow-up: the skill BODIES carry some Claude-Code idioms (tool names,
  slash syntax); a pass to make them tool-neutral would sharpen the codex experience.
