# Health and Notifications

## Health
The Flutter app scaffolds Apple HealthKit and Android Health Connect reads for steps, active energy, heart rate, workouts and sleep. Health is opt-in and is never required for core workout logging. Native entitlements/permissions must be configured before device builds.

## Notifications
Start with local workout and mission reminders. Quiet hours live in `notification_preferences`. Remote push can be added after APNs/FCM credentials are provisioned. Recovery-day reminders should explicitly count recovery as progress rather than using guilt-based streak language.
