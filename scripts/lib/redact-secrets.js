/**
 * Redact high-signal secrets from free text before it is persisted
 * (session summaries, handoff files). Keeps surrounding context readable:
 * key names, URI hosts and prose stay, only the secret value is replaced.
 */

const REDACTED = '[REDACTED]';

// Each entry: [regex, replacer]. Replacers keep non-secret capture groups.
const RULES = [
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?(?:-----END [A-Z ]*PRIVATE KEY-----|$)/g, () => REDACTED],
  [/\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g, () => REDACTED],
  [/\bsk-[A-Za-z0-9_-]{20,}/g, () => REDACTED],
  [/\b[sr]k_(?:live|test)_[A-Za-z0-9]{16,}/g, () => REDACTED],
  [/\bwhsec_[A-Za-z0-9]{16,}/g, () => REDACTED],
  [/\bgh[pousr]_[A-Za-z0-9]{36,}/g, () => REDACTED],
  [/\bgithub_pat_[A-Za-z0-9_]{20,}/g, () => REDACTED],
  [/\bAKIA[0-9A-Z]{16}\b/g, () => REDACTED],
  [/\bxox[abprs]-[A-Za-z0-9-]{10,}/g, () => REDACTED],
  [/\b(Bearer\s+)[A-Za-z0-9._~+/-]{20,}=*/gi, (_m, prefix) => `${prefix}${REDACTED}`],
  // [user]:password@ in any URI scheme (userinfo never contains "/", so host:port/@path
  // stays intact); keep scheme, user and host.
  [/\b([a-z][a-z0-9+.-]*:\/\/[^\s:/@]*:)[^\s@/]+@/gi, (_m, prefix) => `${prefix}${REDACTED}@`],
  // Secret-named key assigned a random-looking value (letter + digit, 16+ chars).
  // URL/path keys (TOKEN_URL, tokenizer), URLs (their credentials are handled by the URI rule
  // above) and ./ ../ paths are left alone; a bare leading "/" is not, base64 can start with it.
  [
    /((?:api[_-]?key|secret|password|passwd|token)(?!s\b|izer|_?url|_?path|_?endpoint)\w*['"]?\s*[:=]\s*['"]?)(?![a-z][a-z0-9+.-]*:\/\/|\.{1,2}\/)(?=[^'"\s]*[0-9])(?=[^'"\s]*[A-Za-z])[^'"\s]{16,}/gi,
    (_m, prefix) => `${prefix}${REDACTED}`,
  ],
];

function redactSecrets(text) {
  if (typeof text !== 'string' || text.length === 0) return text;
  return RULES.reduce((acc, [regex, replacer]) => acc.replace(regex, replacer), text);
}

module.exports = { redactSecrets, REDACTED };
