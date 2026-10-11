/**
 * Tests for the Codex pre-commit secret scan (scripts/codex-git-hooks/pre-commit).
 *
 * Fake secrets are assembled by concatenation so this file never matches the
 * scanner itself when committed.
 */

const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const repoRoot = path.join(__dirname, '..', '..');
const preCommitHook = path.join(repoRoot, 'scripts', 'codex-git-hooks', 'pre-commit');

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

function git(cwd, args) {
  const result = spawnSync('git', args, { cwd, encoding: 'utf8' });
  if (result.status !== 0) throw new Error(`git ${args.join(' ')} failed: ${result.stderr}`);
}

function runHookOnStaged(fileName, content) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ecc-precommit-'));
  try {
    git(dir, ['init', '-q']);
    fs.writeFileSync(path.join(dir, fileName), `${content}\n`);
    git(dir, ['add', fileName]);
    const env = { ...process.env };
    delete env.ECC_SKIP_GIT_HOOKS;
    delete env.ECC_SKIP_PRECOMMIT;
    return spawnSync('bash', [preCommitHook], { cwd: dir, encoding: 'utf8', env });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function assertBlocked(fileName, content) {
  const result = runHookOnStaged(fileName, content);
  assert.strictEqual(result.status, 1, `expected block for ${JSON.stringify(content)}; stderr: ${result.stderr}`);
}

function assertAllowed(fileName, content) {
  const result = runHookOnStaged(fileName, content);
  assert.strictEqual(result.status, 0, `expected allow for ${JSON.stringify(content)}; stderr: ${result.stderr}`);
}

console.log('\n=== Testing codex pre-commit secret scan ===\n');

let passed = 0;
let failed = 0;

const cases = [
  ['blocks a Stripe live secret key in an env file', () => assertBlocked('.env', `STRIPE_SECRET_KEY=${'sk_' + 'live_'}${LONG}`)],
  ['blocks a Stripe test secret key in code', () => assertBlocked('config.js', `stripeSecret: '${'sk_' + 'test_'}${LONG}',`)],
  ['blocks a Stripe restricted key', () => assertBlocked('config.js', `const k = "${'rk_' + 'live_'}${LONG}";`)],
  ['blocks a Stripe webhook signing secret', () => assertBlocked('.env', `STRIPE_WEBHOOK_SECRET=${'wh' + 'sec_'}${LONG}`)],
  ['blocks a Mongo URI with embedded credentials', () => assertBlocked('.env', `MONGO_URI=${'mongodb' + '+srv://'}admin:${LONG}@cluster0.example.mongodb.net/db`)],
  ['blocks a quoted secret whose key name has a prefix', () => assertBlocked('config.js', `const STRIPE_SECRET_KEY = '${LONG}';`)],
  ['blocks a quoted secret in a camelCase key', () => assertBlocked('config.js', `  clientSecret: "${LONG}",`)],
  ['blocks a lowercase hex secret', () => assertBlocked('.env', `JWT_SECRET="${'9f3a'.repeat(8)}"`)],
  ['allows a Mongo URI with a placeholder password', () => assertAllowed('.env.example', '# format: mongodb://user:password@host.com/database')],
  ['allows a Mongo URI with an interpolated password', () => assertAllowed('deploy.sh', 'MONGO_URI="mongodb://app:${MONGO_PASSWORD}@db:27017/x"')],
  ['allows a readable test-fixture token', () => assertAllowed('auth.test.js', "  token: 'valid-reset-token',")],
  ['blocks a private key block', () => assertBlocked('key.pem', `${'-----BEGIN ' + 'RSA PRIVATE KEY-----'}`)],
  ['blocks a Mongo password that merely starts with "pass"', () => assertBlocked('.env', `MONGO_URI=${'mongodb' + '://'}admin:Passw0rd2024xyz@db/x`)],
  ['blocks a credentialed non-Mongo URI under a secret-named key', () => assertBlocked('.env', `DB_PASSWORD="${'postgres' + '://'}admin:hunter2abc123@db.internal/app"`)],
  ['blocks a base64 secret that starts with a slash', () => assertBlocked('.env', `${'AWS_SECRET' + '_ACCESS_KEY'}="/fK3xw9aQpLm2ZrT8vYbN4cHdJ6eG1sU0iOkWq7R"`)],
  ['allows an OAuth token endpoint constant', () => assertAllowed('oauth.js', "const TOKEN_URL = 'https://oauth2.googleapis.com/token';")],
  ['allows a password-reset route', () => assertAllowed('routes.js', '  resetPasswordUrl: "/auth/reset-password/v2/confirm",')],
  ['allows a Mongo URI with an @ after the path', () => assertAllowed('.env', 'MONGO_URI=mongodb://localhost:27017/app?x=@y')],
  ['allows a credential-free local Mongo URI', () => assertAllowed('.env', 'MONGO_URI=mongodb://localhost:27017/neopadel')],
  ['allows a short Stripe placeholder', () => assertAllowed('.env.example', `STRIPE_SECRET_KEY=${'sk_' + 'test_'}xxx`)],
  ['allows reading a token from a variable', () => assertAllowed('auth.js', 'const token = req.headers.authorization;')],
  ['allows UI copy that mentions a password', () => assertAllowed('en.json', '  "passwordLabel": "Enter your password here",')],
];

for (const [name, fn] of cases) {
  if (test(name, fn)) passed++;
  else failed++;
}

console.log(`\nPassed: ${passed}`);
console.log(`Failed: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
