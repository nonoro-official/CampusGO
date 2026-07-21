import 'package:campusgo/providers/theme_provider.dart';
import 'package:campusgo/themes/theme.dart';
import 'package:campusgo/widgets/dark_theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeThemePreferences implements ThemePreferences {
  FakeThemePreferences({this.isDarkMode = false});

  bool isDarkMode;

  @override
  Future<bool> loadDarkMode() async => isDarkMode;

  @override
  Future<void> saveDarkMode(bool enabled) async {
    isDarkMode = enabled;
  }
}

class ThemeTestApp extends ConsumerWidget {
  const ThemeTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;
    final darkColors = AppTheme.darkColorScheme;

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.lightSurfaceColor,
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: darkColors,
        primaryColor: AppTheme.darkPrimaryColor,
        scaffoldBackgroundColor: AppTheme.darkSurfaceColor,
        cardColor: darkColors.surfaceContainerLow,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              const DarkThemeSwitch(),
              Container(
                key: const Key('themed-card'),
                color: Theme.of(context).cardColor,
                child: const Text('Theme preview'),
              ),
              const TextField(key: Key('themed-field')),
              ElevatedButton(onPressed: () {}, child: const Text('Action')),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  test('light theme preserves the existing CampusGO scheme', () {
    expect(AppTheme.primaryColor, const Color(0xFF00364D));
    expect(AppTheme.primarySwatch[500], const Color(0xFF00364D));
    expect(AppTheme.accentColor, const Color(0xFFFF28B1));
    expect(AppTheme.lightSurfaceColor, Colors.white);
  });

  test('dark theme uses neutral surfaces and accessible brand colors', () {
    final colors = AppTheme.darkColorScheme;

    expect(colors.brightness, Brightness.dark);
    expect(colors.primary, AppTheme.darkPrimaryColor);
    expect(colors.primaryContainer, AppTheme.primaryColor);
    expect(colors.secondary, AppTheme.accentColor);
    expect(colors.surface, const Color(0xFF121212));
    expect(colors.surfaceContainerLow, const Color(0xFF181818));
    expect(colors.surfaceContainerHigh, const Color(0xFF252525));
    expect(colors.surfaceTint, Colors.transparent);
    expect(colors.outlineVariant, const Color(0xFF3A3A3A));
  });

  test('shared preferences stores and restores dark mode', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = SharedPreferencesThemePreferences();

    expect(await preferences.loadDarkMode(), isFalse);

    await preferences.saveDarkMode(true);

    expect(await preferences.loadDarkMode(), isTrue);
  });

  testWidgets('theme switch changes rendering and persists the selection', (
    tester,
  ) async {
    final preferences = FakeThemePreferences();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferencesProvider.overrideWithValue(preferences),
        ],
        child: const ThemeTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const Key('dark-theme-switch'));
    expect(switchFinder, findsOneWidget);

    var theme = Theme.of(tester.element(switchFinder));
    var card = tester.widget<Container>(find.byKey(const Key('themed-card')));
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(card.color, Colors.white);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    theme = Theme.of(tester.element(switchFinder));
    card = tester.widget<Container>(find.byKey(const Key('themed-card')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF121212));
    expect(theme.colorScheme.onSurface, const Color(0xFFF2F2F2));
    expect(card.color, const Color(0xFF181818));
    expect(preferences.isDarkMode, isTrue);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    expect(find.textContaining('colors are on'), findsNothing);
  });

  testWidgets('saved dark mode is restored when the provider starts', (
    tester,
  ) async {
    final preferences = FakeThemePreferences(isDarkMode: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferencesProvider.overrideWithValue(preferences),
        ],
        child: const ThemeTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const Key('dark-theme-switch'));
    expect(Theme.of(tester.element(switchFinder)).brightness, Brightness.dark);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    expect(find.textContaining('colors are on'), findsNothing);
  });
}
