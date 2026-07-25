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
  # -- base (v1 keep-list) --
  agent-introspection-debugging agent-sort agentic-engineering ai-regression-testing
  api-design automation-audit-ops backend-patterns benchmark benchmark-optimization-loop
  blueprint ck codebase-onboarding coding-standards context-budget
  continuous-learning-v2 cost-tracking council
  deep-research deployment-patterns dmux-workflows docker-patterns documentation-lookup e2e-testing
  error-handling eval-harness exa-search frontend-patterns
  gan-style-harness gateguard git-workflow github-ops hookify-rules
  make-interfaces-feel-better mcp-server-patterns nextjs-turbopack
  parallel-execution-optimizer plan-orchestrate production-audit
  project-flow-ops prompt-optimizer react-patterns react-performance react-testing
  redis-patterns regex-vs-llm-structured-text repo-scan research-ops rules-distill santa-method
  search-first security-review security-scan skill-comply skill-scout skill-stocktake
  strategic-compact tdd-workflow terminal-ops verification-loop
  # -- v2 adopted: agent-harness & eval --
  agent-eval agent-self-evaluation agent-architecture-audit agent-harness-construction
  autonomous-loops continuous-agent-loop dynamic-workflow-mode intent-driven-development
  recursive-decision-ledger
  # -- v2 adopted: ECC self-mgmt & orchestration --
  configure-ecc config-gc ecc-recipes ecc-tools-cost-audit architecture-decision-records code-tour
  orch-add-feature orch-build-mvp orch-change-feature orch-fix-defect orch-pipeline orch-refine-code
  # -- v2 adopted: frontend/design & a11y --
  design-system accessibility frontend-a11y frontend-design-direction plan-canvas
  motion-foundations motion-patterns motion-ui
  # -- v2 adopted: JS backend & DB --
  database-migrations vue-patterns react-native-patterns
  # -- v2 adopted: QA / security / research / ops (post-review, note.txt) --
  browser-qa canary-watch codehealth-mcp iterative-retrieval knowledge-ops
  security-bounty-hunter seo workspace-surface-audit
)

# --- AGENTS (*.md under agents/) ----------------------------------------------
KEEP_AGENTS=(
  # -- base (v1) --
  architect build-error-resolver code-architect code-explorer code-reviewer code-simplifier comment-analyzer conversation-analyzer
  database-reviewer doc-updater docs-lookup e2e-runner gan-evaluator gan-generator gan-planner harness-optimizer
  loop-operator performance-optimizer planner pr-test-analyzer react-build-resolver react-reviewer refactor-cleaner
  security-reviewer seo-specialist silent-failure-hunter tdd-guide type-design-analyzer typescript-reviewer
  # -- v2 adopted: agent-harness & eval --
  agent-evaluator spec-miner
)

# --- COMMANDS (*.md under commands/) ------------------------------------------
KEEP_COMMANDS=(
  # -- base (v1) --
  build-fix checkpoint code-review cost-report ecc-guide evolve gan-build
  gan-design hookify hookify-configure hookify-help hookify-list instinct-export instinct-import
  instinct-status learn learn-eval model-route
  plan plan-prd pr project-init projects
  promote prp-commit prp-implement prp-plan prp-pr prp-prd prune
  react-build react-review react-test resume-session review-pr santa-loop
  save-session sessions setup-pm skill-create skill-health test-coverage
  update-docs
  # -- v2 adopted: ECC self-mgmt & orchestration --
  harness-audit auto-update update-codemaps refactor-clean quality-gate
  orch-add-feature orch-build-mvp orch-change-feature orch-fix-defect orch-refine-code orch-review
  # -- v2 adopted: frontend/design --
  plan-canvas
)

# --- RULES (directories under rules/) -----------------------------------------
# Stack the team actually touches + your local zh addition. README.md left in place.
# No Python anywhere in the monorepo (Babel/JS backend, Mongoose not Postgres/Prisma) — dropped.
KEEP_RULES=(
  common typescript react web react-native swift kotlin zh
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
