import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemePreferences {
  Future<bool> loadDarkMode();

  Future<void> saveDarkMode(bool enabled);
}

class SharedPreferencesThemePreferences implements ThemePreferences {
  SharedPreferencesThemePreferences({Future<SharedPreferences>? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance();

  static const darkModeKey = 'dark_mode_enabled';

  final Future<SharedPreferences> _preferences;

  @override
  Future<bool> loadDarkMode() async {
    return (await _preferences).getBool(darkModeKey) ?? false;
  }

  @override
  Future<void> saveDarkMode(bool enabled) async {
    await (await _preferences).setBool(darkModeKey, enabled);
  }
}

final themePreferencesProvider = Provider<ThemePreferences>((ref) {
  return SharedPreferencesThemePreferences();
});

final darkModeProvider =
    AsyncNotifierProvider<DarkModeController, bool>(DarkModeController.new);

class DarkModeController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(themePreferencesProvider).loadDarkMode();
  }

  Future<void> setDarkMode(bool enabled) async {
    final previousValue = state.value ?? false;
    if (previousValue == enabled) return;

    state = AsyncData(enabled);

    try {
      await ref.read(themePreferencesProvider).saveDarkMode(enabled);
    } catch (_) {
      state = AsyncData(previousValue);
      rethrow;
    }
  }
}
