import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Préférences')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('GÉNÉRAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),

          // Langue
          ListTile(
            leading: const Icon(CupertinoIcons.globe),
            title: const Text('Langue de l\'application'),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'ar', child: Text('العربية / Darija')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) ref.read(settingsProvider.notifier).setLanguage(val);
              },
            ),
          ),
          const Divider(),

          // Mode Sombre
          ListTile(
            leading: const Icon(CupertinoIcons.moon_fill),
            title: const Text('Mode Sombre'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('Système')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
              ],
              onChanged: (val) {
                if (val != null) ref.read(settingsProvider.notifier).setTheme(val);
              },
            ),
          ),
          const SizedBox(height: 24),

          const Text('NOTIFICATIONS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),

          // Notifications
          SwitchListTile(
            secondary: const Icon(CupertinoIcons.bell_fill),
            title: const Text('Rappels & Alertes'),
            subtitle: const Text('Rappels géolocalisés et objectifs'),
            activeColor: const Color(0xFF0A84FF),
            value: settings.notificationsEnabled,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleNotifications(val);
            },
          ),
        ],
      ),
    );
  }
}