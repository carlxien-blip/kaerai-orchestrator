#!/usr/bin/env bash
# config.sh — shared config sourced by every hook. Nothing here is hard-coded to
# a machine; everything reads from environment variables (set by install.sh into
# your ~/.zshrc / ~/.bashrc, or exported in your shell).
#
# Required:
#   HUB_DIR   — absolute path to your hub (the "brain" project that orchestrates).
#
# Optional (sensible defaults derived from HUB_DIR):
#   HOOKS_DIR        — where these hook scripts live. Default: $HUB_DIR/hooks
#   TRACKED_FILE     — newline list of spoke project roots the hub tracks.
#                      Default: $HOOKS_DIR/tracked-projects.txt
#   HUB_CANONICAL    — the hub's living-brief file synced across sessions.
#                      Default: $HUB_DIR/current_state.md
#   SPOKE_CANONICAL  — relative path, inside each spoke, of that spoke's
#                      operable canonical that canonical-sync injects.
#                      Default: docs/first-principles.md
#   SYNC_STATE_DIR   — where canonical-sync remembers per-session mtimes.
#                      Default: $HOME/.claude/canonical-sync-state
#
# Hooks fail safe: if HUB_DIR is unset, hooks exit 0 silently (never break a session).

: "${HUB_DIR:=}"
: "${HOOKS_DIR:=${HUB_DIR%/}/hooks}"
: "${TRACKED_FILE:=${HOOKS_DIR%/}/tracked-projects.txt}"
: "${HUB_CANONICAL:=${HUB_DIR%/}/current_state.md}"
: "${SPOKE_CANONICAL:=docs/first-principles.md}"
: "${SYNC_STATE_DIR:=${HOME}/.claude/canonical-sync-state}"

# Helper: read a JSON field from stdin payload already captured in $1 (the input),
# field name in $2. Prints empty string on any error.
hook_json_get() {
  printf '%s' "$1" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('$2',''))
except Exception: print('')" 2>/dev/null
}

# Helper: read a nested tool_input field. $1=input, $2=field.
hook_tool_input_get() {
  printf '%s' "$1" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_input',{}).get('$2',''))
except Exception: print('')" 2>/dev/null
}

# Helper: is $1 (a path) the hub dir (or inside it)?
hook_is_hub() {
  [ -n "$HUB_DIR" ] || return 1
  case "$1" in "$HUB_DIR"|"$HUB_DIR"/*) return 0 ;; *) return 1 ;; esac
}
