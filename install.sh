#!/usr/bin/env bash
# Installs the RPP agents and skill for the current user.
# Prompts for the model of each agent. Press Enter to keep the model shown in brackets.
# Choices that differ from the repo default are saved in $AGENT_DIR/rpp-models.conf and reused on the next
# install. Without a terminal (piped input, CI, rpp-feedback), saved choices are kept and other agents get the default.
# Usage: ./install.sh        Install dir: $PI_CODING_AGENT_DIR or ~/.omp/agent
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
CONF="$AGENT_DIR/rpp-models.conf"
RETIRED="rpp-locreducer rpp-commentcleaner"

mkdir -p "$AGENT_DIR/agents" "$AGENT_DIR/skills/rpp"
touch "$CONF"
cp "$HERE/skills/rpp/SKILL.md" "$AGENT_DIR/skills/rpp/SKILL.md"
for name in $RETIRED; do rm -f "$AGENT_DIR/agents/$name.md"; done

# Replaces each "<!-- include: name -->" line with agents/_common/name.md.
expand() {
  local line part
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^\<!--\ include:\ ([a-z-]+)\ --\>$ ]]; then
      part="$HERE/agents/_common/${BASH_REMATCH[1]}.md"
      [ -f "$part" ] || { echo "missing include: $part (in $1)" >&2; exit 1; }
      cat "$part"
    else
      printf '%s\n' "$line"
    fi
  done < "$1"
}

INTERACTIVE=0
[ -t 0 ] && INTERACTIVE=1
[ "$INTERACTIVE" = 1 ] && echo "Choose a model for each agent. Press Enter to keep the model shown. (List models: omp --list-models)"

for src in "$HERE"/agents/rpp-*.md; do
  name="$(basename "$src" .md)"
  dest="$AGENT_DIR/agents/$name.md"
  default="$(sed -n 's/^model: *//p' "$src" | head -n1)"
  saved="$(sed -n "s/^$name=//p" "$CONF" | head -n1)"
  desc="$(sed -n 's/^description: *//p' "$src" | head -n1)"
  choice="${saved:-$default}"
  if [ "$INTERACTIVE" = 1 ]; then
    while true; do
      printf '\n%s\n  %s\n  model [%s]: ' "$name" "$desc" "${saved:-$default}"
      read -r answer || answer=""
      answer="${answer//[[:space:]]/}"
      choice="${answer:-${saved:-$default}}"
      if ! printf '%s' "$choice" | grep -Eq '^[A-Za-z0-9._:/@+-]+$'; then
        echo "  Invalid model id. Try again."
      else
        break
      fi
    done
  fi
  sed -i "/^$name=/d" "$CONF"
  [ "$choice" != "$default" ] && echo "$name=$choice" >> "$CONF"
  expand "$src" > "$dest"
  sed -i "s|^model: .*\$|model: $choice|" "$dest"
done
# rpp-feedback edits this repo and re-runs this installer, so it needs both paths.
sed -i -e "s|__RPP_SOURCE__|$HERE|" -e "s|__AGENT_DIR__|$AGENT_DIR|" "$AGENT_DIR/agents/rpp-feedback.md"

echo
echo "Installed to $AGENT_DIR. Models in use:"
grep -H '^model:\|^thinkingLevel:' "$AGENT_DIR"/agents/rpp-*.md | sed "s#$AGENT_DIR/agents/##"
echo "Check: start omp, then run /agents and confirm ten rpp-* agents are listed."
