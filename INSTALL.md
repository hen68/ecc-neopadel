# Installing curated ECC (`ecc-neopadel`)

This is a trimmed, curated fork of [`affaan-m/ecc`](https://github.com/affaan-m/ecc) — unused
languages/domains removed via `trim.sh`, so it's lighter than upstream.

Setup has **two independent pieces**:

- The **plugin** — agents, skills, commands, hooks — installed via Claude Code's plugin system.
- The **rules** — coding-style / testing / git-workflow standards — copied manually into
  `~/.claude/rules/`, because rules aren't carried by the plugin manifest.

Both are needed for the full setup; neither installs the other.

---

## 1. Clone the repo locally

```bash
git clone https://github.com/hen68/ecc-neopadel.git ~/dev/ecc-neopadel
cd ~/dev/ecc-neopadel
```

SSH alternative:

```bash
git clone git@github.com:hen68/ecc-neopadel.git ~/dev/ecc-neopadel
```

## 2. Install the plugin in Claude Code

The repo is a plugin marketplace (`.claude-plugin/marketplace.json`). Register it, then install the
`ecc` plugin. Run these **inside a Claude Code session**.

**Option A — from the local clone** (recommended; lets you update via `git pull`):

```
/plugin marketplace add ~/dev/ecc-neopadel
/plugin install ecc@ecc
```

**Option B — straight from GitHub** (no local clone needed for the plugin part):

```
/plugin marketplace add hen68/ecc-neopadel
/plugin install ecc@ecc
```

`ecc@ecc` = plugin `ecc` from marketplace `ecc`. Or just run `/plugin` for the interactive browser
and pick it from the list.

Restart Claude Code (or reload) if prompted. Verify:

```
/plugin              # ecc should show as installed
```

The agents (`ecc:code-reviewer`, `ecc:planner`, …), skills, and slash commands become available
immediately.

**Updating later:**

```bash
cd ~/dev/ecc-neopadel && git pull
```

then in Claude Code: `/plugin marketplace update ecc` (Option A) — or
`/plugin marketplace update hen68/ecc-neopadel` (Option B).

## 3. Hand over the rules (manual copy)

Rules are **not** part of the plugin — they live in `rules/` and load as global context from
`~/.claude/rules/`. Copy them in, nested under `ecc/` so they stay separate from your personal
rules:

```bash
mkdir -p ~/.claude/rules
cp -R ~/dev/ecc-neopadel/rules ~/.claude/rules/ecc
```

Result — `~/.claude/rules/ecc/` containing:

```
common/  kotlin/  python/  react/  react-native/  swift/  typescript/  web/  zh/
```

`common/` holds the language-agnostic standards (`coding-style.md`, `testing.md`,
`git-workflow.md`, `code-review.md`, `security.md`, …); the language folders extend them; `zh/` is
the Chinese translation of `common/`.

**Keep personal overrides separate.** Anything machine-specific goes in `~/.claude/rules/personal/`
(not under `ecc/`) so a future `cp -R` re-copy never clobbers it.

**Refreshing rules after a `git pull`:**

```bash
rm -rf ~/.claude/rules/ecc && cp -R ~/dev/ecc-neopadel/rules ~/.claude/rules/ecc
```

---

## Notes

- **Plugin vs. rules are decoupled** — Step 2 gives agents/skills/commands; Step 3 gives the
  standards.
- **`install.sh` exists but this guide skips it** — the repo ships a Node-based installer
  (`bash install.sh`) that would place things automatically. The manual route above is more
  transparent. Don't run both or they'll fight over the same paths.
- **Pulling upstream ECC updates** (maintainer only) — `git fetch upstream && git merge
  upstream/main`, then `bash trim.sh --apply` (idempotent, keep-list driven) to re-trim, then
  `git push`.
