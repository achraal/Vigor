import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String languageCode;
  final bool notificationsEnabled;

  SettingsState({
    required this.themeMode,
    required this.languageCode,
    required this.notificationsEnabled,
  });

  SettingsState copyWith({ThemeMode? themeMode, String? languageCode, bool? notificationsEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(
      themeMode: ThemeMode.system,
      languageCode: 'fr',
      notificationsEnabled: true
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark');
    final lang = prefs.getString('lang') ?? 'fr';
    final notifs = prefs.getBool('notifs') ?? true;

    ThemeMode mode = ThemeMode.system;
    if (isDark != null) mode = isDark ? ThemeMode.dark : ThemeMode.light;

    state = state.copyWith(themeMode: mode, languageCode: lang, notificationsEnabled: notifs);
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) await prefs.setBool('isDark', true);
    if (mode == ThemeMode.light) await prefs.setBool('isDark', false);
    if (mode == ThemeMode.system) await prefs.remove('isDark');
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    state = state.copyWith(languageCode: lang);
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifs', value);
    state = state.copyWith(notificationsEnabled: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});