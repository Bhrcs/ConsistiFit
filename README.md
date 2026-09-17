# ConsistiFit

ConsistiFit is a mobile-first **web/PWA fitness app** built around consistency instead of raw workout volume. Scheduled training, recovery, missions and healthy habits move the user through ranks while permanent account XP tracks long-term progression.

## Live app

https://bhrcs.github.io/ConsistiFit/

## Active repository scope

ConsistiFit is currently being developed, tested and deployed as a web/PWA project.

- `index.html` — production entry point
- `*.js` / `*.css` — workout, progression, rank, routines and UX systems
- `assets/` — web assets
- `manifest.webmanifest`, `service-worker.js`, `offline.html` — installable/offline PWA layer
- `tests/` — web regression and browser-flow tests
- `scripts/` — production build, verification and health-check automation
- `docs/` — product, architecture, UX, automation and roadmap notes
- `.github/workflows/` — web CI, deployment, production monitoring and quality audits

The older `flutter_app/` prototype is parked for possible future native work. It is not part of active CI, deployment, dependency automation, or GitHub language statistics.

## Core rules

- Rank: Iron → Bronze → Silver → Gold → Platinum → Diamond → Master → Grandmaster
- Account XP never decreases.
- Rank reflects current consistency and may move over time.
- Coins never purchase RP.
- Scheduled recovery counts.
- Extra unscheduled workouts do not farm RP.

## Workout rewards

A planned workout awards **30 base RP** once per day, with **5 RP** for that day's check-in. Planned recovery also earns **30 base RP**. Extra sessions remain in history without repeating the primary reward.

## Today and workout changes

Today includes a session preview, equipment and recent performance, recovery guidance, weekly recap and explained next-time targets. Users can replace today's session with a compatible saved/program workout or generate a muscle-focused workout from the exercise library. Overrides apply to that date only unless explicitly saved. Training and recovery share one primary reward claim per day, so swaps and extra sessions cannot farm RP.

See [the consistency UX guide](docs/CONSISTENCY_UX.md) for behavior and regression rules.

## Automated web operations

Pull requests and `main` run web regression tests, browser tests, production artifact validation and build verification. GitHub Pages deploys only after the exact `main` commit passes **ConsistiFit Web CI**. Deployment stamps the service-worker cache from the commit automatically and publishes `build-info.json`, so manual cache-version bumps are not required.

Production is checked hourly. A Lighthouse/security quality audit runs daily. Dependabot checks npm and GitHub Actions weekly. The Pages workflow also supports manual deployment of a known-good commit for rollback.

See [Web Automation](docs/AUTOMATION.md) for deployment, monitoring and rollback instructions.

## Run the web app locally

```bash
npm ci
npm test
npm run build:web
npm run verify:web
```

For the automated Chromium user-flow regression suite:

```bash
npx playwright install chromium
npm run test:browser
```

The deployable artifact is written to `dist/`.

## Install as an app

The PWA can be installed from supported mobile and desktop browsers and reopens offline after its first successful load. On iPhone, use Safari → Share → Add to Home Screen. Supported Android and desktop browsers can install it as a standalone web app.

## Pexels photo sources

The prototype uses selected Pexels workout photographs under the Pexels License. Attribution is not required, but sources are retained for recordkeeping. The people pictured are generic stock subjects and must not be presented as ConsistiFit endorsers/testimonials.

- Marius Aholou: https://www.pexels.com/photo/a-man-using-dumbbells-11432959/
- Tima Miroshnichenko: https://www.pexels.com/photo/a-man-stretching-at-the-gym-6389890/
- Alexander Savchuk: https://www.pexels.com/photo/man-in-white-crew-neck-shirt-running-on-asphalt-road-9616175/
- Marius Aholou: https://www.pexels.com/photo/a-muscular-man-working-out-11433059/
- Alef Morais: https://www.pexels.com/photo/focused-athlete-portrait-in-a-gym-setting-36085104/

See `docs/ROADMAP.md` for the current web roadmap.
