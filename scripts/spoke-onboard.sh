#!/usr/bin/env bash
# spoke-onboard.sh <project-root> — bring a project up to the "spoke contract".
# Idempotent: creates what's missing, never touches what exists, never overwrites.
# Prints "done / still needs manual" at the end.
# See ORCHESTRATOR.md "Spoke contract".
#
# Auto-fills: STATUS.md skeleton / docs/first-principles.md placeholder /
#   .claude/settings.json wired to canonical-sync + concurrency guard /
#   registration into tracked-projects.txt
# Manual: the real content of (1) canonical pointer and (3) asset registry in
#   CLAUDE.md, filling first-principles for real, one line in projects.md
#
# Requires HUB_DIR in the environment (run install.sh first, or export it).

set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# config.sh lives in hooks/, one level up from scripts/
# shellcheck source=/dev/null
. "$HERE/../hooks/config.sh" 2>/dev/null || true

if [ -z "${HUB_DIR:-}" ]; then
  echo "ERROR: HUB_DIR is not set. Run install.sh or 'export HUB_DIR=/path/to/your/hub' first."
  exit 1
fi

SYNC="${HOOKS_DIR%/}/canonical-sync.sh"
GUARD="${HOOKS_DIR%/}/canonical-write-guard.sh"
TRACKED="$TRACKED_FILE"

proj="${1:-}"
if [ -z "$proj" ] || [ ! -d "$proj" ]; then
  echo "usage: spoke-onboard.sh <existing-project-root>"; exit 1
fi
proj="$(cd "$proj" && pwd)"   # normalize to absolute path
name="$(basename "$proj")"
did=(); todo=()

# (4) STATUS.md
if [ -f "$proj/STATUS.md" ]; then
  todo+=("STATUS.md already exists, untouched (confirm it has \`- [ ]\` todos for the hub to read)")
else
  cat > "$proj/STATUS.md" <<EOF
# STATUS · $name

> The hub reads this file live on SessionStart. Todos use \`- [ ]\`. The hub writes it back after sign-off.

## Current state
(fill in: where this project stands right now)

## Todos
- [ ] (fill in)
EOF
  did+=("created STATUS.md skeleton")
fi

# (2) docs/first-principles.md
mkdir -p "$proj/docs" 2>/dev/null
if [ -f "$proj/${SPOKE_CANONICAL}" ]; then
  todo+=("${SPOKE_CANONICAL} already exists, untouched")
else
  mkdir -p "$(dirname "$proj/${SPOKE_CANONICAL}")" 2>/dev/null
  cat > "$proj/${SPOKE_CANONICAL}" <<EOF
# $name first principles (PLACEHOLDER — fill in)

> The single home of this project's operable decision rules for build workers;
> CLAUDE.md should \`@import\` it. The authoritative strategy lives in the hub;
> this is the operable projection — reference, don't copy. canonical-sync injects
> it to running sessions on change.

**WHY (fill in: this project's first-principles goal)**

**Decision gates — pass these before acting (fill in):**
1. (fill in)

(Placeholder. Don't let a worker make big decisions from this until it's filled.)
EOF
  did+=("created ${SPOKE_CANONICAL} placeholder")
  todo+=("fill ${SPOKE_CANONICAL} for real + \`@${SPOKE_CANONICAL}\` at the top of CLAUDE.md")
fi

# (5) .claude/settings.json (canonical-sync + concurrency guard)
mkdir -p "$proj/.claude" 2>/dev/null
SETTINGS="$proj/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if grep -q "canonical-sync.sh" "$SETTINGS" 2>/dev/null; then
    todo+=("settings.json already wired to canonical-sync, untouched")
  else
    todo+=("WARNING: settings.json exists but isn't wired to canonical-sync — manually merge SessionStart/UserPromptSubmit -> canonical-sync.sh + PreToolUse(Write) -> canonical-write-guard.sh (don't clobber existing hooks)")
  fi
else
  cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "$SYNC", "timeout": 15, "statusMessage": "Syncing first-principles canonical…" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "$SYNC", "timeout": 15 } ] }
    ],
    "PreToolUse": [
      { "matcher": "Write", "hooks": [ { "type": "command", "command": "$GUARD", "timeout": 10 } ] }
    ]
  }
}
EOF
  did+=("created .claude/settings.json (canonical-sync + concurrency guard)")
fi

# (6) register in tracked-projects.txt
if grep -qxF "$proj" "$TRACKED" 2>/dev/null; then
  todo+=("tracked-projects.txt already registered, untouched")
else
  printf '%s\n' "$proj" >> "$TRACKED"
  did+=("registered in tracked-projects.txt")
fi

# (1) / (3) CLAUDE.md check (advisory only, never auto-edits)
if [ -f "$proj/CLAUDE.md" ]; then
  grep -qi "canonical pointer" "$proj/CLAUDE.md" 2>/dev/null || todo+=("CLAUDE.md missing a 'Canonical pointer' section — add manually (contract 1)")
  grep -qi "asset registry" "$proj/CLAUDE.md" 2>/dev/null || todo+=("CLAUDE.md missing an 'Asset registry' section — add manually (contract 3)")
else
  todo+=("WARNING: no CLAUDE.md — a spoke needs at least this (home of contract 1/2/3)")
fi
todo+=("add one line in projects.md (the manual half of contract 6)")

# Report
echo "== spoke-onboard: $name =="
echo "path: $proj"
echo
echo "DONE:"
if [ ${#did[@]} -eq 0 ]; then echo "  (none — all already in place)"; else for x in "${did[@]}"; do echo "  - $x"; done; fi
echo
echo "STILL NEEDS MANUAL:"
if [ ${#todo[@]} -eq 0 ]; then echo "  (none)"; else for x in "${todo[@]}"; do echo "  - $x"; done; fi
