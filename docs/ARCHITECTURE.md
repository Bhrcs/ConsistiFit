# ConsistiFit Architecture

## Clients
- Root PWA: investor/demo build, installable with offline shell caching.
- `flutter_app/`: iOS/Android Flutter codebase.

## Current stack
- Flutter + Riverpod + go_router
- `shared_preferences` for local prototype state
- Apple HealthKit + Android Health Connect through the Flutter `health` package
- Local notifications

## Current trust model
This phase is intentionally local-first. RP, XP, Coins, missions, rank, shop purchases and workout history are prototype state stored on the device. Competitive security and cloud-authoritative rewards are deferred until a backend is actually introduced.

## Offline model
The current mobile build works without network access for its core progression and workout logging. Health access still depends on the device platform APIs, and online social/account features remain future work.
