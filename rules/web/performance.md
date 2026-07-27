---
globs: "admin/**/*.css,admin/**/*.scss,admin/**/*.sass,admin/**/*.less,admin/**/*.html,admin/**/*.tsx,admin/**/*.jsx,admin/**/*.vue,admin/**/*.svelte,store-app/**/*.css,store-app/**/*.scss,store-app/**/*.sass,store-app/**/*.less,store-app/**/*.html,store-app/**/*.tsx,store-app/**/*.jsx,store-app/**/*.vue,store-app/**/*.svelte,store-kiosk/**/*.css,store-kiosk/**/*.scss,store-kiosk/**/*.sass,store-kiosk/**/*.less,store-kiosk/**/*.html,store-kiosk/**/*.tsx,store-kiosk/**/*.jsx,store-kiosk/**/*.vue,store-kiosk/**/*.svelte,web-app/**/*.css,web-app/**/*.scss,web-app/**/*.sass,web-app/**/*.less,web-app/**/*.html,web-app/**/*.tsx,web-app/**/*.jsx,web-app/**/*.vue,web-app/**/*.svelte,health-dashboard/**/*.css,health-dashboard/**/*.scss,health-dashboard/**/*.sass,health-dashboard/**/*.less,health-dashboard/**/*.html,health-dashboard/**/*.tsx,health-dashboard/**/*.jsx,health-dashboard/**/*.vue,health-dashboard/**/*.svelte"
---
> This file extends [common/performance.md](../common/performance.md) with web-specific performance content.

# Web Performance Rules

## Core Web Vitals Targets

| Metric | Target |
|--------|--------|
| LCP | < 2.5s |
| INP | < 200ms |
| CLS | < 0.1 |
| FCP | < 1.5s |
| TBT | < 200ms |

## Bundle Budget

| Page Type | JS Budget (gzipped) | CSS Budget |
|-----------|---------------------|------------|
| Landing page | < 150kb | < 30kb |
| App page | < 300kb | < 50kb |
| Microsite | < 80kb | < 15kb |

## Loading Strategy

1. Inline critical above-the-fold CSS where justified
2. Preload the hero image and primary font only
3. Defer non-critical CSS or JS
4. Dynamically import heavy libraries

```js
const gsapModule = await import('gsap');
const { ScrollTrigger } = await import('gsap/ScrollTrigger');
```

## Image Optimization

- Explicit `width` and `height`
- `loading="eager"` plus `fetchpriority="high"` for hero media only
- `loading="lazy"` for below-the-fold assets
- Prefer AVIF or WebP with fallbacks
- Never ship source images far beyond rendered size

## Font Loading

- Max two font families unless there is a clear exception
- `font-display: swap`
- Subset where possible
- Preload only the truly critical weight/style

## Animation Performance

- Animate compositor-friendly properties only
- Use `will-change` narrowly and remove it when done
- Prefer CSS for simple transitions
- Use `requestAnimationFrame` or established animation libraries for JS motion
- Avoid scroll handler churn; use IntersectionObserver or well-behaved libraries

## Performance Checklist

- [ ] All images have explicit dimensions
- [ ] No accidental render-blocking resources
- [ ] No layout shifts from dynamic content
- [ ] Motion stays on compositor-friendly properties
- [ ] Third-party scripts load async/defer and only when needed
