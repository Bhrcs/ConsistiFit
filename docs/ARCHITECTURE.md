# ConsistiFit Architecture

## Clients
- Root PWA: investor/demo build, installable with offline shell caching.
- `flutter_app/`: production iOS/Android codebase.

## Production stack
- Flutter + Riverpod + go_router
- Supabase Auth/Postgres/RLS/RPC/Edge Functions
- Apple HealthKit + Android Health Connect through the Flutter `health` package
- Local notifications first; push notifications can be added after provider credentials are provisioned

## Trust boundaries
The client may propose workout data, but the backend owns RP, XP, Coins, rank changes, achievement grants, streak protection and competitive/social results. `complete_workout_and_reward` is the first server-authoritative transaction.

## Offline model
Workout sets should be written locally and synced when connectivity returns. Server reward claims remain idempotent through `reward_claimed` plus the reward ledger unique index.
