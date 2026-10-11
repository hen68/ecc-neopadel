# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

MANDATORY workflow:
1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

## Test Quality Gates

A green test only counts if it can go red:

- **Name the break first.** Before writing the test body, name the production change that would make it fail. If you can't, the test checks nothing.
- **Watch it fail.** Run a new test before the fix and confirm it fails for the intended reason (not "No tests found", an import error or a timeout).
- **No mirror assertions.** Never compute the expected value with the code under test; use a literal or an independent calculation.
- **Mocks earn no assertions.** Asserting only that a mock was called proves nothing about behavior; assert on the result or the persisted state.
- **No change detectors.** Don't assert on source text or incidental internals that break on harmless refactors.
- **Your test green is not the suite green.** Run the full affected suite before claiming success, and name any failure you leave behind.

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first

## Test Structure (AAA Pattern)

Prefer Arrange-Act-Assert structure for tests:

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### Test Naming

Use descriptive names that explain the behavior under test:

```typescript
test('returns empty array when no markets match query', () => {})
test('throws error when API key is missing', () => {})
test('falls back to substring search when Redis is unavailable', () => {})
```
