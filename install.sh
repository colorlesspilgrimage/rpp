#!/usr/bin/env bash
# Installs the RPP agents and skill for the current user.
# Prompts for the model of each agent. Press Enter to keep the default shown in brackets.
# Without a terminal (piped input, CI), every agent keeps its default model.
# Usage: ./install.sh        Install dir: $PI_CODING_AGENT_DIR or ~/.omp/agent
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"

mkdir -p "$AGENT_DIR/agents" "$AGENT_DIR/skills/rpp"
cp "$HERE"/agents/rpp-*.md "$AGENT_DIR/agents/"
cp "$HERE/skills/rpp/SKILL.md" "$AGENT_DIR/skills/rpp/SKILL.md"

INTERACTIVE=0
[ -t 0 ] && INTERACTIVE=1
[ "$INTERACTIVE" = 1 ] && echo "Choose a model for each agent. Press Enter to keep the default. (List models: omp --list-models)"

for src in "$HERE"/agents/rpp-*.md; do
  name="$(basename "$src" .md)"
  dest="$AGENT_DIR/agents/$name.md"
  default="$(sed -n 's/^model: *//p' "$src" | head -n1)"
  desc="$(sed -n 's/^description: *//p' "$src" | head -n1)"
  choice="$default"
  if [ "$INTERACTIVE" = 1 ]; then
    while true; do
      printf '\n%s\n  %s\n  model [%s]: ' "$name" "$desc" "$default"
      read -r answer || answer=""
      answer="${answer//[[:space:]]/}"
      choice="${answer:-$default}"
      if ! printf '%s' "$choice" | grep -Eq '^[A-Za-z0-9._:/@+-]+$'; then
        echo "  Invalid model id. Try again."
      else
        break
      fi
    done
  fi
  sed -i "s|^model: .*\$|model: $choice|" "$dest"
done

echo
echo "Installed to $AGENT_DIR. Models in use:"
grep -H '^model:\|^thinkingLevel:' "$AGENT_DIR"/agents/rpp-*.md | sed "s#$AGENT_DIR/agents/##"
echo "Check: start omp, then run /agents and confirm nine rpp-* agents are listed."
