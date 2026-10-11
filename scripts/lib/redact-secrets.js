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
  // user:password@ in any URI scheme; keep scheme, user and host.
  [/\b([a-z][a-z0-9+.-]*:\/\/[^\s:/@]+:)[^\s@]+@/gi, (_m, prefix) => `${prefix}${REDACTED}@`],
  // Secret-named key assigned a random-looking value (letter + digit, 16+ chars).
  [
    /((?:api[_-]?key|secret|password|passwd|token)\w*['"]?\s*[:=]\s*['"]?)(?=[^'"\s]*[0-9])(?=[^'"\s]*[A-Za-z])[^'"\s]{16,}/gi,
    (_m, prefix) => `${prefix}${REDACTED}`,
  ],
];

function redactSecrets(text) {
  if (typeof text !== 'string' || text.length === 0) return text;
  return RULES.reduce((acc, [regex, replacer]) => acc.replace(regex, replacer), text);
}

module.exports = { redactSecrets, REDACTED };
