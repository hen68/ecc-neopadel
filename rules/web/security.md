---
globs: "admin/**/*.css,admin/**/*.scss,admin/**/*.sass,admin/**/*.less,admin/**/*.html,admin/**/*.tsx,admin/**/*.jsx,admin/**/*.vue,admin/**/*.svelte,store-app/**/*.css,store-app/**/*.scss,store-app/**/*.sass,store-app/**/*.less,store-app/**/*.html,store-app/**/*.tsx,store-app/**/*.jsx,store-app/**/*.vue,store-app/**/*.svelte,store-kiosk/**/*.css,store-kiosk/**/*.scss,store-kiosk/**/*.sass,store-kiosk/**/*.less,store-kiosk/**/*.html,store-kiosk/**/*.tsx,store-kiosk/**/*.jsx,store-kiosk/**/*.vue,store-kiosk/**/*.svelte,web-app/**/*.css,web-app/**/*.scss,web-app/**/*.sass,web-app/**/*.less,web-app/**/*.html,web-app/**/*.tsx,web-app/**/*.jsx,web-app/**/*.vue,web-app/**/*.svelte,health-dashboard/**/*.css,health-dashboard/**/*.scss,health-dashboard/**/*.sass,health-dashboard/**/*.less,health-dashboard/**/*.html,health-dashboard/**/*.tsx,health-dashboard/**/*.jsx,health-dashboard/**/*.vue,health-dashboard/**/*.svelte"
---
> This file extends [common/security.md](../common/security.md) with web-specific security content.

# Web Security Rules

## Content Security Policy

Always configure a production CSP.

### Nonce-Based CSP

Use a per-request nonce for scripts instead of `'unsafe-inline'`.

```text
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{RANDOM}' https://cdn.jsdelivr.net;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  img-src 'self' data: https:;
  font-src 'self' https://fonts.gstatic.com;
  connect-src 'self' https://*.example.com;
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
```

Adjust origins to the project. Do not cargo-cult this block unchanged.

## XSS Prevention

- Never inject unsanitized HTML
- Avoid `innerHTML` / `dangerouslySetInnerHTML` unless sanitized first
- Escape dynamic template values
- Sanitize user HTML with a vetted local sanitizer when absolutely necessary

## Third-Party Scripts

- Load asynchronously
- Use SRI when serving from a CDN
- Audit quarterly
- Prefer self-hosting for critical dependencies when practical

## HTTPS and Headers

```text
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## Forms

- CSRF protection on state-changing forms
- Rate limiting on submission endpoints
- Validate client and server side
- Prefer honeypots or light anti-abuse controls over heavy-handed CAPTCHA defaults
