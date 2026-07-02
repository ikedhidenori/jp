# ZUKAN.PAGE deploy notes

Status: local staging ready / external publish not performed.

## Current Files

- `zukan/index.html`
- `zukan/styles.css`
- `zukan/DEPLOY.md`

`CNAME` is intentionally not active yet. It briefly caused GitHub Pages to
redirect `ikedhidenori.github.io/jp/zukan/` to `zukan.page/zukan/` while DNS
was still pointed at Porkbun default hosting. Add root `CNAME` only in the same
deployment window as the DNS change.

## Current External State

Observed 2026-07-03 JST:

```text
zukan.page A -> 44.227.65.245, 44.227.76.166
www.zukan.page CNAME -> pixie.porkbun.com
http://zukan.page/ -> 200, X-Service: pixie-default
https://zukan.page/ -> TLS handshake failure
```

This means the domain is still pointed at Porkbun default hosting, not GitHub Pages.

## Publish Choices

### Option A: Fast, minimal risk

Publish this hub at:

```text
https://zukan.page/zukan/
```

Keep the existing repository root `index.html` unchanged.

Required external changes:

1. Keep `zukan/` published on GitHub Pages.
2. Point DNS to GitHub Pages.
3. Add root `CNAME` with `zukan.page`, then enable GitHub Pages custom domain
   `zukan.page` and Enforce HTTPS.

### Option B: Canonical root

Publish this hub at:

```text
https://zukan.page/
```

This requires replacing or redirecting the repository root `index.html`, which currently serves the shared design-system page. Do this only after deciding that `zukan.page` should own the root of the whole publish repository.

## DNS Records for GitHub Pages

```text
zukan.page A 185.199.108.153
zukan.page A 185.199.109.153
zukan.page A 185.199.110.153
zukan.page A 185.199.111.153
www CNAME ikedhidenori.github.io
```

Keep existing MX records for Porkbun email forwarding.

## Verification After Publish

```bash
dig +short zukan.page A
dig +short www.zukan.page CNAME
curl -sI https://zukan.page/zukan/ | head
curl -sI https://zukan.page/ | head
```

Expected for Option A:

```text
https://zukan.page/zukan/ -> 200
https://zukan.page/ -> existing root page or redirect, depending on later choice
```

Until DNS and CNAME are applied together, use:

```text
https://ikedhidenori.github.io/jp/zukan/
```
