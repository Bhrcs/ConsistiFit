# Exercise Guides

Every exercise surfaced by ConsistiFit's generated programs can open a form guide from the active workout screen.

Each guide includes:

- target muscles and equipment
- a plain-language overview
- a three-phase motion demonstration
- numbered setup and execution steps
- coaching cues
- common mistakes
- a compatible substitution
- a short safety note

## Web demo

The playable PWA adds a `How to perform + demo` button for the active exercise and a dedicated arrow beside every exercise in the workout order. The guide opens in the existing in-workout sheet so a user can inspect form without losing session state.

The web motion preview is an original lightweight CSS figure sequence. It is intentionally not a copied or AI-generated exercise image and works offline after the PWA is cached.

## Flutter app

The Flutter workout screen exposes the same guide action. Its bottom sheet cycles automatically through the three motion phases and lets the user tap a phase indicator manually.

`ExerciseLibrary` maps exercise names to movement families so Home, Gym Machines, Custom Equipment, Habit, Strength, and Cardio plans all receive appropriate instruction data. Unknown future exercises receive a safe general guide instead of a broken view.

The demonstration is a technique aid, not medical advice. Users are instructed to use a controllable load and range and to stop a set for sharp pain, numbness, or loss of normal movement control.
