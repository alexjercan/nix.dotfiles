# Fixture runner, sourced by check.sh. Uses its `root`, `fail` and `findings`.
#
# A fixture is a scenario stated as `key: value` lines. Three kinds:
#
#   disclosure/  what a phase may load on one branch, and what it may not
#   invocation/  which skills the two agent tools may trigger implicitly
#   output/      what a phase's chat report must contain, and its word cap
#
# These are STRUCTURAL proofs over the skill texts, not live-agent runs: they
# prove the suite is SHAPED so that only the intended files are reachable and
# only the intended skills are implicitly invocable. Whether a given model then
# obeys the shape is the manual acceptance item on the Epic, not something a
# deterministic check can assert.

fx_get() { sed -n "s/^$2: *//p" "$1" | head -1; }

run_fixtures() {
  local fx kind

  # --- disclosure -----------------------------------------------------------
  # Every `loads` reference must be an arrow pointer from SKILL.md whose stated
  # condition names this branch; every `forbids` reference must be a real
  # pointer whose condition names NONE of this branch's words. That is what
  # makes an unrelated branch's file unreachable rather than merely unmentioned.
  for fx in "$root"/fixtures/disclosure/*.fixture; do
    [ -e "$fx" ] || break
    local name skill when ref cond hit
    name="$(fx_get "$fx" name)"; skill="$(fx_get "$fx" skill)"
    when="$(fx_get "$fx" when)"
    kind="skill_progressive_disclosure/$name"

    if [ ! -f "$root/$skill/SKILL.md" ]; then
      fail "$kind" bad-fixture "no such skill: $skill"; continue
    fi

    for ref in $(fx_get "$fx" loads); do
      cond="$(pointer_condition "$root/$skill/SKILL.md" "$ref")"
      if [ -z "$cond" ]; then
        fail "$kind" not-loadable "$skill/$ref has no conditional pointer"
        continue
      fi
      hit=no
      for w in $when; do case "$cond" in *"$w"*) hit=yes ;; esac; done
      [ "$hit" = yes ] || fail "$kind" condition-misses-branch \
        "$skill/$ref condition '$(printf '%s' "$cond" | sed 's/^ *//')' names none of: $when"
    done

    for ref in $(fx_get "$fx" forbids); do
      cond="$(pointer_condition "$root/$skill/SKILL.md" "$ref")"
      if [ -z "$cond" ]; then
        fail "$kind" bad-fixture "$skill/$ref is not a pointer, so forbidding it is vacuous"
        continue
      fi
      for w in $when; do
        case "$cond" in *"$w"*)
          fail "$kind" leaks-on-unrelated-branch \
            "$skill/$ref condition matches '$w', so it loads on this branch" ;;
        esac
      done
    done
  done

  # --- invocation -----------------------------------------------------------
  # One frontmatter declares the policy and BOTH tools read it: Claude Code
  # honours `disable-model-invocation`, and the codex CLI reads the same
  # SKILL.md from ~/.codex/skills. The paired agents/openai.yaml is what makes
  # the skill explicitly reachable in codex, so an implicit skill needs both.
  for fx in "$root"/fixtures/invocation/*.fixture; do
    [ -e "$fx" ] || break
    local name skill want disabled desc trig
    name="$(fx_get "$fx" name)"; skill="$(fx_get "$fx" skill)"
    want="$(fx_get "$fx" invocation)"
    kind="skill_invocation_policy/$name"

    if [ ! -f "$root/$skill/SKILL.md" ]; then
      fail "$kind" bad-fixture "no such skill: $skill"; continue
    fi
    disabled="$(fm_value "$root/$skill/SKILL.md" disable-model-invocation)"
    case "$want" in
      implicit) [ "$disabled" = true ] &&
        fail "$kind" wrong-policy "$skill is explicit-only but the fixture expects implicit" ;;
      explicit) [ "$disabled" = true ] ||
        fail "$kind" wrong-policy "$skill is model-invocable but the fixture expects explicit-only" ;;
      *) fail "$kind" bad-fixture "invocation must be implicit or explicit, got '$want'" ;;
    esac

    # Branch-complete description: every trigger the fixture says must reach
    # this skill has to be findable in the description both tools match on.
    desc="$(fm_value "$root/$skill/SKILL.md" description | tr 'A-Z' 'a-z')"
    while IFS= read -r trig; do
      [ -n "$trig" ] || continue
      case "$desc" in *"$trig"*) ;; *)
        fail "$kind" description-misses-trigger "'$trig' is not in $skill's description" ;;
      esac
    done < <(fx_get "$fx" triggers | tr ',' '\n' | sed 's/^ *//; s/ *$//' | tr 'A-Z' 'a-z')

    [ -f "$root/$skill/agents/openai.yaml" ] ||
      fail "$kind" codex-parity "$skill has no agents/openai.yaml, so codex cannot reach it"
  done

  # --- output ---------------------------------------------------------------
  for fx in "$root"/fixtures/output/*.fixture; do
    [ -e "$fx" ] || break
    local name skill limit section req
    name="$(fx_get "$fx" name)"; skill="$(fx_get "$fx" skill)"
    limit="$(fx_get "$fx" limit)"
    kind="skill_output_contracts/$name"

    if [ ! -f "$root/$skill/SKILL.md" ]; then
      fail "$kind" bad-fixture "no such skill: $skill"; continue
    fi
    section="$(awk '/^## Output$/{o=1;next} /^## /{o=0} o' "$root/$skill/SKILL.md")"
    if [ -z "$(printf '%s' "$section" | tr -d '[:space:]')" ]; then
      fail "$kind" missing-output-contract "$skill/SKILL.md has no '## Output' section"
      continue
    fi
    if [ -n "$limit" ]; then
      case "$section" in *"$limit words"*) ;; *)
        fail "$kind" missing-output-limit "$skill's Output section does not state '$limit words'" ;;
      esac
    fi
    while IFS= read -r req; do
      [ -n "$req" ] || continue
      case "$(printf '%s' "$section" | tr 'A-Z' 'a-z')" in *"$req"*) ;; *)
        fail "$kind" missing-output-element "$skill's Output section does not name '$req'" ;;
      esac
    done < <(fx_get "$fx" requires | tr ',' '\n' | sed 's/^ *//; s/ *$//' | tr 'A-Z' 'a-z')
  done
}
