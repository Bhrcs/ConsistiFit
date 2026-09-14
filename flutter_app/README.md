# ConsistiFit Flutter App

This folder is the production mobile scaffold. It runs in demo mode without Supabase credentials and switches to cloud mode when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are supplied as Dart defines.

Before shipping on devices, configure HealthKit capability/usage descriptions on iOS and Health Connect permissions on Android, then initialize `HealthService` only after the user opts in. Configure local notification permissions after onboarding rather than at first launch.

Suggested commands:

```bash
flutter pub get
flutter test
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
