import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consistifit/core/theme/app_theme.dart';
import 'package:consistifit/features/progress/weekly_recap_card.dart';
import 'package:consistifit/features/workouts/workout_screen.dart';
import 'package:consistifit/models/models.dart';
import 'package:consistifit/services/local_state_service.dart';
import 'package:consistifit/services/program_generator.dart';

class _MemoryStore implements LocalStateStore {
  final Map<String, Object> values = {};
  @override Future<String?> getString(String key) async => values[key] as String?;
  @override Future<int?> getInt(String key) async => values[key] as int?;
  @override Future<double?> getDouble(String key) async => values[key] as double?;
  @override Future<bool?> getBool(String key) async => values[key] as bool?;
  @override Future<List<String>?> getStringList(String key) async => values[key] as List<String>?;
  @override Future<void> setString(String key, String value) async { values[key] = value; }
  @override Future<void> setInt(String key, int value) async { values[key] = value; }
  @override Future<void> setBool(String key, bool value) async { values[key] = value; }
  @override Future<void> remove(String key) async { values.remove(key); }
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: child,
);

void main() {
  testWidgets('recovery route never silently starts a program workout', (tester) async {
    final local = LocalStateService(store: _MemoryStore(), clock: () => DateTime(2026, 9, 15, 10));
    await tester.pumpWidget(_app(WorkoutScreen(localState: local)));
    await tester.pumpAndSettle();
    expect(find.text('Recovery is today’s plan'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(await local.todayOverride(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('focus choice is day only unless saving is explicitly selected', (tester) async {
    final local = LocalStateService(store: _MemoryStore(), clock: () => DateTime(2026, 9, 15, 10));
    await tester.pumpWidget(_app(WorkoutScreen(localState: local)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a workout for today'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Back'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Use for today'), 240, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Use for today'));
    await tester.pumpAndSettle();
    expect(await local.todayOverride(), isNotNull);
    expect(await local.savedWorkouts(), isEmpty);
    expect(find.text('Workout preview'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('workout preview fits a narrow phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final local = LocalStateService(store: _MemoryStore(), clock: () => DateTime(2026, 9, 14, 10));
    final exercise = const ProgramGenerator().generateFocused(ProgramPreferences.homeDefault, 'Back').exercises.first;
    await local.setTodayOverride(WorkoutTemplate(name: 'Back focus', exercises: [exercise.copyWith(sets: 3)], estimatedMinutes: 20));
    await tester.pumpWidget(_app(WorkoutScreen(localState: local), scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Workout preview'), findsOneWidget);
    expect(find.text('Back focus'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completing a set shows immediate feedback', (tester) async {
    final local = LocalStateService(store: _MemoryStore(), clock: () => DateTime(2026, 9, 14, 10));
    final exercise = const ProgramGenerator().generateFocused(ProgramPreferences.homeDefault, 'Back').exercises.first;
    await local.setTodayOverride(WorkoutTemplate(name: 'Back focus', exercises: [exercise.copyWith(sets: 3)], estimatedMinutes: 20));
    await tester.pumpWidget(_app(WorkoutScreen(localState: local)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsWidgets);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('Set complete · nice work'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('weekly recap uses persisted completions and wraps with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final local = LocalStateService(store: _MemoryStore(), clock: () => DateTime(2026, 9, 15, 10));
    await local.completeDailyMission('recovery');
    final recap = await local.weeklyRecap();
    await tester.pumpWidget(_app(Scaffold(body: ListView(children: [WeeklyRecapCard(recap: recap, showSchedule: true)])), scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1 planned days completed'), findsOneWidget);
    expect(find.text('1 recovery days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial check-in reward does not announce primary completion', (tester) async {
    final local = LocalStateService(store: _MemoryStore(), clock: () => DateTime(2026, 9, 14, 10));
    final exercise = const ProgramGenerator().generateFocused(ProgramPreferences.homeDefault, 'Back').exercises.first;
    await local.setTodayOverride(WorkoutTemplate(name: 'Short back session', exercises: [exercise.copyWith(sets: 3)], estimatedMinutes: 10));
    await tester.pumpWidget(_app(WorkoutScreen(localState: local)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    expect(find.text('Workout saved'), findsOneWidget);
    expect(find.textContaining('did not reach the 3-set primary target'), findsOneWidget);
    expect(find.textContaining('The primary mission for'), findsNothing);
    final entry = (await local.workoutHistory()).first;
    expect(entry.rp, 5);
    expect(entry.primaryCompleted, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
