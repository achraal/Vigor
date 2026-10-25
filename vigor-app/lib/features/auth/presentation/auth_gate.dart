import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../../home/home_page.dart';

// Fournisseur du flux d'état d'authentification Supabase
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (data) {
        final session = data.session;
        // Si une session existe, on va vers l'accueil, sinon vers la connexion
        if (session != null) {
          return const HomePage();
        }
        return const LoginPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Erreur d\'authentification : $error')),
      ),
    );
  }
}