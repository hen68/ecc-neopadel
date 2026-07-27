---
globs: "admin/**/*.css,admin/**/*.scss,admin/**/*.sass,admin/**/*.less,admin/**/*.html,admin/**/*.tsx,admin/**/*.jsx,admin/**/*.vue,admin/**/*.svelte,store-app/**/*.css,store-app/**/*.scss,store-app/**/*.sass,store-app/**/*.less,store-app/**/*.html,store-app/**/*.tsx,store-app/**/*.jsx,store-app/**/*.vue,store-app/**/*.svelte,store-kiosk/**/*.css,store-kiosk/**/*.scss,store-kiosk/**/*.sass,store-kiosk/**/*.less,store-kiosk/**/*.html,store-kiosk/**/*.tsx,store-kiosk/**/*.jsx,store-kiosk/**/*.vue,store-kiosk/**/*.svelte,web-app/**/*.css,web-app/**/*.scss,web-app/**/*.sass,web-app/**/*.less,web-app/**/*.html,web-app/**/*.tsx,web-app/**/*.jsx,web-app/**/*.vue,web-app/**/*.svelte,health-dashboard/**/*.css,health-dashboard/**/*.scss,health-dashboard/**/*.sass,health-dashboard/**/*.less,health-dashboard/**/*.html,health-dashboard/**/*.tsx,health-dashboard/**/*.jsx,health-dashboard/**/*.vue,health-dashboard/**/*.svelte"
---
> This file extends [common/patterns.md](../common/patterns.md) with web-specific patterns.

# Web Patterns

## Component Composition

### Compound Components

Use compound components when related UI shares state and interaction semantics:

```tsx
<Tabs defaultValue="overview">
  <Tabs.List>
    <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="overview">...</Tabs.Content>
  <Tabs.Content value="settings">...</Tabs.Content>
</Tabs>
```

- Parent owns state
- Children consume via context
- Prefer this over prop drilling for complex widgets

### Render Props / Slots

- Use render props or slot patterns when behavior is shared but markup must vary
- Keep keyboard handling, ARIA, and focus logic in the headless layer

### Container / Presentational Split

- Container components own data loading and side effects
- Presentational components receive props and render UI
- Presentational components should stay pure

## State Management

Treat these separately:

| Concern | Tooling |
|---------|---------|
| Server state | TanStack Query, SWR, tRPC |
| Client state | Zustand, Jotai, signals |
| URL state | search params, route segments |
| Form state | React Hook Form or equivalent |

- Do not duplicate server state into client stores
- Derive values instead of storing redundant computed state

## URL As State

Persist shareable state in the URL:
- filters
- sort order
- pagination
- active tab
- search query

## Data Fetching

### Stale-While-Revalidate

- Return cached data immediately
- Revalidate in the background
- Prefer existing libraries instead of rolling this by hand

### Optimistic Updates

- Snapshot current state
- Apply optimistic update
- Roll back on failure
- Emit visible error feedback when rolling back

### Parallel Loading

- Fetch independent data in parallel
- Avoid parent-child request waterfalls
- Prefetch likely next routes or states when justified
