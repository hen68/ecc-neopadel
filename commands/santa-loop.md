---
description: Adversarial dual-review convergence loop — two independent model reviewers must both approve before code ships.
---

# Santa Loop

Adversarial dual-review convergence loop using the santa-method skill. Two independent reviewers — different models, no shared context — must both return NICE before code ships.

## Purpose

Run two independent reviewers (Claude Opus + an external model) against the current task output. Both must return NICE before the code is pushed. If either returns NAUGHTY, fix all flagged issues, commit, and re-run fresh reviewers — up to 3 rounds.

## Usage

```
/santa-loop [file-or-glob | description]
```

## Workflow

### Step 1: Identify What to Review

Determine the scope from `$ARGUMENTS` or fall back to uncommitted changes:

```bash
git diff --name-only HEAD
```

Read all changed files to build the full review context. If `$ARGUMENTS` specifies a path, file, or description, use that as the scope instead.

### Step 2: Build the Rubric

Construct a rubric appropriate to the file types under review. Every criterion must have an objective PASS/FAIL condition. Include at minimum:

| Criterion | Pass Condition |
|-----------|---------------|
| Correctness | Logic is sound, no bugs, handles edge cases |
| Security | No secrets, injection, XSS, or OWASP Top 10 issues |
| Error handling | Errors handled explicitly, no silent swallowing |
| Completeness | All requirements addressed, no missing cases |
| Internal consistency | No contradictions between files or sections |
| No regressions | Changes don't break existing behavior |

Add domain-specific criteria based on file types (e.g., type safety for TS, memory safety for Rust, migration safety for SQL).

### Step 3: Dual Independent Review

Launch two reviewers **in parallel** using the Agent tool (both in a single message for concurrent execution). Both must complete before proceeding to the verdict gate.

Each reviewer evaluates every rubric criterion with a **typed verdict**, not a plain PASS/FAIL —
per the 2026-09-12 tooling research (`docs/ai-agent-verification-tooling-research-2026-09-12.md` in
the neopadel repo, recommendation #3; independently reinforced by three unrelated projects'
convergence on typed verdicts, cited there): collapsing "this fails, and here's the concrete broken
behavior" and "this fails, but it's a subjective/stylistic worry with no concrete evidence" into the
same FAIL loses exactly the distinction that determines whether the loop should actually block. Each
criterion gets one of:

- **`AGREE`** — meets the pass condition, nothing to report.
- **`DISAGREE_EVIDENCE`** — fails, and the reviewer can point to a concrete failure: specific
  input/state → wrong output, crash, security hole, or a requirement the diff doesn't meet. This is
  the only result that blocks.
- **`DISAGREE_CONCERN`** — the reviewer is uneasy but cannot state a concrete failure (a style
  preference, a "this feels risky" hunch, a suggestion). Reported, never blocking.

Return structured JSON:

```json
{
  "verdict": "NICE" | "NAUGHTY",
  "checks": [
    {"criterion": "...", "result": "AGREE" | "DISAGREE_EVIDENCE" | "DISAGREE_CONCERN", "detail": "..."}
  ],
  "critical_issues": ["... one per DISAGREE_EVIDENCE check, each stating the concrete failure ..."],
  "concerns": ["... one per DISAGREE_CONCERN check — advisory, never blocking ..."],
  "suggestions": ["..."]
}
```

A reviewer's own `verdict` is `NAUGHTY` iff at least one criterion is `DISAGREE_EVIDENCE` —
`DISAGREE_CONCERN`-only results still verdict `NICE`, with the concerns carried through to the final
report instead of silently dropped. The verdict gate (Step 4) maps these to the loop's own NICE/NAUGHTY:
both `NICE` → NICE, either `NAUGHTY` → NAUGHTY.

#### Reviewer A: Claude Agent (always runs)

Launch an Agent (subagent_type: `code-reviewer`, model: `opus`) with the full rubric + all files under review. The prompt must include:
- The complete rubric
- All file contents under review
- "You are an independent quality reviewer. You have NOT seen any other review. Your job is to find problems, not to approve."
- Return the structured JSON verdict above

#### Reviewer B: External Model (Claude fallback only if no external CLI installed)

First, detect which CLIs are available:
```bash
command -v codex >/dev/null 2>&1 && echo "codex" || true
command -v gemini >/dev/null 2>&1 && echo "gemini" || true
```

Build the reviewer prompt (identical rubric + instructions as Reviewer A) and write it to a unique temp file:
```bash
PROMPT_FILE=$(mktemp /tmp/santa-reviewer-b-XXXXXX.txt)
cat > "$PROMPT_FILE" << 'EOF'
... full rubric + file contents + reviewer instructions ...
EOF
```

Use the first available CLI:

**Codex CLI** (if installed)
```bash
codex exec --sandbox read-only -C "$(pwd)" - < "$PROMPT_FILE"
rm -f "$PROMPT_FILE"
```
Omit `-m`/model selection: confirmed live 2026-09-12 that a ChatGPT-account-authenticated Codex CLI
(`stored auth mode: chatgpt` in `codex doctor`) hard-rejects `-m gpt-5.4` with `the 'gpt-5.4' model is
not supported when using Codex with a ChatGPT account` (HTTP 400) — this is an auth-mode restriction,
not a typo or a stale model name. Codex's own default model works and returns a valid structured
verdict. If you're on API-key auth instead of a ChatGPT account, `-m gpt-5.4` (or another explicit
model) may work for you — check `codex doctor`'s `auth mode` line before adding it back.

**Gemini CLI** (if installed and codex is not)
```bash
gemini -p "$(cat "$PROMPT_FILE")" -m gemini-2.5-pro
rm -f "$PROMPT_FILE"
```

**Claude Agent fallback** (only if neither `codex` nor `gemini` is installed)
Launch a second Claude Agent (subagent_type: `code-reviewer`, model: `opus`). Log a warning that both reviewers share the same model family — true model diversity was not achieved but context isolation is still enforced.

In all cases, the reviewer must return the same structured JSON verdict as Reviewer A.

### Step 4: Verdict Gate

- **Both `NICE`** → **NICE** — proceed to Step 6 (confirm & push). Merge and deduplicate any
  `concerns` from both reviewers and carry them into the final report as advisory notes — they do
  not block, but a real NICE-with-concerns ship should not silently drop them.
- **Either `NAUGHTY`** → **NAUGHTY** — merge all `critical_issues` (the `DISAGREE_EVIDENCE` items)
  from both reviewers, deduplicate, proceed to Step 5. `concerns` from a `NAUGHTY` round are still
  worth fixing opportunistically in the same pass but never gate the loop by themselves.

### Step 5: Fix Cycle (NAUGHTY path)

1. Display all critical issues (`DISAGREE_EVIDENCE`) from both reviewers — fix these; they gate the
   loop. Display any `concerns` (`DISAGREE_CONCERN`) too, and fix them opportunistically in the same
   pass if cheap, but do not treat leaving one unaddressed as a reason to re-loop.
2. Fix every flagged critical issue — change only what was flagged, no drive-by refactors
3. Commit all fixes in a single commit:
   ```
   fix: address santa-loop review findings (round N)
   ```
4. Re-run Step 3 with **fresh reviewers** (no memory of previous rounds)
5. Repeat until both return `NICE`

**Maximum 3 iterations.** If still NAUGHTY after 3 rounds, stop and present remaining issues:

```
SANTA LOOP ESCALATION (exceeded 3 iterations)

Remaining critical issues after 3 rounds (DISAGREE_EVIDENCE):
- [list all unresolved critical issues from both reviewers]

Remaining concerns (DISAGREE_CONCERN, non-blocking):
- [list any concerns still open]

Manual review required before proceeding.
```

Do NOT push.

### Step 6: Confirm & Push (NICE path)

Both reviewers passing clears the code to ship — it does NOT push it automatically. Present the verdict (both NICE, any concerns found by each, iteration count) and explicitly ask the user for confirmation before running:

```bash
git push -u origin HEAD
```

Never push without that confirmation, even after a clean NICE verdict, and even if an earlier turn in this same session already confirmed a push once — a prior approval does not carry forward to a new push. If the user declines or doesn't respond, stop here and report NICE-but-not-pushed; do not treat silence as approval.

### Step 7: Final Report

Print the output report (see Output section below).

## Output

```
SANTA VERDICT: [NICE / NAUGHTY (escalated)]

Reviewer A (Claude Opus):   [NICE/NAUGHTY]
Reviewer B ([model used]):  [NICE/NAUGHTY]

Agreement (DISAGREE_EVIDENCE — blocking):
  Both flagged:      [issues caught by both]
  Reviewer A only:   [issues only A caught]
  Reviewer B only:   [issues only B caught]

Concerns (DISAGREE_CONCERN — advisory, non-blocking):
  [merged, deduplicated concerns from both reviewers, or "None"]

Iterations: [N]/3
Result:     [PUSHED / NICE — AWAITING PUSH CONFIRMATION / ESCALATED TO USER]
```

## Notes

- Reviewer A (Claude Opus) always runs — guarantees at least one strong reviewer regardless of tooling.
- Model diversity is the goal for Reviewer B. GPT-5.4 or Gemini 2.5 Pro gives true independence — different training data, different biases, different blind spots. The Claude-only fallback still provides value via context isolation but loses model diversity.
- Strongest available model is used for Reviewer A (Opus). Reviewer B uses Codex/Gemini's own default
  model rather than a hardcoded one — an explicit `-m` can reject outright depending on the CLI's auth
  mode (see the Codex CLI note above), so this intentionally defers to whatever each CLI considers its
  best default.
- External reviewers run with `--sandbox read-only` (Codex) to prevent repo mutation during review.
- Fresh reviewers each round prevents anchoring bias from prior findings.
- The rubric is the most important input. Tighten it if reviewers rubber-stamp or flag subjective style issues.
- Commits happen on NAUGHTY rounds so fixes are preserved even if the loop is interrupted.
- Push only happens after NICE, and only after the user explicitly confirms it — never mid-loop, and never automatic even on a clean NICE.
