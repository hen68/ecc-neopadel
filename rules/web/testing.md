---
globs: "admin/**/*.css,admin/**/*.scss,admin/**/*.sass,admin/**/*.less,admin/**/*.html,admin/**/*.tsx,admin/**/*.jsx,admin/**/*.vue,admin/**/*.svelte,store-app/**/*.css,store-app/**/*.scss,store-app/**/*.sass,store-app/**/*.less,store-app/**/*.html,store-app/**/*.tsx,store-app/**/*.jsx,store-app/**/*.vue,store-app/**/*.svelte,store-kiosk/**/*.css,store-kiosk/**/*.scss,store-kiosk/**/*.sass,store-kiosk/**/*.less,store-kiosk/**/*.html,store-kiosk/**/*.tsx,store-kiosk/**/*.jsx,store-kiosk/**/*.vue,store-kiosk/**/*.svelte,web-app/**/*.css,web-app/**/*.scss,web-app/**/*.sass,web-app/**/*.less,web-app/**/*.html,web-app/**/*.tsx,web-app/**/*.jsx,web-app/**/*.vue,web-app/**/*.svelte,health-dashboard/**/*.css,health-dashboard/**/*.scss,health-dashboard/**/*.sass,health-dashboard/**/*.less,health-dashboard/**/*.html,health-dashboard/**/*.tsx,health-dashboard/**/*.jsx,health-dashboard/**/*.vue,health-dashboard/**/*.svelte"
---
> This file extends [common/testing.md](../common/testing.md) with web-specific testing content.

# Web Testing Rules

## Priority Order

### 1. Visual Regression

- Screenshot key breakpoints: 320, 768, 1024, 1440
- Test hero sections, scrollytelling sections, and meaningful states
- Use Playwright screenshots for visual-heavy work
- If both themes exist, test both

### 2. Accessibility

- Run automated accessibility checks
- Test keyboard navigation
- Verify reduced-motion behavior
- Verify color contrast

### 3. Performance

- Run Lighthouse or equivalent against meaningful pages
- Keep CWV targets from [performance.md](performance.md)

### 4. Cross-Browser

- Minimum: Chrome, Firefox, Safari
- Test scrolling, motion, and fallback behavior

### 5. Responsive

- Test 320, 375, 768, 1024, 1440, 1920
- Verify no overflow
- Verify touch interactions

## E2E Shape

```ts
import { test, expect } from '@playwright/test';

test('landing hero loads', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('h1')).toBeVisible();
});
```

- Avoid flaky timeout-based assertions
- Prefer deterministic waits

## Unit Tests

- Test utilities, data transforms, and custom hooks
- For highly visual components, visual regression often carries more signal than brittle markup assertions
- Visual regression supplements coverage targets; it does not replace them
