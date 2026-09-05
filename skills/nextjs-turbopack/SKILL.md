---
name: nextjs-turbopack
description: Turbopack and Next.js bundling — incremental bundling, FS caching, dev speed, and when to use Turbopack vs webpack. Applies from Next.js 15.0 (Turbopack dev stable, opt-in via `--turbopack`); check the app's package.json first, since dev-default, FS caching, Bundle Analyzer and the `proxy.ts` middleware filename are 16+ only.
metadata:
  origin: ECC
---

# Next.js and Turbopack

## Check the Version First

Most of this skill applies from **Next.js 15.0**, where Turbopack dev went stable. Four things are **16+ only**. Before applying any of them — especially in review — read the app's `package.json`:

```bash
grep '"next":' package.json      # per-app, in a monorepo check every app
grep '"dev":' package.json       # is --turbopack already opted in?
```

| 16+ only | On 15.x instead |
|---|---|
| Turbopack is the **dev default** | Stable but **opt-in**: `next dev --turbopack` |
| Filesystem caching (default from 16.1) | Not in stable 15.x |
| Turbopack Bundle Analyzer (experimental, 16.1) | `@next/bundle-analyzer` (webpack), `ANALYZE=true next build` |
| `proxy.ts` middleware filename | `middleware.ts` is the only convention |

Everything else — Turbopack vs webpack tradeoffs, HMR and dev-speed guidance, debugging slow startup — **applies on 15.x too** once `--turbopack` is on. Do not dismiss the skill because the app is 15.x.

**Never flag the middleware filename without checking the version first:** `proxy.ts` on 16+ is correct and intentional; `middleware.ts` on 15.x is correct and `proxy.ts` does not exist there, so a rename silently disables middleware.

In a monorepo, versions differ per app — verify the specific app you are touching.

Next.js 16+ uses Turbopack by default for local development: an incremental bundler written in Rust that significantly speeds up dev startup and hot updates.

## When to Use

- **Turbopack** (default dev on 16+, `--turbopack` on 15.x): Use for day-to-day development. Faster cold start and HMR, especially in large apps.
- **Webpack**: Use only if you hit a Turbopack bug or rely on a webpack-only plugin in dev. On 16+ opt out with `--webpack`; on 15.x you opt *out* by simply omitting `--turbopack`, since webpack is still the default there.
- **Production**: On 16+ `next build` also uses Turbopack by default (opt out with `--webpack`; a build that finds a custom `webpack` config **fails** rather than silently ignoring it). On 15.x `next build` is webpack unless you pass `--turbopack`.

Use when: developing or debugging Next.js 15.0+ apps, diagnosing slow dev startup or HMR, or optimizing production bundles.

## How It Works

- **Turbopack**: Incremental bundler for Next.js dev. With filesystem caching (16.1+) restarts reuse prior work and are much faster (e.g. 5–14x on large projects); on 15.x there is no disk cache, so the win is cold start and HMR only.
- **Default in dev**: From Next.js 16, `next dev` runs with Turbopack unless disabled.
- **File-system caching**: Restarts reuse previous work; cache is typically under `.next`. Not in stable 15.x (experimental on 15.5 canaries only); beta and flag-gated on 16.0 via two separate flags, `experimental.turbopackFileSystemCacheForDev` and `…ForBuild`; on by default from 16.1.
- **Bundle Analyzer (Next.js 16.1+)**: Experimental Turbopack analyzer to inspect output and find heavy dependencies — run it as a CLI command, `next experimental-analyze`. On 15.x use `@next/bundle-analyzer` instead.

## Examples

### Commands

```bash
next dev              # 16+: Turbopack by default
next dev --turbopack  # 15.x: Turbopack is stable but opt-in
next build
next start
```

### Usage

Run `next dev` for local development — on 16+ that is Turbopack; on 15.x add `--turbopack` or you get webpack. To trim large dependencies, use `next experimental-analyze` (Turbopack, 16.1+) or `@next/bundle-analyzer` with `ANALYZE=true next build` on 15.x. Prefer App Router and server components where possible.

## Middleware File Naming

Next.js 16 introduced `proxy.ts` as the middleware filename, replacing the older `middleware.ts` convention:

- **Next.js 16+**: use `proxy.ts` at the project root
- **Pre-Next.js 16**: use `middleware.ts` at the project root

The filename change is tied to the **Next.js version**, not to which bundler (Turbopack or webpack) is in use. Always check the official docs for the version you are reviewing.

The rule cuts **both** ways — check the version before flagging either filename:

- **Do not flag `proxy.ts`** in Next.js 16+ projects. It is correct and intentional.
- **Do not flag `middleware.ts`** in Next.js 15.x or earlier. It is correct there, and `proxy.ts` is not a recognized file convention before v16.0.0, so renaming forward **does** break middleware.
- On 16+, `middleware.ts` is **deprecated but still runs** (Edge-runtime use cases), slated for removal in a future major. So flag it as deprecated if you like; do not claim it is broken.

**The rename is not just the filename.** `proxy.ts` must export a function named `proxy` (or a default export); `middleware.ts` must export `middleware`. Renaming only the file leaves a dead handler either way. The codemod does both:

```bash
npx @next/codemod@canary middleware-to-proxy .
```

**Do not run it on an edge-runtime handler.** Per the v16 upgrade guide: *"The `edge` runtime is **NOT** supported in `proxy`. The `proxy` runtime is `nodejs`, and it cannot be configured. If you want to continue using the `edge` runtime, keep using `middleware`."* So `runtime: 'edge'` is the one case where staying on the deprecated `middleware.ts` is correct on 16+.

Reference: [Proxy docs](https://nextjs.org/docs/app/getting-started/proxy), [Renaming Middleware to Proxy](https://nextjs.org/docs/messages/middleware-to-proxy)

## Best Practices

- Turbopack dev is stable from 15.0; filesystem caching needs 16.1+. Do not recommend a major upgrade solely for Turbopack.
- If dev is slow, ensure you're actually on Turbopack (default on 16+, `--turbopack` on 15.x) and that the cache isn't being cleared unnecessarily.
- For production bundle size issues, use the official Next.js bundle analysis tooling for your version.
