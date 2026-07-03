#!/usr/bin/env bash
# install.sh — wire the orchestrator hooks into your hub's Claude Code settings.
#
# What it does:
#   1. Asks for (or takes as $1) your HUB_DIR — the "brain" project that orchestrates.
#   2. Copies hooks/ + scripts/ into the hub (so paths are self-contained), or you
#      can point at this repo in place with --in-place.
#   3. Persists HUB_DIR to your shell rc so hooks and spoke-onboard.sh can read it.
#   4. Merges the hub-side hooks into $HUB_DIR/.claude/settings.json (creating it if
#      absent; backing it up first; never clobbering unrelated keys).
#
# Usage:
#   ./install.sh /path/to/your/hub
#   ./install.sh /path/to/your/hub --in-place   # don't copy; reference this repo dir
#
# This is Claude-Code-specific (it wires Claude Code hooks). Non-Claude-Code users:
# take the methodology from README.md / docs/ and skip this.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_DIR=""
IN_PLACE=0
# Accept --in-place in any argument position; first non-flag arg is HUB_DIR.
for arg in "$@"; do
  case "$arg" in
    --in-place) IN_PLACE=1 ;;
    *) [ -z "$HUB_DIR" ] && HUB_DIR="$arg" ;;
  esac
done

if [ -z "$HUB_DIR" ]; then
  printf "Enter the absolute path to your HUB_DIR (the brain/orchestrator project): "
  read -r HUB_DIR
fi
HUB_DIR="${HUB_DIR%/}"
if [ ! -d "$HUB_DIR" ]; then
  echo "ERROR: '$HUB_DIR' is not a directory. Create it first (mkdir -p) then re-run."
  exit 1
fi

# 1. Decide where hooks live.
if [ "$IN_PLACE" -eq 1 ]; then
  HOOKS_DIR="$REPO_DIR/hooks"
  SCRIPTS_DIR="$REPO_DIR/scripts"
  echo "Using hooks in place: $HOOKS_DIR"
else
  HOOKS_DIR="$HUB_DIR/hooks"
  SCRIPTS_DIR="$HUB_DIR/scripts"
  mkdir -p "$HOOKS_DIR" "$SCRIPTS_DIR"
  cp "$REPO_DIR"/hooks/*.sh "$HOOKS_DIR"/
  # Only copy the tracked-projects template if the hub doesn't already have one.
  [ -f "$HOOKS_DIR/tracked-projects.txt" ] || cp "$REPO_DIR/hooks/tracked-projects.txt" "$HOOKS_DIR/"
  cp "$REPO_DIR"/scripts/*.sh "$SCRIPTS_DIR"/
  chmod +x "$HOOKS_DIR"/*.sh "$SCRIPTS_DIR"/*.sh
  echo "Copied hooks -> $HOOKS_DIR and scripts -> $SCRIPTS_DIR"
fi

SYNC="$HOOKS_DIR/canonical-sync.sh"
WRITE_GUARD="$HOOKS_DIR/canonical-write-guard.sh"
NO_HANDS="$HOOKS_DIR/orchestrator-no-hands-guard.sh"
STATUS_DIGEST="$HOOKS_DIR/project-status-digest.sh"
WRITEBACK_GATE="$HOOKS_DIR/status-writeback-gate.sh"
REGISTRY_DIGEST="$HOOKS_DIR/worker-registry-digest.sh"
REUSE_GUARD="$HOOKS_DIR/reuse-check-guard.sh"
REGISTRY_WRITE="$HOOKS_DIR/worker-registry-write.sh"

# 2. Persist HUB_DIR (and, for --in-place, HOOKS_DIR) to shell rc.
# In-place mode keeps hooks in this repo dir, which is NOT the default
# $HUB_DIR/hooks config.sh would derive — so HOOKS_DIR must be persisted too,
# or spoke-onboard.sh would point spokes at a non-existent hooks dir.
RC="$HOME/.zshrc"
[ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ] && RC="$HOME/.bashrc"
LINE="export HUB_DIR=\"$HUB_DIR\"   # orchestrator-oss"
if [ "$IN_PLACE" -eq 1 ]; then
  LINE="$LINE"$'\n'"export HOOKS_DIR=\"$HOOKS_DIR\"   # orchestrator-oss"
fi
if grep -q "# orchestrator-oss" "$RC" 2>/dev/null; then
  echo "HUB_DIR already in $RC (leaving as-is; edit manually to change)."
else
  printf '\n%s\n' "$LINE" >> "$RC"
  [ "$IN_PLACE" -eq 1 ] && extra=" + HOOKS_DIR" || extra=""
  echo "Added HUB_DIR$extra to $RC (run 'source $RC' or open a new shell)."
fi
export HUB_DIR
[ "$IN_PLACE" -eq 1 ] && export HOOKS_DIR

# 3. Merge hooks into $HUB_DIR/.claude/settings.json.
SETTINGS="$HUB_DIR/.claude/settings.json"
mkdir -p "$HUB_DIR/.claude"
[ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)" && echo "Backed up existing settings.json"

python3 - "$SETTINGS" "$SYNC" "$WRITE_GUARD" "$NO_HANDS" "$STATUS_DIGEST" "$WRITEBACK_GATE" "$REGISTRY_DIGEST" "$REUSE_GUARD" "$REGISTRY_WRITE" <<'PY'
import json, os, sys
(settings_path, sync, write_guard, no_hands, status_digest, writeback_gate,
 registry_digest, reuse_guard, registry_write) = sys.argv[1:10]

data = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path) as f:
            data = json.load(f)
    except Exception:
        data = {}
hooks = data.setdefault("hooks", {})

def cmd(path, **extra):
    h = {"type": "command", "command": path, "timeout": extra.get("timeout", 15)}
    if "statusMessage" in extra:
        h["statusMessage"] = extra["statusMessage"]
    return h

def ensure(event, matcher, command, **extra):
    """Add a command hook for (event, matcher) only if that exact command isn't present."""
    entries = hooks.setdefault(event, [])
    # find an entry with the same matcher (or no matcher)
    target = None
    for e in entries:
        if e.get("matcher", None) == matcher:
            target = e
            break
    if target is None:
        target = {"hooks": []}
        if matcher is not None:
            target["matcher"] = matcher
        entries.append(target)
    if any(h.get("command") == command for h in target.get("hooks", [])):
        return
    target.setdefault("hooks", []).append(cmd(command, **extra))

ensure("SessionStart", None, status_digest, timeout=30, statusMessage="Pulling tracked-project status…")
ensure("SessionStart", None, sync, timeout=15, statusMessage="Syncing canonical…")
ensure("SessionStart", None, registry_digest, timeout=15, statusMessage="Surfacing reusable workers…")
ensure("UserPromptSubmit", None, sync, timeout=15)
ensure("PreToolUse", "Write", write_guard, timeout=10)
ensure("PreToolUse", "Write|Edit|Bash", no_hands, timeout=10)
ensure("PreToolUse", "mcp__.*", no_hands, timeout=10)
ensure("PreToolUse", "Task|Agent", reuse_guard, timeout=10)
ensure("PostToolUse", "Task|Agent", registry_write, timeout=10)
ensure("Stop", None, writeback_gate, timeout=30, statusMessage="STATUS write-back gate…")

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("Wrote hooks into", settings_path)
PY

echo
echo "Done. Next:"
echo "  1) source your shell rc (or open a new shell) so HUB_DIR is set."
echo "  2) edit $HOOKS_DIR/tracked-projects.txt to list your spoke projects."
echo "  3) run: $SCRIPTS_DIR/spoke-onboard.sh /path/to/a/project"
