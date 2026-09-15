import '../models/models.dart';

enum ExerciseMotion {
  squat,
  hinge,
  bridge,
  press,
  verticalPress,
  row,
  verticalPull,
  raise,
  curl,
  triceps,
  kneeExtension,
  kneeFlexion,
  calf,
  abduction,
  core,
  plank,
  cardio,
  general,
}

class ExerciseGuide {
  const ExerciseGuide({
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.motion,
    required this.overview,
    required this.steps,
    required this.mistakes,
    required this.cues,
    required this.demoPhases,
    required this.substitution,
    required this.safetyNote,
  });

  final String name;
  final String muscleGroup;
  final String equipment;
  final ExerciseMotion motion;
  final String overview;
  final List<String> steps;
  final List<String> mistakes;
  final List<String> cues;
  final List<DemoPhase> demoPhases;
  final String substitution;
  final String safetyNote;
}

class DemoPhase {
  const DemoPhase(this.title, this.instruction);
  final String title;
  final String instruction;
}

class ExerciseLibrary {
  const ExerciseLibrary();

  ExerciseGuide forExercise(ExercisePrescription exercise) {
    final name = exercise.name;
    final lower = name.toLowerCase();
    final template = _template(lower);
    return ExerciseGuide(
      name: name,
      muscleGroup: exercise.muscleGroup,
      equipment: _equipment(lower),
      motion: template.motion,
      overview: template.overview,
      steps: template.steps,
      mistakes: template.mistakes,
      cues: template.cues,
      demoPhases: template.demoPhases,
      substitution: template.substitution,
      safetyNote:
          'Use a load and range you can control. Stop the set if you feel sharp pain, numbness, or a loss of normal movement control.',
    );
  }

  _GuideTemplate _template(String name) {
    if (name.contains('leg extension')) return _legExtension;
    if (name.contains('leg curl')) return _legCurl;
    if (name.contains('calf raise')) return _calf;
    if (name.contains('hip abduction')) return _hipAbduction;
    if (_hasAny(name, const ['deadlift', 'romanian', 'good morning', 'hinge'])) {
      return _hinge;
    }
    if (_hasAny(name, const ['hip thrust', 'glute bridge'])) return _bridge;
    if (_hasAny(name, const ['lat pulldown', 'pull-up', 'pullover', 'lat sweep'])) {
      return _verticalPull;
    }
    if (_hasAny(name, const ['row', 'reverse snow angel'])) return _row;
    if (_hasAny(name, const ['shoulder press', 'overhead press', 'arnold press', 'pike push-up'])) {
      return _verticalPress;
    }
    if (_hasAny(name, const ['bench press', 'chest press', 'floor press', 'push-up', 'pec deck', 'chest fly'])) {
      return _horizontalPress;
    }
    if (_hasAny(name, const ['lateral raise', 'rear delt', 'reverse pec deck'])) {
      return _shoulderIsolation;
    }
    if (name.contains('curl')) return _biceps;
    if (_hasAny(name, const ['triceps', 'pressdown'])) return _triceps;
    if (name.contains('dead bug')) return _deadBug;
    if (name.contains('plank')) return _plank;
    if (_hasAny(name, const ['crunch', 'leg raise'])) return _coreFlexion;
    if (_hasAny(name, const ['walk', 'run', 'bike', 'cardio', 'interval'])) return _cardio;
    if (_hasAny(name, const ['squat', 'leg press', 'step-up', 'lunge'])) return _squat;
    return _general;
  }

  bool _hasAny(String value, List<String> terms) => terms.any(value.contains);

  String _equipment(String name) {
    if (name.contains('dumbbell')) return 'Dumbbell';
    if (name.contains('barbell')) return 'Barbell';
    if (name.contains('kettlebell')) return 'Kettlebell';
    if (name.contains('band')) return 'Resistance band';
    if (name.contains('cable')) return 'Cable station';
    if (name.contains('machine') || name.contains('leg press') || name.contains('pec deck')) {
      return 'Machine';
    }
    if (name.contains('bench')) return 'Bench';
    if (name.contains('pull-up')) return 'Pull-up bar';
    return 'Bodyweight / selected equipment';
  }

  static const _GuideTemplate _legExtension = _GuideTemplate(
    motion: ExerciseMotion.kneeExtension,
    overview:
        'A quad-focused knee-extension movement. Set the machine so your knee lines up with the pivot, keep your hips down, and extend without kicking or slamming the stack.',
    steps: <String>[
      'Adjust the seat and pad so the knees line up with the machine pivot and the lower pad rests just above the ankles.',
      'Sit tall with the back against the pad and hold the handles.',
      'Brace the core and smoothly straighten the knees until the legs are nearly straight.',
      'Pause briefly while squeezing the quads.',
      'Lower the weight under control to the starting position.',
    ],
    mistakes: <String>[
      'Using momentum to kick the weight up.',
      'Letting the hips lift off the seat.',
      'Dropping the weight stack between reps.',
    ],
    cues: <String>['Smooth up, slower down', 'Keep the hips heavy', 'Squeeze the quads'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Knees bent and aligned with the pivot.'),
      DemoPhase('Extend', 'Straighten the knees under control.'),
      DemoPhase('Return', 'Lower slowly without letting the stack slam.'),
    ],
    substitution: 'Dumbbell split squat, reverse lunge, or bodyweight squat.',
  );

  static const _GuideTemplate _legCurl = _GuideTemplate(
    motion: ExerciseMotion.kneeFlexion,
    overview:
        'A hamstring-focused knee-flexion movement. Keep your hips and torso stable while curling the pad toward you with the hamstrings.',
    steps: <String>[
      'Adjust the machine so the knees line up with the pivot and the pad sits just above the heels or ankles.',
      'Brace the trunk and keep the hips pressed into the pad or seat.',
      'Curl the pad through a comfortable range by bending the knees.',
      'Pause briefly when the hamstrings are fully shortened.',
      'Return slowly until the knees are nearly straight.',
    ],
    mistakes: <String>[
      'Lifting the hips to move more weight.',
      'Jerking the first part of the rep.',
      'Letting the return phase drop too quickly.',
    ],
    cues: <String>['Keep the hips pinned', 'Curl with the hamstrings', 'Control the return'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Knees almost straight and hips stable.'),
      DemoPhase('Curl', 'Bend the knees and pull the pad in.'),
      DemoPhase('Return', 'Lengthen the hamstrings under control.'),
    ],
    substitution: 'Romanian deadlift, band leg curl, or single-leg glute bridge.',
  );

  static const _GuideTemplate _calf = _GuideTemplate(
    motion: ExerciseMotion.calf,
    overview:
        'A calf-strengthening movement. Move through the ankle instead of bouncing through the knees and use a full controlled range.',
    steps: <String>[
      'Set the feet so the balls of the feet are supported and the heels can move freely.',
      'Keep the knees softly locked or slightly bent for the chosen variation.',
      'Lower the heels until you feel a comfortable calf stretch.',
      'Drive through the balls of the feet and rise as high as you can without rolling the ankles outward.',
      'Pause at the top, then lower slowly.',
    ],
    mistakes: <String>['Bouncing through the bottom.', 'Rolling the ankles outward.', 'Using a very short range.'],
    cues: <String>['Stretch low', 'Rise tall', 'Pause at the top'],
    demoPhases: <DemoPhase>[
      DemoPhase('Stretch', 'Heels lowered under control.'),
      DemoPhase('Rise', 'Press through the balls of the feet.'),
      DemoPhase('Squeeze', 'Finish tall, then lower slowly.'),
    ],
    substitution: 'Standing bodyweight calf raise or dumbbell calf raise.',
  );

  static const _GuideTemplate _hipAbduction = _GuideTemplate(
    motion: ExerciseMotion.abduction,
    overview:
        'A glute-focused hip-abduction movement. Keep the pelvis stable while moving the thighs outward without bouncing.',
    steps: <String>[
      'Adjust the seat and thigh pads so you can sit tall with the feet supported.',
      'Brace the core and keep the pelvis still against the seat.',
      'Press the knees outward against the pads.',
      'Pause briefly in the open position.',
      'Return slowly until the stack is just above resting.',
    ],
    mistakes: <String>['Rocking the torso for momentum.', 'Letting the stack slam shut.', 'Forcing the pelvis to rotate.'],
    cues: <String>['Stay tall', 'Open from the hips', 'Control the return'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Knees comfortably inside the pads.'),
      DemoPhase('Open', 'Drive the thighs outward.'),
      DemoPhase('Return', 'Bring the knees back in slowly.'),
    ],
    substitution: 'Band lateral walk or side-lying hip abduction.',
  );

  static const _GuideTemplate _squat = _GuideTemplate(
    motion: ExerciseMotion.squat,
    overview:
        'A lower-body knee-and-hip pattern for the quads and glutes. Keep the whole foot planted, brace the trunk, and let the knees track with the toes.',
    steps: <String>[
      'Set a balanced stance with pressure through the heel, big toe, and little toe.',
      'Brace the core and keep the ribs stacked over the pelvis.',
      'Bend at the knees and hips together while the knees track over the toes.',
      'Lower through a comfortable range without losing foot pressure or trunk control.',
      'Drive the floor away and finish tall without snapping the knees backward.',
    ],
    mistakes: <String>[
      'Knees collapsing inward.',
      'Heels lifting or feet rolling.',
      'Rounding or overextending the lower back.',
      'Rushing the bottom position.',
    ],
    cues: <String>['Whole foot down', 'Knees follow toes', 'Brace before moving', 'Drive the floor away'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Balanced stance with the trunk braced.'),
      DemoPhase('Lower', 'Bend the knees and hips while staying controlled.'),
      DemoPhase('Stand', 'Drive through the whole foot to return tall.'),
    ],
    substitution: 'Goblet squat, reverse lunge, split squat, or leg press depending on equipment.',
  );

  static const _GuideTemplate _hinge = _GuideTemplate(
    motion: ExerciseMotion.hinge,
    overview:
        'A hip-hinge pattern for the hamstrings and glutes. The hips travel backward while the spine stays controlled and the load stays close.',
    steps: <String>[
      'Stand tall with the weight close to the thighs and soften the knees.',
      'Brace the trunk, then push the hips backward.',
      'Keep the load close and continue until you feel a strong hamstring stretch without rounding the back.',
      'Drive the hips forward by squeezing the glutes.',
      'Finish tall with the ribs stacked instead of leaning backward.',
    ],
    mistakes: <String>[
      'Turning the movement into a squat.',
      'Letting the load drift away from the body.',
      'Rounding the lower back.',
      'Leaning backward at lockout.',
    ],
    cues: <String>['Hips back', 'Keep the load close', 'Long spine', 'Squeeze the glutes'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Soft knees, load close, trunk braced.'),
      DemoPhase('Hinge', 'Push the hips back while keeping the spine controlled.'),
      DemoPhase('Stand', 'Drive the hips forward and finish tall.'),
    ],
    substitution: 'Dumbbell RDL, kettlebell RDL, band good morning, or glute bridge.',
  );

  static const _GuideTemplate _bridge = _GuideTemplate(
    motion: ExerciseMotion.bridge,
    overview:
        'A hip-extension movement for the glutes. Keep the ribs down, drive through the feet, and finish with the hips instead of arching the lower back.',
    steps: <String>[
      'Set the upper back on a bench for a hip thrust, or lie on the floor for a glute bridge.',
      'Place the feet so the shins are close to vertical at the top.',
      'Brace the core and gently tuck the pelvis.',
      'Drive through the feet and squeeze the glutes to raise the hips.',
      'Pause at the top, then lower under control.',
    ],
    mistakes: <String>['Hyperextending the lower back.', 'Feet too far away or too close.', 'Pushing mainly through the toes.'],
    cues: <String>['Ribs down', 'Drive through the heels', 'Squeeze the glutes'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Feet planted and ribs stacked.'),
      DemoPhase('Drive', 'Raise the hips by squeezing the glutes.'),
      DemoPhase('Lower', 'Return under control while keeping tension.'),
    ],
    substitution: 'Glute bridge, dumbbell hip thrust, or banded hip thrust.',
  );

  static const _GuideTemplate _horizontalPress = _GuideTemplate(
    motion: ExerciseMotion.press,
    overview:
        'A chest-focused pressing pattern. Keep the shoulder blades controlled, wrists stacked, and press without shrugging the shoulders.',
    steps: <String>[
      'Set the chest open, upper back stable, and feet supported.',
      'Position the hands so the wrists stay stacked over the forearms.',
      'Lower the resistance with control until you reach a comfortable chest stretch.',
      'Press away while keeping the shoulders down and the elbows in a strong path.',
      'Finish without forcefully locking or shrugging.',
    ],
    mistakes: <String>['Shoulders rolling forward.', 'Elbows flaring excessively.', 'Bouncing through the bottom.', 'Wrists bending backward.'],
    cues: <String>['Chest tall', 'Wrists stacked', 'Shoulders down', 'Press smoothly'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Upper back stable and hands aligned.'),
      DemoPhase('Lower', 'Bring the resistance toward the chest under control.'),
      DemoPhase('Press', 'Drive away and finish without shrugging.'),
    ],
    substitution: 'Push-up, dumbbell floor press, machine chest press, or band chest press.',
  );

  static const _GuideTemplate _verticalPress = _GuideTemplate(
    motion: ExerciseMotion.verticalPress,
    overview:
        'An overhead pressing pattern for the shoulders and triceps. Keep the ribs controlled and move the load overhead without turning the press into a backbend.',
    steps: <String>[
      'Set the hands just outside shoulder width or in the machine handles.',
      'Brace the core and keep the ribs stacked over the pelvis.',
      'Press upward while keeping the forearms close to vertical.',
      'Finish overhead without aggressively shrugging or arching the lower back.',
      'Lower back to shoulder level under control.',
    ],
    mistakes: <String>['Overarching the lower back.', 'Pressing around the face instead of moving naturally.', 'Letting the wrists collapse backward.'],
    cues: <String>['Ribs down', 'Forearms vertical', 'Press up, not back', 'Control the lowering phase'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Load at shoulder level and core braced.'),
      DemoPhase('Press', 'Move the resistance overhead.'),
      DemoPhase('Return', 'Lower back to shoulder level slowly.'),
    ],
    substitution: 'Dumbbell shoulder press, machine shoulder press, band press, or pike push-up.',
  );

  static const _GuideTemplate _row = _GuideTemplate(
    motion: ExerciseMotion.row,
    overview:
        'A horizontal pulling pattern for the back and biceps. Keep the torso stable and pull by driving the elbows instead of yanking with the hands.',
    steps: <String>[
      'Set the chest and torso in a stable position before the first rep.',
      'Reach forward enough to lengthen the back without losing spinal control.',
      'Pull toward the lower ribs by driving the elbows backward.',
      'Pause briefly with the shoulder blades pulled back without shrugging.',
      'Return slowly until the arms are long again.',
    ],
    mistakes: <String>['Jerking the torso backward.', 'Shrugging the shoulders.', 'Pulling too high toward the neck.', 'Dropping the load on the return.'],
    cues: <String>['Lead with the elbows', 'Chest stable', 'Shoulders away from ears', 'Reach, then row'],
    demoPhases: <DemoPhase>[
      DemoPhase('Reach', 'Arms long and torso stable.'),
      DemoPhase('Pull', 'Drive the elbows toward the ribs.'),
      DemoPhase('Return', 'Reach forward under control.'),
    ],
    substitution: 'Dumbbell row, cable row, machine row, barbell row, or band row.',
  );

  static const _GuideTemplate _verticalPull = _GuideTemplate(
    motion: ExerciseMotion.verticalPull,
    overview:
        'A vertical pulling pattern for the lats and upper back. Keep the ribs controlled and pull the elbows down without swinging the torso.',
    steps: <String>[
      'Take a secure grip and set the shoulders down away from the ears.',
      'Brace the core with the chest tall but not excessively arched.',
      'Pull by driving the elbows down toward the sides of the torso.',
      'Pause briefly when the lats are shortened.',
      'Return to the top under control and allow a comfortable stretch.',
    ],
    mistakes: <String>['Swinging the torso.', 'Pulling behind the neck.', 'Shrugging at the bottom.', 'Letting the load yank the shoulders upward.'],
    cues: <String>['Elbows to your pockets', 'Ribs down', 'Long reach at the top', 'No swinging'],
    demoPhases: <DemoPhase>[
      DemoPhase('Reach', 'Arms long with shoulders controlled.'),
      DemoPhase('Pull', 'Drive the elbows down.'),
      DemoPhase('Return', 'Lengthen the lats under control.'),
    ],
    substitution: 'Lat pulldown, assisted pull-up, band pulldown, or dumbbell pullover.',
  );

  static const _GuideTemplate _shoulderIsolation = _GuideTemplate(
    motion: ExerciseMotion.raise,
    overview:
        'A shoulder-isolation movement. Use a light enough load to keep the torso quiet and move from the shoulder instead of swinging.',
    steps: <String>[
      'Stand or sit tall with a soft bend in the elbows.',
      'Brace the torso before moving.',
      'Raise the arms through the intended path until the target shoulder muscles are working hard.',
      'Pause briefly without shrugging.',
      'Lower slowly and keep tension through the bottom.',
    ],
    mistakes: <String>['Swinging the torso.', 'Shrugging the shoulders.', 'Using a load that forces a short uncontrolled range.'],
    cues: <String>['Lead with the elbows', 'Stay tall', 'Shoulders away from ears', 'Slow on the way down'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Arms relaxed and torso still.'),
      DemoPhase('Raise', 'Lift from the shoulder without swinging.'),
      DemoPhase('Lower', 'Return slowly while keeping control.'),
    ],
    substitution: 'Dumbbell lateral raise, cable raise, band raise, or reverse fly.',
  );

  static const _GuideTemplate _biceps = _GuideTemplate(
    motion: ExerciseMotion.curl,
    overview:
        'A biceps elbow-flexion movement. Keep the upper arm quiet and bend the elbow without using the torso to swing the load.',
    steps: <String>[
      'Stand or sit tall with the upper arms close to the torso.',
      'Brace the core and start with the elbows nearly straight.',
      'Curl by bending the elbows while keeping the upper arms mostly still.',
      'Squeeze briefly near the top.',
      'Lower slowly until the elbows are almost straight again.',
    ],
    mistakes: <String>['Swinging the torso.', 'Letting the elbows travel far forward.', 'Dropping the weight quickly.'],
    cues: <String>['Pin the upper arms', 'Curl, do not swing', 'Slow on the way down'],
    demoPhases: <DemoPhase>[
      DemoPhase('Start', 'Arms long and torso still.'),
      DemoPhase('Curl', 'Bend the elbows and squeeze.'),
      DemoPhase('Return', 'Lower under control.'),
    ],
    substitution: 'Dumbbell curl, cable curl, barbell curl, or band curl.',
  );

  static const _GuideTemplate _triceps = _GuideTemplate(
    motion: ExerciseMotion.triceps,
    overview:
        'A triceps elbow-extension movement. Keep the upper arm stable while straightening the elbow through a controlled range.',
    steps: <String>[
      'Set the shoulders down and keep the upper arms stable.',
      'Brace the core before the first rep.',
      'Straighten the elbows until the triceps are fully contracted without forcing the joint.',
      'Pause briefly at the end of the rep.',
      'Return slowly while keeping the upper arms from drifting.',
    ],
    mistakes: <String>['Moving the shoulder instead of the elbow.', 'Using bodyweight to force the load.', 'Snapping into lockout.'],
    cues: <String>['Upper arms still', 'Straighten the elbows', 'Control the return'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Elbows bent and upper arms stable.'),
      DemoPhase('Extend', 'Straighten the elbows.'),
      DemoPhase('Return', 'Bend the elbows slowly.'),
    ],
    substitution: 'Cable pressdown, overhead dumbbell extension, band pressdown, or close-grip push-up.',
  );

  static const _GuideTemplate _plank = _GuideTemplate(
    motion: ExerciseMotion.plank,
    overview:
        'An anti-extension core hold. Keep the body in one strong line while breathing normally and preventing the lower back from sagging.',
    steps: <String>[
      'Set the elbows or hands under the shoulders.',
      'Straighten the legs and create a long line from head to heels.',
      'Brace the abs and gently squeeze the glutes.',
      'Keep the ribs down while breathing behind the brace.',
      'End the set when you can no longer hold the same body position.',
    ],
    mistakes: <String>['Hips sagging.', 'Hips excessively high.', 'Holding the breath.', 'Shrugging into the shoulders.'],
    cues: <String>['Ribs down', 'Squeeze the glutes', 'Push the floor away', 'Stay long'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Shoulders stacked and legs long.'),
      DemoPhase('Brace', 'Tighten the abs and glutes while breathing.'),
      DemoPhase('Hold', 'Maintain the same line until the set ends.'),
    ],
    substitution: 'Dead bug, elevated plank, or side plank.',
  );

  static const _GuideTemplate _deadBug = _GuideTemplate(
    motion: ExerciseMotion.core,
    overview:
        'A controlled core drill that teaches you to move the arms and legs while keeping the lower back and ribs stable.',
    steps: <String>[
      'Lie on the back with hips and knees bent to about 90 degrees and arms pointed upward.',
      'Gently press the lower back toward the floor and brace the abs.',
      'Slowly extend the opposite arm and leg without letting the ribs flare or back arch.',
      'Return to the start and switch sides.',
      'Move only as far as you can while keeping the trunk position unchanged.',
    ],
    mistakes: <String>['Arching the lower back.', 'Moving too fast.', 'Extending farther than you can control.'],
    cues: <String>['Back stays heavy', 'Move slowly', 'Exhale as you extend'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Arms up with hips and knees bent.'),
      DemoPhase('Extend', 'Reach the opposite arm and leg away.'),
      DemoPhase('Return', 'Come back to center and switch sides.'),
    ],
    substitution: 'Plank, heel tap, or bird dog.',
  );

  static const _GuideTemplate _coreFlexion = _GuideTemplate(
    motion: ExerciseMotion.core,
    overview:
        'A core movement that should be controlled through the trunk instead of created by swinging the legs or pulling on the neck.',
    steps: <String>[
      'Set the pelvis and ribs in a controlled starting position.',
      'Brace the abs before moving.',
      'Move through the intended range using the abdominal muscles instead of momentum.',
      'Pause briefly at the hardest point.',
      'Return slowly without losing trunk control.',
    ],
    mistakes: <String>['Swinging through the rep.', 'Pulling on the neck.', 'Letting the lower back arch excessively.'],
    cues: <String>['Move from the abs', 'Stay controlled', 'Exhale through the hard part'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Brace the trunk before moving.'),
      DemoPhase('Contract', 'Shorten the abs through a controlled range.'),
      DemoPhase('Return', 'Lengthen slowly without losing position.'),
    ],
    substitution: 'Dead bug, plank, or cable crunch.',
  );

  static const _GuideTemplate _cardio = _GuideTemplate(
    motion: ExerciseMotion.cardio,
    overview:
        'A conditioning movement. Start easy, build intensity gradually, and keep a pace you can control with relaxed posture.',
    steps: <String>[
      'Begin with an easy warm-up for several minutes.',
      'Set a pace that matches the planned effort.',
      'Keep the posture relaxed and the breathing rhythmic.',
      'For intervals, increase effort only during the work segment and recover enough to repeat with control.',
      'Finish with an easier cooldown before stopping.',
    ],
    mistakes: <String>['Starting too hard.', 'Skipping the warm-up.', 'Using an intensity that ruins later intervals.', 'Stopping abruptly after hard work.'],
    cues: <String>['Build gradually', 'Relax the shoulders', 'Control the breathing', 'Save enough for the final round'],
    demoPhases: <DemoPhase>[
      DemoPhase('Warm up', 'Begin at an easy pace.'),
      DemoPhase('Work', 'Use the planned training pace.'),
      DemoPhase('Cool down', 'Gradually reduce intensity.'),
    ],
    substitution: 'Walking, stationary bike, elliptical, rower, or another low-impact cardio option.',
  );

  static const _GuideTemplate _general = _GuideTemplate(
    motion: ExerciseMotion.general,
    overview:
        'A controlled resistance-training movement. Use a load you can move through a comfortable range while keeping the joints and trunk stable.',
    steps: <String>[
      'Set up the equipment and body position before the first repetition.',
      'Brace the trunk and establish a stable starting position.',
      'Move through the intended range smoothly without using momentum.',
      'Pause briefly in the strongest controlled position.',
      'Return to the start slowly and repeat with the same technique.',
    ],
    mistakes: <String>['Using momentum instead of control.', 'Changing body position as fatigue increases.', 'Rushing the lowering phase.'],
    cues: <String>['Stay controlled', 'Use a repeatable range', 'Keep the trunk stable'],
    demoPhases: <DemoPhase>[
      DemoPhase('Set up', 'Create a stable starting position.'),
      DemoPhase('Move', 'Perform the working portion under control.'),
      DemoPhase('Return', 'Come back to the start slowly.'),
    ],
    substitution: 'Choose another movement for the same muscle group that matches your equipment.',
  );
}

class _GuideTemplate {
  const _GuideTemplate({
    required this.motion,
    required this.overview,
    required this.steps,
    required this.mistakes,
    required this.cues,
    required this.demoPhases,
    required this.substitution,
  });

  final ExerciseMotion motion;
  final String overview;
  final List<String> steps;
  final List<String> mistakes;
  final List<String> cues;
  final List<DemoPhase> demoPhases;
  final String substitution;
}
