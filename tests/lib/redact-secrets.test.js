/**
 * Tests for scripts/lib/redact-secrets.js
 *
 * Fake secrets are assembled by concatenation so this file never trips the
 * pre-commit secret scan.
 *
 * Run with: node tests/lib/redact-secrets.test.js
 */

const assert = require('assert');
const { redactSecrets, REDACTED } = require('../../scripts/lib/redact-secrets');

const LONG = 'A1b2C3d4E5f6G7h8J9k0L1m2';

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    return true;
  } catch (error) {
    console.log(`  ✗ ${name}`);
    console.log(`    Error: ${error.message}`);
    return false;
  }
}

function assertRedacted(input, secret) {
  const out = redactSecrets(input);
  assert.ok(!out.includes(secret), `secret survived: ${out}`);
  assert.ok(out.includes(REDACTED), `no redaction marker: ${out}`);
}

console.log('\n=== Testing redact-secrets ===\n');

let passed = 0;
let failed = 0;

const stripeLive = `${'sk_' + 'live_'}${LONG}`;
const webhook = `${'wh' + 'sec_'}${LONG}`;
const ghToken = `${'gh' + 'p_'}${'a1B2'.repeat(9)}`;
const awsKey = `${'AK' + 'IA'}ABCDEFGHIJKLMNOP`;
const anthropicKey = `${'sk-' + 'ant-'}api03-${LONG}`;
const jwt = `${'ey' + 'J'}hbGciOiJIUzI1NiJ9.${'ey' + 'J'}zdWIiOiIxMjM0NTY3ODkwIn0.${LONG}`;

const cases = [
  ['redacts a Stripe live key in prose', () => assertRedacted(`please use ${stripeLive} for the test`, stripeLive)],
  ['redacts a Stripe webhook secret', () => assertRedacted(`STRIPE_WEBHOOK_SECRET=${webhook}`, webhook)],
  ['redacts a GitHub token', () => assertRedacted(`token is ${ghToken}`, ghToken)],
  ['redacts an AWS access key id', () => assertRedacted(`aws key ${awsKey} here`, awsKey)],
  ['redacts an Anthropic/OpenAI-style key', () => assertRedacted(`export KEY=${anthropicKey}`, anthropicKey)],
  ['redacts a JWT', () => assertRedacted(`Authorization: Bearer ${jwt}`, jwt)],
  ['redacts the password in a URI but keeps the host', () => {
    const out = redactSecrets(`MONGO_URI=${'mongodb' + '+srv://'}admin:${LONG}@cluster0.example.net/db`);
    assert.ok(!out.includes(LONG), out);
    assert.ok(out.includes('cluster0.example.net'), out);
  }],
  ['redacts a random-looking value assigned to a secret-named key', () => assertRedacted(`JWT_SECRET="${'9f3a'.repeat(8)}"`, '9f3a'.repeat(8))],
  ['redacts a private key block', () => assertRedacted(`${'-----BEGIN ' + 'PRIVATE KEY-----'}\nMIIEv${LONG}\n-----END PRIVATE KEY-----`, `MIIEv${LONG}`)],
  ['leaves ordinary prose untouched', () => {
    const text = 'Fix the payout cron and add a regression test for token refresh';
    assert.strictEqual(redactSecrets(text), text);
  }],
  ['leaves a credential-free URI untouched', () => {
    const text = 'mongodb://localhost:27017/neopadel';
    assert.strictEqual(redactSecrets(text), text);
  }],
  ['returns non-strings unchanged', () => {
    assert.strictEqual(redactSecrets(null), null);
    assert.strictEqual(redactSecrets(undefined), undefined);
  }],
];

for (const [name, fn] of cases) {
  if (test(name, fn)) passed++;
  else failed++;
}

console.log(`\nPassed: ${passed}`);
console.log(`Failed: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
