---
description: Adversarial dual-review convergence loop — Codex and DeepSeek (via opencode) must both return NICE before code ships.
---

# Santa Loop

Two independent external reviewers — **Reviewer A: Codex**, **Reviewer B: DeepSeek via opencode** — different model families, no shared context, must both return NICE. Claude Opus is the fallback for a slot whose external reviewer is unavailable, blocked by the secret guard, or returns an unparsable verdict. It is never counted as "approval by silence".

Scope is the whole branch (committed + uncommitted), an outbound secret guard runs before anything leaves the machine, and an unparsable reviewer verdict fails closed. Neopadel-specific rubric rows only apply when the diff can exhibit them.

## Usage

```
/santa-loop [file-or-glob | description] [--no-deepseek] [--opus]
```

- `--no-deepseek` — keep DeepSeek out of the loop (Opus takes slot B). Use for anything you do not want a third party to see.
- `--opus` — add Claude Opus as a third reviewer on top of A and B.

## Step 1: Scope

```bash
BASE=$(git merge-base origin/main HEAD)
git diff --name-only "$BASE"     # committed + uncommitted
```

If `$ARGUMENTS` names a path or description, narrow to it. If the diff is empty, stop and say so — do not review nothing. Never include `.env*`, `*.pem`, `*.key` or `api/_local-*` files in the payload.

## Step 2: Rubric

Every criterion has an objective pass condition. Always include:

| Criterion | Pass condition |
|---|---|
| Correctness | Sound logic, edge cases handled |
| Security | No secrets, injection, XSS, authz holes |
| Error handling | Explicit, no silent swallowing |
| Completeness | All requirements addressed |
| Internal consistency | No contradictions between files |
| No regressions | Existing behaviour intact |

Add only the Neopadel criteria the diff can actually exhibit:

| Criterion | Pass condition |
|---|---|
| Money/state guard | Every status transition is guarded in the update filter, not by a prior read; no external call inside a transaction retry boundary (mongo-conventions) |
| Same value, one rule | No two call sites derive the same number/window/label under different rules (review-bug-shapes) |
| Club time | Time-of-day logic resolves in the club timezone, not server/laptop local (servers run UTC) |
| Hardware safety | No test/script path actuates MQTT gate/light/buzzer on real devices |

Reviewers use typed verdicts per criterion: `AGREE`, `DISAGREE_EVIDENCE` (fails AND states a concrete failure: input/state -> wrong output; the only blocking result), `DISAGREE_CONCERN` (no concrete failure; advisory). Required instruction in every reviewer prompt: *"Report DISAGREE_EVIDENCE only with a concrete failure sentence. No sentence, no block."*

Required JSON (no prose, no code fence):

```json
{"verdict":"NICE"|"NAUGHTY","checks":[{"criterion":"...","result":"AGREE"|"DISAGREE_EVIDENCE"|"DISAGREE_CONCERN","detail":"..."}],"critical_issues":["..."],"concerns":["..."],"suggestions":["..."]}
```

## Step 3: Build the payload and run the guard

```bash
PROMPT_FILE=$(mktemp /tmp/santa-payload-XXXXXX.txt)
# write: reviewer instructions + rubric + `git diff "$BASE"` + full text of each changed file
```

If the payload exceeds ~300k characters, send the diff only and tell the reviewers files were omitted.

**Outbound secret guard — mandatory before any external send** (global rule: never send a secret outward):

```bash
SECRET_RE='(sk_(live|test)_[A-Za-z0-9]{8,}|rk_(live|test)_[A-Za-z0-9]{8,}|whsec_[A-Za-z0-9]{8,}|-----BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|mongodb(\+srv)?://[^ /]+:[^ @]+@|xox[bp]-[A-Za-z0-9-]{10,}|gh[pous]_[A-Za-z0-9]{20,}|(API_KEY|SECRET|TOKEN|PASSWORD)[A-Z_]*[=:] *[^ ]{12,})'
if grep -E -q "$SECRET_RE" "$PROMPT_FILE"; then
  echo "secret-like string in payload: NOT sending to external reviewers" >&2   # -> Opus for both slots, tell the user which pattern class matched (never print the match)
fi
```

## Step 4: Dual independent review (run A and B in parallel, one Bash message each, timeout 600000)

Scratch dir for anything that has no sandbox: `SCRATCH=$(mktemp -d)`.

**Reviewer A — Codex** (flags verified; no `-m`: a ChatGPT-auth Codex rejects explicit models)

```bash
codex exec --sandbox read-only --ephemeral -C "$(pwd)" - < "$PROMPT_FILE" > "$SCRATCH/a.out" 2> "$SCRATCH/a.err"
```

**Reviewer B — DeepSeek via opencode** (verified live 2026-10-10)

```bash
opencode run "Do not use any tools. Everything needed is in the attached file. Reply with the JSON verdict only." \
  --pure --dir "$SCRATCH" -m deepseek/deepseek-v4-pro --format json -f "$PROMPT_FILE" > "$SCRATCH/b.jsonl" 2> "$SCRATCH/b.err"
jq -r 'select(.type=="text") | .part.text' "$SCRATCH/b.jsonl" > "$SCRATCH/b.out"
```

opencode gotchas (all confirmed live):

| Gotcha | Symptom | Fix |
|---|---|---|
| `-f` is an array option | A positional after `-f` is swallowed as a second file: `File not found: <your prompt>` | Put the message **first**, options after |
| `-f` resolves relative to `--dir` | `File not found: p.txt` when `--dir` is the scratch dir | Pass an **absolute** path to `-f` |
| No sandbox / read-only flag | A stray tool call could touch files | Empty `--dir "$SCRATCH"` + no-tools instruction; never pass `--auto` |
| Bad model / auth | exit 1, empty stdout | Treat empty `b.out` as failure (below) |
| JSON events | `step_start`, `text`, `step_finish` | Only `.type=="text"` carries the reply; trivial call costs ~30k input tokens (~$0.02) |

**Antigravity (`agy`) — optional fallback for either slot, before Opus** (only if installed and the slot's primary reviewer failed)

```bash
AGY_PROMPT="$(cat "$PROMPT_FILE")
Do not use any tools. Do not read, list, or search any files — everything you need is already in
this message. Reply with the JSON verdict only."
for attempt in 1 2 3; do
  RESULT=$(agy --print="$AGY_PROMPT" --output-format json --model gemini-3.1-pro-high --sandbox 2>&1)
  STATUS=$(printf '%s\n' "$RESULT" | tail -1 | jq -r '.status // empty' 2>/dev/null)
  RESPONSE=$(printf '%s\n' "$RESULT" | tail -1 | jq -r '.response // empty' 2>/dev/null)
  [ "$STATUS" = "SUCCESS" ] && [ -n "$RESPONSE" ] && { printf '%s\n' "$RESPONSE"; break; }
  sleep 5
done
```

`agy` gotchas (verified live 2026-09-13): the eligibility gate is flaky (~2/3 of identical calls fail, hence 3 attempts); headless mode silently denies tool use and returns `SUCCESS` with an **empty** `response` (always check `-n "$RESPONSE"`); a bare path is treated as prompt text, so pass content inline; use `printf '%s\n'`, never `echo`, before `jq` (zsh mangles the escapes); strip a leading/trailing json code fence.

**Validate each reviewer output (fail closed).** Strip one leading/trailing code fence if present, then require valid JSON with `checks[]`, every `result` in the three allowed values. Recompute the verdict yourself: **NAUGHTY iff any check is `DISAGREE_EVIDENCE`** — do not trust the reviewer's own `verdict` field. On empty/invalid output retry once; if it still fails, the slot falls back to `agy` (if installed), then to an Opus agent (`subagent_type: ecc:code-reviewer`, `model: opus`, same prompt) and the report says the slot was **not** external. If the fallback also fails, stop: **NAUGHTY (escalated)**, never NICE.

Clean up: `rm -rf "$SCRATCH" "$PROMPT_FILE"`.

With `--opus`, also launch the Opus agent as a third, independent reviewer; all three must be NICE.

## Step 5: Verdict gate

- All reviewers `NICE` -> **NICE**. Carry merged, deduplicated `concerns` into the report.
- Any `NAUGHTY` -> merge and deduplicate `critical_issues` (the `DISAGREE_EVIDENCE` items) and go to Step 6.

## Step 6: Fix cycle (NAUGHTY)

1. Show all critical issues; fix only what was flagged (no drive-by refactors). Fix concerns opportunistically if cheap — never re-loop for them alone.
2. Commit fixes in one commit: `fix: address santa-loop findings (round N)`. Commit with `-c commit.gpgsign=false` in secondary worktrees.
3. Re-run Step 4 with **fresh** reviewers (no memory of earlier rounds).
4. **Max 3 rounds.** Then stop and print the unresolved `DISAGREE_EVIDENCE` and open concerns for manual review. Do not push.

## Step 7: Confirm and push (NICE)

NICE clears the code to ship; it does **not** push. Present the verdict and ask for explicit confirmation before `git push -u origin HEAD`. A prior approval in the session does not carry forward. No answer = not pushed.

## Output

```
SANTA VERDICT: [NICE / NAUGHTY (escalated)]
Reviewer A (Codex):          [NICE/NAUGHTY]  [external | Opus fallback: reason]
Reviewer B (DeepSeek v4 pro): [NICE/NAUGHTY]  [external | Opus fallback: reason]
Blocking (DISAGREE_EVIDENCE): both / A only / B only
Concerns (advisory): ...
Iterations: N/3
Result: [NICE — AWAITING PUSH CONFIRMATION / ESCALATED TO USER]
```

## Notes

- Different training data is the point; the Opus fallback gives context isolation but not model diversity — the report must say when it was used.
- Codex gets repo read access inside its read-only sandbox; DeepSeek gets only the payload (no sandbox exists for opencode).
- The rubric is the most important input. Tighten it if reviewers rubber-stamp or flag style.
- Fixture smoke test 2026-10-10 (synthetic refund function, no repo code): both reviewers returned NAUGHTY on a read-then-write status guard with a concrete race sentence; DeepSeek returned NICE on the guarded version, Codex found a real lost-finalization edge case on it.
