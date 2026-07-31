# Fixture runner, sourced by check.sh. Uses its `root`, `fail` and `findings`.
#
# A fixture is a scenario stated as `key: value` lines. Four kinds:
#
#   disclosure/  what a phase may load on one branch, and what it may not
#   invocation/  which skills the two agent tools may trigger implicitly
#   output/      what a phase's chat report must contain, and its word cap
#   content/     which rules a reference file or section must actually state
#
# These are STRUCTURAL proofs over the skill texts, not live-agent runs: they
# prove the suite is SHAPED so that only the intended files are reachable and
# only the intended skills are implicitly invocable. Whether a given model then
# obeys the shape is the manual acceptance item on the Epic, not something a
# deterministic check can assert.

fx_get() { sed -n "s/^$2: *//p" "$1" | head -1; }

# `run_fixtures [name]` runs every case, or only the case(s) whose `name:` is
# exactly `name`. It sets `fixtures_matched` so `check.sh --fixture` can tell a
# clean run from a typo that matched nothing.
fx_skip() { [ -n "$1" ] && [ "$1" != "$2" ]; }

run_fixtures() {
  local fx kind filter="${1-}"
  fixtures_matched=0

  # --- disclosure -----------------------------------------------------------
  # Every `loads` reference must be an arrow pointer from SKILL.md whose stated
  # condition names this branch; every `forbids` reference must be a real
  # pointer whose condition names NONE of this branch's words. That is what
  # makes an unrelated branch's file unreachable rather than merely unmentioned.
  for fx in "$root"/fixtures/disclosure/*.fixture; do
    [ -e "$fx" ] || break
    local name skill when ref cond hit
    name="$(fx_get "$fx" name)"; skill="$(fx_get "$fx" skill)"
    fx_skip "$filter" "$name" && continue
    fixtures_matched=$((fixtures_matched + 1))
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
    fx_skip "$filter" "$name" && continue
    fixtures_matched=$((fixtures_matched + 1))
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
    fx_skip "$filter" "$name" && continue
    fixtures_matched=$((fixtures_matched + 1))
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

  # --- content --------------------------------------------------------------
  # The other three kinds prove a file is REACHABLE on its branch, fits its
  # budget and is pointed at under a stated condition. None of them can see
  # whether it still says the thing it exists to say: a reference can keep its
  # pointer, its condition and its word count while the rule inside it is
  # rewritten away. A content case names the file (and optionally one `##`
  # section) plus the elements that rule is made of.
  #
  #   name: <case>          skill: <dir>          file: <SKILL.md|reference.md>
  #   section: <heading text without the ##>      (optional; whole file if absent)
  #   requires: <substring>, <substring>, ...     (all must appear)
  #   forbids:  <substring>, ...                  (none may appear)
  #
  # Matching is case-insensitive substring, so a case asserts vocabulary, not
  # phrasing - it survives an edit that rewords the prose around the rule and
  # fails the one that drops the rule.
  for fx in "$root"/fixtures/content/*.fixture; do
    [ -e "$fx" ] || break
    local name skill file heading text lc req
    name="$(fx_get "$fx" name)"; skill="$(fx_get "$fx" skill)"
    fx_skip "$filter" "$name" && continue
    fixtures_matched=$((fixtures_matched + 1))
    file="$(fx_get "$fx" file)"; heading="$(fx_get "$fx" section)"
    kind="skill_content/$name"

    if [ ! -d "$root/$skill" ]; then
      fail "$kind" bad-fixture "no such skill: $skill"; continue
    fi
    if [ -z "$file" ] || [ ! -f "$root/$skill/$file" ]; then
      fail "$kind" bad-fixture "no such file: $skill/${file:-<unset>}"; continue
    fi
    # A case with neither list asserts nothing and still prints `ok`, which is
    # worse than no case at all when a DoD proof names it.
    if [ -z "$(fx_get "$fx" requires)$(fx_get "$fx" forbids)" ]; then
      fail "$kind" bad-fixture "states no requires: or forbids:, so it asserts nothing"
      continue
    fi

    if [ -n "$heading" ]; then
      text="$(section_of "$root/$skill/$file" "$heading")"
      if [ -z "$(printf '%s' "$text" | tr -d '[:space:]')" ]; then
        fail "$kind" bad-fixture "$skill/$file has no '## $heading' section"; continue
      fi
    else
      text="$(cat "$root/$skill/$file")"
    fi
    lc="$(printf '%s' "$text" | tr 'A-Z' 'a-z')"

    while IFS= read -r req; do
      [ -n "$req" ] || continue
      case "$lc" in *"$req"*) ;; *)
        fail "$kind" missing-content-element \
          "$skill/$file${heading:+ (## $heading)} does not state '$req'" ;;
      esac
    done < <(fx_get "$fx" requires | tr ',' '\n' | sed 's/^ *//; s/ *$//' | tr 'A-Z' 'a-z')

    while IFS= read -r req; do
      [ -n "$req" ] || continue
      case "$lc" in *"$req"*)
        fail "$kind" forbidden-content-element \
          "$skill/$file${heading:+ (## $heading)} still says '$req'" ;;
      esac
    done < <(fx_get "$fx" forbids | tr ',' '\n' | sed 's/^ *//; s/ *$//' | tr 'A-Z' 'a-z')
  done
}
