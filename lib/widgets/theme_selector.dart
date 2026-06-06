import 'package:flutter/material.dart';
import '../providers/app_state.dart';

Widget buildThemeSelector(BuildContext context, AppState appState) {
  final isDark = context.isDarkMode;
  final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);

  return PopupMenuButton<ThemeMode>(
    tooltip: 'Select Theme',
    icon: Icon(
      appState.themeMode == ThemeMode.system
          ? Icons.brightness_auto_rounded
          : appState.themeMode == ThemeMode.dark
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
      color: iconColor,
    ),
    onSelected: appState.setThemeMode,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: isDark ? const Color(0xFF1E293B) : Colors.white,
    itemBuilder: (context) => [
      PopupMenuItem(
        value: ThemeMode.system,
        child: Row(
          children: [
            const Icon(Icons.brightness_auto_rounded, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              'System Default',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: ThemeMode.light,
        child: Row(
          children: [
            const Icon(Icons.light_mode_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              'Light Mode',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: ThemeMode.dark,
        child: Row(
          children: [
            const Icon(Icons.dark_mode_rounded, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Dark Mode',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    ],
  );
}
