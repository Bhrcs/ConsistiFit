# ConsistiFit

ConsistiFit is a mobile-first fitness app built around **consistency instead of raw workout volume**. Scheduled training, recovery, missions and healthy habits move the user through ranks while permanent account XP tracks long-term progression.

## Repository
- `index.html` — GitHub Pages loader for the clickable investor prototype
- `payload/` — compressed prototype UI payload
- `manifest.webmanifest`, `service-worker.js`, `offline.html` — installable PWA layer
- `flutter_app/` — iOS/Android Flutter application
- `docs/` — product, architecture, health/notification and roadmap specifications
- `.github/workflows/pages.yml` — GitHub Pages deployment

## Current architecture
The current Flutter build is intentionally **local-first**. Profile progress, RP, XP, Coins, missions, shop purchases, workout logs and health summaries are stored on the device with `shared_preferences`. No cloud backend or account system is required at this stage.

## Core rules
- Rank: Iron → Bronze → Silver → Gold → Platinum → Diamond → Master → Grandmaster
- Account XP never decreases.
- Rank reflects current consistency and may move over time.
- Coins never purchase RP.
- Scheduled recovery counts.
- Extra unscheduled workouts do not farm RP.

## Current workout reward
A planned workout awards **30 base RP** once per day, with **5 RP** for that day's check-in. Planned recovery also earns **30 base RP**. Extra sessions remain in history without repeating the primary reward.

## Today and workout changes
Today now includes a session preview, equipment and recent performance, recovery guidance, weekly recap and explained next-time targets. Replace today's session with a compatible saved/program workout or a muscle-focused workout from the local exercise library. Overrides apply to that date only; saving for reuse is explicit. Training and recovery share one primary reward claim per day, so swaps and extra sessions cannot farm RP.

See [the consistency UX guide](docs/CONSISTENCY_UX.md) for behavior, migration and regression checks.

## PWA
The prototype is installable and caches its core UI payload for offline reopening after the first successful load. iPhone users can use Safari → Share → Add to Home Screen; supported Android browsers can install it as a standalone app.

## Flutter
The mobile source is under `flutter_app/`. On a machine with Flutter 3.44+/Dart 3.12+, run:

```bash
flutter pub get
flutter test
flutter run
```

HealthKit / Health Connect and local notification support remain available. Online accounts, cloud sync and multiplayer social features are deferred until a backend is actually needed.

## Pexels photo sources
The investor prototype uses selected Pexels workout photographs under the Pexels License. Attribution is not required, but sources are retained for recordkeeping. The people pictured are generic stock subjects and must not be presented as ConsistiFit endorsers/testimonials.
- Marius Aholou: https://www.pexels.com/photo/a-man-using-dumbbells-11432959/
- Tima Miroshnichenko: https://www.pexels.com/photo/a-man-stretching-at-the-gym-6389890/
- Alexander Savchuk: https://www.pexels.com/photo/man-in-white-crew-neck-shirt-running-on-asphalt-road-9616175/
- Marius Aholou: https://www.pexels.com/photo/a-muscular-man-working-out-11433059/
- Alef Morais: https://www.pexels.com/photo/focused-athlete-portrait-in-a-gym-setting-36085104/

See `docs/ROADMAP.md` for the remaining product and release steps.
