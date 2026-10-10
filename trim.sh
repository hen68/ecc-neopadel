#!/usr/bin/env bash
#
# trim.sh — curate a LOCAL, OWNED ECC plugin clone down to a keep-list.
#
# Trims skills/, agents/, commands/, rules/ (deletes everything not listed below).
# Never touches scripts/, hooks/, contexts/, .claude-plugin/, node_modules/,
# package.json, mcp-configs/, .mcp.json, etc. — the instinct loop depends on those.
#
# Idempotent + keep-list driven: edit the arrays, re-run after `git pull`.
#
# Usage:
#   bash trim.sh             # DRY RUN — prints what WOULD be deleted, changes nothing
#   bash trim.sh --apply     # actually delete
#
set -euo pipefail

# --- resolve to the clone this script lives in --------------------------------
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- safety guards ------------------------------------------------------------
if [[ ! -f "$ROOT/.claude-plugin/plugin.json" ]]; then
  echo "ERROR: $ROOT is not an ECC plugin clone (.claude-plugin/plugin.json missing)." >&2
  exit 1
fi
case "$ROOT" in
  */.claude/plugins/*)
    echo "ERROR: refusing to run inside the managed plugin cache ($ROOT)." >&2
    echo "       Trim your OWNED clone (e.g. ~/dev/ecc-curated-v2), not ~/.claude/plugins." >&2
    exit 1 ;;
esac

APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

# ==============================================================================
# KEEP-LISTS  —  edit these to taste, then re-run.
# Anything NOT listed in the matching array gets deleted.
# ==============================================================================

# --- SKILLS (directories under skills/) ---------------------------------------
# Base curation (carried from v1) + adopted v2.0.0 additions across four groups:
#   agent-harness/eval, ECC self-mgmt/orchestration, frontend/design/a11y, JS backend/DB.
KEEP_SKILLS=(
  # v2.2.8 prune (Neopadel /context audit): only what the monorepo uses; do not re-add without a reason
  continuous-learning-v2 motion-foundations react-performance santa-method seo
)

# --- AGENTS (*.md under agents/) ----------------------------------------------
KEEP_AGENTS=(
  # v2.2.8 prune (Neopadel /context audit): only what the monorepo uses; do not re-add without a reason
  code-explorer code-reviewer database-reviewer planner react-reviewer security-reviewer seo-specialist typescript-reviewer
)

# --- COMMANDS (*.md under commands/) ------------------------------------------
KEEP_COMMANDS=(
  # v2.2.8 prune (Neopadel /context audit): only what the monorepo uses; do not re-add without a reason
  auto-update evolve orch-review resume-session santa-loop save-session setup-pm
)

# --- RULES (directories under rules/) -----------------------------------------
# Stack the team actually touches + your local zh addition. README.md left in place.
# No Python anywhere in the monorepo (Babel/JS backend, Mongoose not Postgres/Prisma) — dropped.
KEEP_RULES=(
  common typescript react web react-native swift kotlin
)

# ==============================================================================
# engine — do not edit below
# ==============================================================================
in_list() { local x="$1"; shift; local e; for e in "$@"; do [[ "$e" == "$x" ]] && return 0; done; return 1; }

trim_dir() { # $1=subdir  $2=mode(dir|md)  rest=keep-list
  local sub="$1" mode="$2"; shift 2
  local path="$ROOT/$sub"
  [[ -d "$path" ]] || { echo "  (skip: $sub/ not found)"; return; }
  local kept=0 del=0 name target
  echo "== $sub/ =="
  if [[ "$mode" == "dir" ]]; then
    for target in "$path"/*/; do
      [[ -d "$target" ]] || continue
      name="$(basename "$target")"
      if in_list "$name" "$@"; then kept=$((kept+1)); else
        del=$((del+1)); echo "  DEL  $sub/$name"
        [[ $APPLY -eq 1 ]] && rm -rf "$target"
      fi
    done
  else
    for target in "$path"/*.md; do
      [[ -f "$target" ]] || continue
      name="$(basename "$target" .md)"
      if in_list "$name" "$@"; then kept=$((kept+1)); else
        del=$((del+1)); echo "  DEL  $sub/$name.md"
        [[ $APPLY -eq 1 ]] && rm -f "$target"
      fi
    done
  fi
  echo "  -> keep $kept, $([[ $APPLY -eq 1 ]] && echo deleted || echo would-delete) $del"
}

echo "ECC trim @ $ROOT"
echo "Mode: $([[ $APPLY -eq 1 ]] && echo 'APPLY (deleting)' || echo 'DRY RUN (no changes) — pass --apply to delete')"
echo
trim_dir skills   dir "${KEEP_SKILLS[@]}"
trim_dir agents   md  "${KEEP_AGENTS[@]}"
trim_dir commands md  "${KEEP_COMMANDS[@]}"
trim_dir rules    dir "${KEEP_RULES[@]}"
echo
echo "Done. (scripts/ hooks/ contexts/ mcp-configs/ node_modules/ .claude-plugin/ left untouched)"
