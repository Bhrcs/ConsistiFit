# Roadmap

## Implemented foundation
- PWA manifest, service worker, offline fallback, icons and GitHub Pages workflow
- Functional investor prototype
- Flutter production project structure
- Program generator and workout engine rules
- Supabase schema, authentication profile trigger, RLS and server-authoritative workout rewards
- Starter exercise database
- Health integration service scaffold
- Notification service scaffold
- Friends, squads, challenges and activity-feed foundation

## External setup still required
- Create a Supabase project and apply the migrations
- Provide `SUPABASE_URL` and `SUPABASE_ANON_KEY` via Dart defines
- Enable Apple/Google auth providers if desired
- Configure iOS HealthKit entitlements and Android Health Connect permissions
- Configure notification entitlements and a push provider for remote push
- Set GitHub Pages Source to GitHub Actions once in repository settings
- Build/sign iOS in Xcode and Android with Flutter tooling
