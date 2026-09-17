# ConsistiFit Web Automation

ConsistiFit is currently operated as a web/PWA project on GitHub Pages. Normal web releases, monitoring, dependency maintenance and rollback are automated while production stays tied to tested commits.

## Release flow

1. Changes are pushed to a branch and opened as a pull request.
2. `ConsistiFit Web CI` runs web regression tests, browser-flow tests, the production web build and artifact verification.
3. After changes reach `main`, the same web CI runs again on that exact commit.
4. `Deploy PWA to GitHub Pages` is triggered only after the `main` web CI workflow completes successfully.
5. Deployment checks out the exact SHA that CI tested, rebuilds the web artifact, reruns smoke tests, verifies the artifact and deploys only `dist/`.
6. `build-info.json` records the live commit/build id. The service-worker cache id is stamped from that commit automatically.

No Flutter, Android or iOS jobs are part of the active release gate.

## Generated web artifact

Run locally:

```bash
npm ci
npm run build:web
npm run verify:web
```

The build is written to `dist/`. It contains only deployable PWA files/assets plus generated `build-info.json`.

## Browser regression

The automated browser suite exercises real ConsistiFit flows in Chromium, including workout preview, set completion, reload/resume, weekly recap, mobile layout and offline behavior.

```bash
npx playwright install chromium
npm run test:browser
```

## Production monitoring

`Production Health Check` runs hourly and verifies:

- the public ConsistiFit page responds;
- the app name is present;
- the manifest is valid;
- the service worker is deployed with a stamped cache id;
- `build-info.json` matches the service worker;
- every local asset referenced by the production page responds successfully.

If the check fails, GitHub automatically opens or updates an issue titled:

`[Automation] Production health check failing`

When checks recover, that issue is automatically closed.

Run the same check manually with:

```bash
npm run check:production
```

## Daily web quality audit

`Web Quality Audit` runs once per day and can also be started manually. It checks:

- production availability and asset integrity;
- npm dependency security with `npm audit --audit-level=high`;
- Lighthouse accessibility, best-practice, performance and SEO budgets.

Lighthouse reports are uploaded as workflow artifacts for 14 days. A failing audit opens or updates:

`[Automation] Web quality audit needs attention`

## Dependency automation

Dependabot checks every Monday for:

- npm/web dependency updates;
- GitHub Actions updates.

Updates are grouped to reduce pull-request noise. Each update must still pass normal web CI before it can reach production.

## Rollback

The Pages workflow doubles as the rollback tool.

1. Open GitHub → Actions → `Deploy PWA to GitHub Pages`.
2. Choose `Run workflow`.
3. Enter the last known-good commit SHA or tag in the `ref` field.
4. Run the workflow.

The workflow checks out that ref, runs web smoke tests, builds and verifies it, and redeploys it to GitHub Pages. No force-push or history rewrite is required.

To identify what is currently live, open:

`https://bhrcs.github.io/ConsistiFit/build-info.json`

## Native prototype status

`flutter_app/` is parked for possible future native development. It is intentionally excluded from active CI, release automation, Dependabot and GitHub language statistics while ConsistiFit focuses on the PWA.

## Automation files

- `.github/workflows/ci.yml` — web regression, browser, build and artifact verification
- `.github/workflows/pages.yml` — tested deployment and rollback
- `.github/workflows/web-health.yml` — hourly production health monitoring
- `.github/workflows/web-audit.yml` — daily quality/security/Lighthouse audit
- `.github/dependabot.yml` — npm and GitHub Actions dependency updates
- `scripts/build-web.js` — creates the deployable artifact and cache/build stamp
- `scripts/verify-web-build.js` — validates local production assets
- `scripts/check-production.js` — verifies the live deployment
- `.lighthouserc.json` — automated quality budgets
