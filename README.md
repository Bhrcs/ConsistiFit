# ConsistiFit

ConsistiFit is a mobile-first fitness app built around **consistency instead of raw workout volume**. Scheduled training, recovery, missions and healthy habits move the user through ranks while permanent account XP tracks long-term progression.

## Repository
- `index.html` — GitHub Pages loader for the clickable investor prototype
- `payload/` — compressed prototype UI payload
- `manifest.webmanifest`, `service-worker.js`, `offline.html` — installable PWA layer
- `flutter_app/` — production iOS/Android Flutter application scaffold
- `supabase/` — Postgres schema, RLS and server-authoritative reward function
- `docs/` — product, architecture, health/notification and roadmap specifications
- `.github/workflows/pages.yml` — GitHub Pages deployment

## Core rules
- Rank: Iron → Bronze → Silver → Gold → Platinum → Diamond → Master → Grandmaster
- Account XP never decreases.
- Rank reflects current consistency and may move over time.
- Coins never purchase RP.
- Scheduled recovery counts.
- Extra unscheduled workouts do not farm RP.
- Workout rewards are server-authoritative in production.

## Current workout reward
A scheduled workout plus difficulty check-in awards **35 RP, 240 XP and 85 Coins** once. The Supabase RPC makes the claim idempotent.

## PWA
The prototype is installable and caches its core UI payload for offline reopening after the first successful load. iPhone users can use Safari → Share → Add to Home Screen; supported Android browsers can install it as a standalone app.

## Flutter
The production source is under `flutter_app/`. On a machine with Flutter 3.44+/Dart 3.12+, run `flutter pub get`, `flutter test`, then `flutter run` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` Dart defines.

The project uses stable September 2026 packages: Riverpod 3.4.3, go_router 18.0.1, supabase_flutter 2.17.2, health 13.3.2 and flutter_local_notifications 22.3.1.

## Pexels photo sources
The investor prototype uses selected Pexels workout photographs under the Pexels License. Attribution is not required, but sources are retained for recordkeeping. The people pictured are generic stock subjects and must not be presented as ConsistiFit endorsers/testimonials.
- Marius Aholou: https://www.pexels.com/photo/a-man-using-dumbbells-11432959/
- Tima Miroshnichenko: https://www.pexels.com/photo/a-man-stretching-at-the-gym-6389890/
- Alexander Savchuk: https://www.pexels.com/photo/man-in-white-crew-neck-shirt-running-on-asphalt-road-9616175/
- Marius Aholou: https://www.pexels.com/photo/a-muscular-man-working-out-11433059/
- Alef Morais: https://www.pexels.com/photo/focused-athlete-portrait-in-a-gym-setting-36085104/

See `docs/ROADMAP.md` for account/credential/device-signing steps that cannot be provisioned from source code alone.
