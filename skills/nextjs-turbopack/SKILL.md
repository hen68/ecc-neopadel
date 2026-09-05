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
| Filesystem caching | Not available |
| Bundle Analyzer (16.1) | Not available |
| `proxy.ts` middleware filename | `middleware.ts` is the only convention |

Everything else — Turbopack vs webpack tradeoffs, HMR and dev-speed guidance, debugging slow startup — **applies on 15.x too** once `--turbopack` is on. Do not dismiss the skill because the app is 15.x.

**Never flag the middleware filename without checking the version first:** `proxy.ts` on 16+ is correct and intentional; `middleware.ts` on 15.x is correct and `proxy.ts` does not exist there, so a rename silently disables middleware.

In a monorepo, versions differ per app — verify the specific app you are touching.

Next.js 16+ uses Turbopack by default for local development: an incremental bundler written in Rust that significantly speeds up dev startup and hot updates.

## When to Use

- **Turbopack (default dev)**: Use for day-to-day development. Faster cold start and HMR, especially in large apps.
- **Webpack (legacy dev)**: Use only if you hit a Turbopack bug or rely on a webpack-only plugin in dev. Disable with `--webpack` (or `--no-turbopack` depending on your Next.js version; check the docs for your release).
- **Production**: Production build behavior (`next build`) may use Turbopack or webpack depending on Next.js version; check the official Next.js docs for your version.

Use when: developing or debugging Next.js 15.0+ apps, diagnosing slow dev startup or HMR, or optimizing production bundles.

## How It Works

- **Turbopack**: Incremental bundler for Next.js dev. Uses file-system caching so restarts are much faster (e.g. 5–14x on large projects).
- **Default in dev**: From Next.js 16, `next dev` runs with Turbopack unless disabled.
- **File-system caching**: Restarts reuse previous work; cache is typically under `.next`; no extra config needed for basic use.
- **Bundle Analyzer (Next.js 16.1+)**: Experimental Bundle Analyzer to inspect output and find heavy dependencies; enable via config or experimental flag (see Next.js docs for your version).

## Examples

### Commands

```bash
next dev
next build
next start
```

### Usage

Run `next dev` for local development with Turbopack. Use the Bundle Analyzer (see Next.js docs) to optimize code-splitting and trim large dependencies. Prefer App Router and server components where possible.

## Middleware File Naming

Next.js 16 introduced `proxy.ts` as the middleware filename, replacing the older `middleware.ts` convention:

- **Next.js 16+**: use `proxy.ts` at the project root
- **Pre-Next.js 16**: use `middleware.ts` at the project root

The filename change is tied to the **Next.js version**, not to which bundler (Turbopack or webpack) is in use. Always check the official docs for the version you are reviewing.

The rule cuts **both** ways — check the version before flagging either filename:

- **Do not flag `proxy.ts`** as a misnamed or missing middleware file in Next.js 16+ projects. The file is correct and intentional; suggesting a rename to `middleware.ts` will break middleware execution.
- **Do not flag `middleware.ts`** in Next.js 15.x or earlier projects. It is correct there, `proxy.ts` is not available, and renaming it will break middleware execution.

Reference: [Next.js proxy docs](https://nextjs.org/docs/app/getting-started/proxy)

## Best Practices

- Stay on a recent Next.js 16.x for stable Turbopack and caching behavior.
- If dev is slow, ensure you're on Turbopack (default) and that the cache isn't being cleared unnecessarily.
- For production bundle size issues, use the official Next.js bundle analysis tooling for your version.
