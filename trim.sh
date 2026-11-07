#!/usr/bin/env bash
#
# trim.sh — curate a LOCAL, OWNED ECC plugin clone down to a keep-list.
#
# Trims skills/, agents/, commands/, rules/ (Claude Code surface) AND the
# opencode surface (.opencode/commands/, .opencode/prompts/agents/) — deletes
# everything not listed in the matching keep-list below.
# Never touches scripts/, hooks/, contexts/, .claude-plugin/, node_modules/,
# package.json, mcp-configs/, .mcp.json, .opencode/plugins/, .opencode/tools/,
# .opencode/instructions/, .opencode/opencode.json, etc. — the instinct loop and
# opencode plugin runtime depend on those.
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
  # v2.2.10 prune (Neopadel /context audit): only what the monorepo uses; do not re-add without a reason
  blueprint continuous-learning-v2 deployment-patterns eval-harness motion-foundations react-performance santa-method verification-loop
)

# --- AGENTS (*.md under agents/) ----------------------------------------------
KEEP_AGENTS=(
  # v2.2.10 prune (Neopadel /context audit): only what the monorepo uses; do not re-add without a reason
  # v2.2.14: restored planner architect build-error-resolver refactor-cleaner (own, versioned copies instead of relying on native behaviour)
  architect build-error-resolver code-explorer code-reviewer code-simplifier database-reviewer e2e-runner harness-optimizer performance-optimizer planner pr-test-analyzer refactor-cleaner react-reviewer security-reviewer seo-specialist silent-failure-hunter tdd-guide typescript-reviewer
)

# --- COMMANDS (*.md under commands/) ------------------------------------------
KEEP_COMMANDS=(
  # v2.2.10 prune (Neopadel /context audit): only what the monorepo uses; do not re-add without a reason
  evolve resume-session save-session
)

# --- RULES (directories under rules/) -----------------------------------------
# Stack the team actually touches + your local zh addition. README.md left in place.
# No Python anywhere in the monorepo (Babel/JS backend, Mongoose not Postgres/Prisma) — dropped.
KEEP_RULES=(
  common typescript react web react-native swift kotlin
)

# --- OPENCODE COMMANDS (*.md under .opencode/commands/) ------------------------
# Same Neopadel stack audit: no Go/Rust/C++/Java/Kotlin/PHP/Python in the monorepo.
# opencode's slash commands are its primary agent-invocation surface, so we keep
# the whole JS/TS/React/RN/Next.js + harness/orchestration set and only drop the
# six language-specific commands.
KEEP_OPENCODE_COMMANDS=(
  build-fix checkpoint code-review e2e eval evolve harness-audit instinct-export
  instinct-import instinct-status learn loop-start loop-status model-route
  orchestrate plan projects promote quality-gate refactor-clean security-scan
  security setup-pm skill-create tdd test-coverage update-codemaps update-docs verify
)

# --- OPENCODE AGENTS (*.txt under .opencode/prompts/agents/) -------------------
# Drop the language-specific reviewers/build-resolvers the monorepo can never use
# (Go/Rust/C++/Java/Kotlin/PHP/Python). Keep the shared + JS/TS/React/RN set plus
# doc-updater/docs-lookup (docs discipline) and loop-operator (orchestration).
KEEP_OPENCODE_AGENTS=(
  architect build-error-resolver code-reviewer database-reviewer doc-updater
  docs-lookup e2e-runner harness-optimizer loop-operator planner refactor-cleaner
  security-reviewer tdd-guide
)

# ==============================================================================
# engine — do not edit below
# ==============================================================================
in_list() { local x="$1"; shift; local e; for e in "$@"; do [[ "$e" == "$x" ]] && return 0; done; return 1; }

trim_dir() { # $1=subdir  $2=mode(dir|md|txt)  rest=keep-list
  local sub="$1" mode="$2"; shift 2
  local path="$ROOT/$sub"
  [[ -d "$path" ]] || { echo "  (skip: $sub/ not found)"; return; }
  local kept=0 del=0 name target ext
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
    ext="$mode"
    for target in "$path"/*."$ext"; do
      [[ -f "$target" ]] || continue
      name="$(basename "$target" ".$ext")"
      if in_list "$name" "$@"; then kept=$((kept+1)); else
        del=$((del+1)); echo "  DEL  $sub/$name.$ext"
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
trim_dir .opencode/commands        md  "${KEEP_OPENCODE_COMMANDS[@]}"
trim_dir .opencode/prompts/agents  txt "${KEEP_OPENCODE_AGENTS[@]}"
echo
echo "Done. (scripts/ hooks/ contexts/ mcp-configs/ node_modules/ .claude-plugin/ and .opencode/{plugins,tools,instructions,opencode.json} left untouched)"
