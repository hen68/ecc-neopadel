# Commands Quick Reference

> 42 slash commands installed globally. Type `/` in any Claude Code session to invoke.

---

## Core Workflow

| Command | What it does |
|---------|-------------|
| `/plan` | Restate requirements, assess risks, write step-by-step implementation plan — **waits for your confirm before touching code** |
| `/plan-canvas` | Open a plan or HTML artifact in the browser Plan Canvas for annotate-and-approve review |
| `/plan-prd` | Generate a lean, problem-first PRD and hand off to `/plan` for implementation planning |
| `/code-review` | Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode) |
| `/review-pr` | Comprehensive PR review using specialized agents |
| `/build-fix` | Detect and fix build errors — delegates to the right build-resolver agent automatically |
| `/quality-gate` | Quality gate check against project standards |
| `/santa-loop` | Adversarial dual-review convergence loop — two independent model reviewers must both approve before code ships |

---

## Testing

| Command | What it does |
|---------|-------------|
| `/test-coverage` | Analyze coverage, identify gaps, and generate missing tests toward the target threshold |
| `/react-test` | TDD for React (React Testing Library, Vitest or Jest, coverage targets) |

---

## Code Review

| Command | What it does |
|---------|-------------|
| `/code-review` | Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode) |
| `/react-review` | React/JSX — hook correctness, render performance, server/client boundaries, accessibility |

---

## Build Fixers

| Command | What it does |
|---------|-------------|
| `/build-fix` | Detect and fix build errors — delegates to the right build-resolver agent automatically |
| `/react-build` | Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) |

---

## Orchestrated Feature Workflows

| Command | What it does |
|---------|-------------|
| `/orch-add-feature` | Build a brand-new feature end to end — research, plan, TDD, review, gated commit |
| `/orch-build-mvp` | Bootstrap a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit |
| `/orch-change-feature` | Alter an existing feature to new desired behavior — update tests to the new spec, change impl, review, gated commit |
| `/orch-fix-defect` | Fix a bug — reproduce it as a failing regression test, fix to green, review, gated commit |
| `/orch-refine-code` | Behavior-preserving refactor — confirm tests green, restructure, keep green, review, gated commit |
| `/orch-review` | Run the orch-review native Workflow over a diff (local changes or a GitHub PR) and report blocking vs advisory findings |

---

## PRP Workflow

| Command | What it does |
|---------|-------------|
| `/prp-plan` | Create a comprehensive feature implementation plan with codebase analysis and pattern extraction |
| `/prp-pr` | Create a GitHub PR from the current branch with unpushed commits |

---

## Planning & Architecture

| Command | What it does |
|---------|-------------|
| `/plan` | Restate requirements, assess risks, write step-by-step implementation plan — **waits for your confirm before touching code** |

---

## Session Management

| Command | What it does |
|---------|-------------|
| `/save-session` | Save current session state to `~/.claude/session-data/` |
| `/resume-session` | Load the most recent saved session from the canonical session store and resume from where you left off |
| `/sessions` | Browse, search, and manage session history with aliases from `~/.claude/session-data/` (with legacy reads from `~/.claude/sessions/`) |
| `/checkpoint` | Create, verify, or list workflow checkpoints after running verification checks |

---

## Cross-Harness Memory CLI

These are `ecc` CLI commands, not slash commands. They use one inspectable
Markdown vault across Claude, Codex, Hermes, OpenClaw, Kimi, and other
harnesses.

| Command | What it does |
|---------|-------------|
| `ecc memory init` | Create project, team, or user vault directories |
| `ecc memory save` | Create an unreviewed context, decision, fact, lesson, note, preference, or runbook |
| `ecc memory handoff` | Transfer bounded work state from one harness to another |
| `ecc memory search` | Search memories by text, scope, kind, or target harness |
| `ecc memory read` | Read a memory and its backlinks by stable ID |
| `ecc memory doctor` | Report malformed files, duplicate IDs, broken links, and skipped symlinks |
| `ecc-memory-mcp` | Start the optional local stdio MCP server |

Pass memory bodies with `--stdin` or `--body-file`; they are intentionally not
accepted as command-line values. Recalled memories are untrusted context, not
executable instructions or policy.

---

## Install Health & Feedback CLI

These lifecycle commands are also available through the `ecc` CLI.

| Command | What it does |
|---------|-------------|
| `ecc list-installed` | Show installs recorded in ECC's managed state |
| `ecc doctor` | Diagnose missing or drifted managed files and point failures to the short problem form |
| `ecc repair` | Restore missing or drifted managed files |
| `ecc uninstall` | Remove only install-state-managed files and optionally show the 20-second exit-feedback route |
| `ecc feedback` | Show the public problem, quick-feedback, and feature routes without reading files or uploading diagnostics |

---

## Learning & Improvement

| Command | What it does |
|---------|-------------|
| `/evolve` | Analyse learned instincts, suggest evolved skill structures |
| `/skill-create` | Analyse local git history → generate a reusable skill |
| `/skill-health` | Skill portfolio health dashboard with analytics |

---

## Refactoring & Cleanup

| Command | What it does |
|---------|-------------|
| `/refactor-clean` | Remove dead code, consolidate duplicates, clean up structure |

---

## Docs & Research

| Command | What it does |
|---------|-------------|
| `/ecc-guide` | Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface |
| `/update-docs` | Sync documentation from source-of-truth files such as scripts, schemas, routes, and exports |
| `/update-codemaps` | Regenerate codemaps for the codebase |

---

## Loops & Automation

| Command | What it does |
|---------|-------------|
| `/gan-build` | Generator/evaluator build loop for implementation tasks, bounded iterations and scoring |
| `/gan-design` | Generator/evaluator design loop for frontend or visual work, bounded iterations and scoring |

---

## Project & Infrastructure

| Command | What it does |
|---------|-------------|
| `/projects` | List known projects and their instinct statistics |
| `/project-init` | Detect a project's stack and produce a dry-run ECC onboarding plan |
| `/harness-audit` | Audit the agent harness configuration for reliability and cost |
| `/model-route` | Route a task to the right model (Haiku / Sonnet / Opus) |
| `/setup-pm` | Configure package manager (npm / pnpm / yarn / bun) |
| `/auto-update` | Pull the latest ECC repo changes and reinstall the current managed targets |
| `/cost-report` | Generate a local Claude Code cost report from a cost-tracker SQLite database |
| `/pr` | Create a GitHub PR from current branch with unpushed commits |

---

## Retired Commands

These slash commands were retired in favor of skills. The command files still exist under `legacy-command-shims/commands/` for backward compatibility (not part of the default installed surface), but the maintained workflow now lives in the listed skill — invoke the skill directly instead:

| Retired command | Use this skill instead |
|---|---|
| `/tdd` | `tdd-workflow` |
| `/eval` | `eval-harness` |
| `/verify` | `verification-loop` |
| `/e2e` | `e2e-testing` |
| `/docs` | `documentation-lookup` |
| `/claw` | `nanoclaw-repl` |
| `/context-budget` | `context-budget` |
| `/devfleet` | `claude-devfleet` |
| `/orchestrate` | `dmux-workflows` and `autonomous-agent-harness` |
| `/prompt-optimize` | `prompt-optimizer` |
| `/rules-distill` | `rules-distill` |
| `/agent-sort` | `agent-sort` |

---

## Quick Decision Guide

```
Starting a new feature?         → /plan first, then TDD via the tdd-workflow skill
Code just written?              → /code-review
Build broken?                   → /build-fix
Need live docs?                 → the documentation-lookup skill
Session about to end?           → /save-session or /learn-eval
Resuming next day?              → /resume-session
Context getting heavy?          → the context-budget skill
Want to extract what you learned? → /learn-eval then /evolve
Running repeated tasks?         → /loop-start
```
