# ConsistiFit Web Roadmap

## Implemented foundation

- Installable PWA manifest, service worker, offline fallback and icons
- GitHub Pages production deployment
- Consistency-based rank, XP, Coins, missions and recovery rules
- Program generator, workout engine and one-day workout overrides
- Equipment-aware muscle-focused workout generation
- Workout history, progression recommendations and weekly recaps
- Premium Rank, Progress, routines and workout-logging UI
- Local-first browser persistence
- Automated web regression and Chromium browser-flow tests
- Automated production artifact verification and commit-stamped cache versioning
- Hourly production health checks
- Daily Lighthouse/security quality audits
- Weekly npm and GitHub Actions dependency updates
- Manual known-good-commit rollback through GitHub Actions

## Current focus

- Improve web/PWA reliability and user experience
- Expand browser regression coverage for unusual/error states
- Continue performance and accessibility improvements
- Refine workout/program quality and progression logic
- Prepare the PWA for real-user testing without adding unnecessary platform complexity

## Deferred until needed

- User accounts and authentication
- Cloud sync across devices
- Server-authoritative RP/XP/Coins/rank validation
- Networked friends, squads, challenges and activity feed
- Remote push infrastructure
- Native iOS/Android release work

## Parked native work

The existing `flutter_app/` prototype is retained only as a future reference. Native CI, Android/iOS builds, Flutter dependency automation, signing and app-store packaging are intentionally paused while ConsistiFit focuses on the webpage/PWA.
