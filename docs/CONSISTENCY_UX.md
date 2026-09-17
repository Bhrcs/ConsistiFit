# Consistency experience and day-only workouts

Today shows the session length, working sets, equipment, previous performance and available primary reward. Starting a new session opens a preview; a saved active session resumes directly. Recovery has its own mobility and readiness flow. Set completion starts rest and gives brief feedback. The completion summary explains next-time targets using local history. Weekly recaps count elapsed tracked days, workouts, recovery, actual recorded RP, PRs and streaks, with the next week's projected schedule.

## Change today

- Pick another compatible saved/program workout, or generate Back, Chest, Legs, Shoulders, Arms, Core or Full Body from the existing exercise catalog.
- All required equipment must be selected. Home/Gym environment restrictions also apply; Choose Equipment permits the selected equipment combination. Unsupported focuses show an explanation. A leg press does not imply access to a hack squat machine.
- Review the full session before applying it. Applying creates a date-keyed snapshot; it does not edit the recurring program. Saving to the library requires an explicit action and does not activate that saved workout as a recurring plan.
- An active workout keeps its approved set target, equipment setup and start date through reloads. Finish it before replacing the day. Changes to future setup cannot rewrite the active session.
- No cloud service, account, model call or external workout generation is involved. Browser saves remain in localStorage; Flutter saves remain in device preferences.

## Rewards and history

The primary reward is shared by the planned session and an approved override. Complete at least 70% of its approved working sets to qualify. Swapping, repeating a workout, restoring the plan, reopening the app, or revisiting a date cannot create another primary claim. Partial sessions stay in history without primary credit. Recovery-day overrides retain the recovery day's reward budget and cannot add a mobility bonus. A session finished after midnight credits its captured start date; the new day's mission remains separate.

Web daily claims use a persistent per-date ledger. Flutter stores profile changes, session history and daily claims together in one local snapshot, with serialized writes. Existing local progress is migrated without granting new rewards. Older archives without exact reward receipts are identified in recaps rather than given invented RP totals.

Plan adaptation explains its evidence and offers explicit accept/keep controls. Web frequency suggestions require at least five past scheduled workouts and exclude today. Flutter's session suggestions explain previous difficulty and offer a day-only adjustment. Neither changes the plan without acceptance.

## Verification

```sh
npm test
npm ci
npx playwright install chromium
npm run test:browser
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

Browser tests can use an installed Chromium browser with `CHROME_PATH`. They use an isolated browser context and an ephemeral loopback server. They cover preview, override selection, set feedback, active-session reload, completion recommendations, repeat reward suppression, recovery logging, weekly recap, narrow viewport and offline reopening. Production-code regression tests additionally cover all focus/equipment combinations, malformed templates, explicit saves, migration, shortened sessions, overnight completion, calendar boundaries and adaptation decisions.

The PWA cache is v11 and includes the new local scripts and styles. CI also retains Android debug and iOS simulator build checks. No developer/test controls are added to the product UI.
