import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';

class DarkThemeSwitch extends ConsumerWidget {
  const DarkThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final enabled = darkMode.value ?? false;
    final colors = Theme.of(context).colorScheme;

    return SwitchListTile(
      key: const Key('dark-theme-switch'),
      secondary: Icon(
        enabled ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: colors.primary,
      ),
      title: const Text('Dark theme'),
      value: enabled,
      activeThumbColor: colors.primary,
      onChanged: darkMode.isLoading
          ? null
          : (value) async {
              try {
                await ref.read(darkModeProvider.notifier).setDarkMode(value);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not save the theme preference.'),
                  ),
                );
              }
            },
    );
  }
}
