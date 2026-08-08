#!/usr/bin/env bash
# Cheap structural checks for agent skills.
# Exit 0 when clean, 1 with findings.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
findings=0

fail() {
  printf '%s: %s\n' "$1" "$2" >&2
  findings=$((findings + 1))
}

body_of() {
  awk 'NR==1&&$0=="---"{fm=1;next} fm==1&&$0=="---"{fm=2;next} fm==2' "$1"
}

frontmatter_of() {
  awk 'NR==1&&$0=="---"{fm=1;next} fm==1&&$0=="---"{exit} fm==1' "$1"
}

fm_value() {
  frontmatter_of "$1" | sed -n "s/^$2: *//p" | head -1
}

word_count() {
  wc -w | tr -d ' '
}

# Body word budgets. Keep skills intentionally small.
budget_for() {
  case "$1" in
    understand) echo 250 ;;
    plan)       echo 250 ;;
    work)       echo 250 ;;
    review)     echo 250 ;;
    compound)   echo 250 ;;
    sprout)     echo 250 ;;
    *)          echo 250 ;;
  esac
}

TYPOGRAPHIC='\xe2\x80\x93|\xe2\x80\x94|\xe2\x80\x98|\xe2\x80\x99|\xe2\x80\x9c|\xe2\x80\x9d|\xe2\x80\xa6|\xe2\x86\x90|\xe2\x86\x92|\xe2\x87\x92|\xe2\x80\xa2|\xc2\xa0|\xc3\x97'

skills=0

while IFS= read -r f; do
  skills=$((skills + 1))
  dir="$(dirname "$f")"
  skill="$(basename "$dir")"
  rel="${f#"$root"/}"

  # Minimal frontmatter contract.
  head -1 "$f" | grep -qx -- '---' ||
    fail "$rel" "missing YAML frontmatter"

  name="$(fm_value "$f" name)"
  desc="$(fm_value "$f" description)"

  [ "$name" = "$skill" ] ||
    fail "$rel" "name '$name' does not match directory '$skill'"

  [ -n "$desc" ] ||
    fail "$rel" "missing description"

  desc_words="$(printf '%s' "$desc" | word_count)"
  [ "$desc_words" -le 20 ] ||
    fail "$rel" "description is $desc_words words; max 20"

  body_words="$(body_of "$f" | word_count)"
  budget="$(budget_for "$skill")"
  [ "$body_words" -le "$budget" ] ||
    fail "$rel" "body is $body_words words; max $budget"

  # AGENTS.md requires ASCII-adjacent writing.
  line="$(LC_ALL=C grep -nP "$TYPOGRAPHIC" "$f" 2>/dev/null | head -1)"
  [ -z "$line" ] ||
    fail "$rel" "typographic character at line ${line%%:*}"

  # Codex/OpenAI UI metadata is expected for every skill.
  openai="$dir/agents/openai.yaml"
  if [ ! -f "$openai" ]; then
    fail "$skill" "missing agents/openai.yaml"
  else
    for key in display_name short_description default_prompt; do
      grep -q "^  $key:" "$openai" ||
        fail "${openai#"$root"/}" "missing interface.$key"
    done
  fi
done < <(find "$root" -mindepth 2 -maxdepth 2 -name SKILL.md | sort)

[ "$skills" -gt 0 ] || fail skills "no */SKILL.md found"

if [ "$findings" -gt 0 ]; then
  printf '\n%d finding(s)\n' "$findings" >&2
  exit 1
fi

printf 'skills: clean (%d skills)\n' "$skills"
