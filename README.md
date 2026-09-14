# ConsistiFit Investor Prototype

This clickable browser prototype now demonstrates the core ConsistiFit training engine as well as the rank/reward loop.

## Investor demo flow
1. Open `index.html`.
2. Complete the 5-step onboarding:
   - Goal
   - Experience
   - Equipment
   - Training days
   - Session length
3. Generate the 8-week plan.
4. Review the weekly schedule, including recovery/rest days.
5. Start the program.
6. On Home, open **Your Program** to view the full training block.
7. Start and complete today's workout.
8. Collect RP, XP, and Coins.
9. Open Missions, Rank, Progress, Profile, and Shop.

## Prototype concepts shown
- Goal-based program selection
- Experience-based scheduling
- Equipment substitutions
- 2–4+ day schedule logic
- Training, recovery, and rest days
- 8-week training blocks
- Double-progression concept
- Missed-workout reflow rules
- Ranked consistency progression
- XP and Coin rewards
- Workout logging
- Progress analytics

All data is simulated. This prototype does not yet connect to a backend or health platform.

## UI rework
The investor prototype now uses a cleaner workout-app visual system:
- Fitness photography on Home, Missions, Rank, Progress, and Profile
- Reduced card/gradient clutter
- Clear workout-first hierarchy
- Reserved ad placements that stay outside active workouts
- Cleaner missions list and consistency meter
- Dedicated rank ladder presentation
- Fitness-oriented progress screen
- Profile layout designed around training history, rank, and achievements

## Interaction audit
All visible static buttons have a working demo action. Dynamic panels also use actionable controls for navigation, settings, schedule changes, exercise replacement, history, records, inventory, purchases, and report actions.

## Prototype photo licensing

The current prototype uses selected Pexels workout photographs. Pexels states that its photos can be used for free for personal and commercial projects under the Pexels License. Attribution is not required, but source information is retained here for recordkeeping.

These are stock photos used as generic fitness imagery. They must not be presented as testimonials or as endorsements of ConsistiFit by the people shown.

### Photo sources
- Marius Aholou / Pexels: https://www.pexels.com/photo/a-man-using-dumbbells-11432959/
- Tima Miroshnichenko / Pexels: https://www.pexels.com/photo/a-man-stretching-at-the-gym-6389890/
- Alexander Savchuk / Pexels: https://www.pexels.com/photo/man-in-white-crew-neck-shirt-running-on-asphalt-road-9616175/
- Marius Aholou / Pexels: https://www.pexels.com/photo/a-muscular-man-working-out-11433059/
- Alef Morais / Pexels: https://www.pexels.com/photo/focused-athlete-portrait-in-a-gym-setting-36085104/

Pexels license: https://www.pexels.com/license/

The prototype loads these images from Pexels over the internet. The app therefore needs an internet connection for the photos to appear in this demo build.

## Workout session flow
The prototype now includes a functional workout experience:
- Active exercise selection
- Set logging
- Automatic 90-second rest timer
- Rest-time adjustment and skip controls
- Exercise form guide and history
- Exercise substitutions
- Post-workout difficulty check-in
- Adaptive-training preview based on feedback
- Workout summary sharing
- Rank Points, XP, and Coin rewards after completion
