# ConsistiFit Architecture

## Active client

ConsistiFit is currently a mobile-first web/PWA deployed through GitHub Pages.

## Active stack

- HTML, CSS and JavaScript PWA
- Browser `localStorage` for local-first prototype state
- Web App Manifest + service worker for installability/offline reopening
- Node-based build and verification scripts
- Playwright/Chromium browser regression tests
- GitHub Actions for CI, deployment, monitoring and Lighthouse/security audits

## Current trust model

This phase is intentionally local-first. RP, XP, Coins, missions, rank, shop purchases, workout history and preferences are stored in the browser. Competitive security, accounts, cross-device sync and cloud-authoritative rewards are deferred until a backend is actually needed.

## Offline model

After a successful first load, the service worker caches the core PWA shell/assets so the app can reopen offline. Workout state is stored locally and can resume after reload. Production builds use commit-stamped cache ids to prevent stale releases.

## Parked native prototype

`flutter_app/` contains earlier native-app work retained for possible future use. It is not part of the current product architecture, CI, deployment or dependency-maintenance pipeline.
