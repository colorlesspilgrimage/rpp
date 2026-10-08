#!/usr/bin/env bash
# Copies installed RPP pipeline files back into this repo. Used by rpp-feedback.
# Keeps this repo's default model: lines, so per-user model choices never get committed.
# Usage: ./sync-back.sh FILE...   FILE is rpp-<name>.md or SKILL.md
# Install dir: $PI_CODING_AGENT_DIR or ~/.omp/agent
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
[ "$#" -gt 0 ] || { echo "usage: $0 FILE..." >&2; exit 2; }

for f in "$@"; do
  case "$f" in
    SKILL.md) src="$AGENT_DIR/skills/rpp/SKILL.md"; dest="$HERE/skills/rpp/SKILL.md" ;;
    rpp-feedback.md) echo "refusing to sync rpp-feedback.md" >&2; exit 1 ;;
    rpp-*.md) src="$AGENT_DIR/agents/$f"; dest="$HERE/agents/$f" ;;
    *) echo "unknown file: $f" >&2; exit 1 ;;
  esac
  [ -f "$src" ] || { echo "missing: $src" >&2; exit 1; }
  model="$(sed -n 's/^model: *//p' "$dest" 2>/dev/null | head -n1)"
  cp "$src" "$dest"
  [ -n "$model" ] && sed -i "s|^model: .*\$|model: $model|" "$dest"
  echo "synced $f"
done
