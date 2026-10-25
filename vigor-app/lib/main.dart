import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart'; // <-- IMPORT i18n
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'core/providers/settings_provider.dart';
import 'features/map/application/notification_service.dart';

// Import conditionnel pour le Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> main() async {
  // Garantir l'initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser EasyLocalization (i18n)
  await EasyLocalization.ensureInitialized();

  // 2. Charger les variables d'environnement depuis le fichier .env
  await dotenv.load(fileName: ".env");

  // 3. Initialiser Supabase en utilisant les clés sécurisées
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 4. Initialiser les Notifications (Uniquement sur mobile Android/iOS)
  if (!kIsWeb) {
    await NotificationService.init();
  }

  // 5. Injection dynamique de la clé Google Maps pour la version Web (Chrome)
  if (kIsWeb) {
    final apiKey = dotenv.env['GOOGLE_MAPS_WEB_KEY'] ?? '';
    final script = html.ScriptElement()
      ..src = "https://maps.googleapis.com/maps/api/js?key=$apiKey"
      ..async = true
      ..defer = true;
    html.document.head?.append(script);
  }

  // 6. Lancer l'application encapsulée dans EasyLocalization et ProviderScope
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
        Locale('en'),
      ],
      path: 'assets/translations', // Chemin vers tes fichiers json
      fallbackLocale: const Locale('fr'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute les paramètres en temps réel
    final settings = ref.watch(settingsProvider);

    // Synchronisation de la langue EasyLocalization avec ton settingsProvider
    if (context.locale.languageCode != settings.languageCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.setLocale(Locale(settings.languageCode));
      });
    }

    return MaterialApp(
      title: 'Vigor',
      debugShowCheckedModeBanner: false,

      // -- GESTION DE LA LANGUE (i18n) --
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,

      // -- GESTION DU THÈME --
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E90FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}