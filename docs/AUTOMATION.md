# ConsistiFit Web Automation

The ConsistiFit PWA is operated as an automated GitHub Pages deployment. The goal is to make normal web releases, monitoring, dependency maintenance and rollback require as little manual work as possible while keeping production tied to tested commits.

## Release flow

1. Changes are pushed to a branch and opened as a pull request.
2. `ConsistiFit CI` runs PWA regression tests, browser tests, the production web build and artifact verification. Flutter/native checks continue to run in parallel for shared-app safety.
3. After changes reach `main`, CI runs again on that exact commit.
4. `Deploy PWA to GitHub Pages` is triggered only after the `main` CI workflow completes successfully.
5. The deployment checks out the exact SHA that CI tested, rebuilds the web artifact, re-runs smoke tests, verifies the artifact and deploys only `dist/`.
6. `build-info.json` records the live commit and build id. The service-worker cache id is stamped from that commit, so manual `v12`, `v13`, etc. cache bumps are no longer required.

## Generated web artifact

Run locally:

```bash
npm ci
npm run build:web
npm run verify:web
```

The build is written to `dist/`. It contains only the deployable PWA files and assets plus a generated `build-info.json`.

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

When checks recover, the issue is automatically closed with a recovery note.

You can also run the same check manually:

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

The issue closes automatically after the audit becomes healthy again.

## Dependency automation

Dependabot checks every Monday for:

- npm/web dependency updates;
- GitHub Actions updates;
- Flutter/Dart package updates.

Updates are grouped to reduce pull-request noise. Dependabot does not silently merge changes; each update still goes through the normal ConsistiFit CI checks before it can reach production.

## Rollback

The Pages workflow doubles as the rollback tool.

1. Open GitHub → Actions → `Deploy PWA to GitHub Pages`.
2. Choose `Run workflow`.
3. Enter the last known-good commit SHA or tag in the `ref` field.
4. Run the workflow.

The workflow checks out that ref, runs smoke tests, builds and verifies it, and redeploys it to GitHub Pages. No force-push or history rewrite is required.

To identify what is currently live, open:

`https://bhrcs.github.io/ConsistiFit/build-info.json`

## Important GitHub settings

For the strongest protection, keep `main` as the production branch and require the `ConsistiFit CI` checks before merging pull requests. GitHub repository administration permissions are required to configure branch-protection/ruleset settings; they are intentionally separate from the app code.

## Automation files

- `.github/workflows/ci.yml` — regression, browser, build and artifact verification
- `.github/workflows/pages.yml` — tested deployment and rollback
- `.github/workflows/web-health.yml` — hourly production health monitoring
- `.github/workflows/web-audit.yml` — daily quality/security/Lighthouse audit
- `.github/dependabot.yml` — scheduled dependency updates
- `scripts/build-web.js` — creates the deployable artifact and cache/build stamp
- `scripts/verify-web-build.js` — validates all local production assets
- `scripts/check-production.js` — verifies the live deployment
- `.lighthouserc.json` — automated quality budgets
