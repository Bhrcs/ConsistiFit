# ConsistiFit Flutter App

This folder contains the mobile Flutter application. The current build is local-first and does not require any cloud backend, account credentials or environment variables.

Local device storage currently handles profile progress, RP, XP, Coins, missions, shop purchases, workout history and cached health summaries. Online accounts, cloud sync and networked social features are intentionally deferred.

Before shipping on devices, configure HealthKit capability/usage descriptions on iOS and Health Connect permissions on Android, then initialize `HealthService` only after the user opts in. Configure local notification permissions after onboarding rather than at first launch.

Suggested commands:

```bash
flutter pub get
flutter test
flutter run
```
