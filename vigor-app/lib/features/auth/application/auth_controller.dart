import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

// Provider pour injecter le repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// Provider pour l'état de l'authentification
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncData(null));

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    XFile? avatar,
  }) async {
    state = const AsyncLoading();

    // Validations métier
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      state = AsyncError("Format d'email invalide", StackTrace.current);
      return;
    }

    if (password.length < 8) {
      state = AsyncError("Le mot de passe doit contenir au moins 8 caractères", StackTrace.current);
      return;
    }

    try {
      await _repository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        avatarFile: avatar,
      );
      state = const AsyncData(null);
    } on AuthException catch (e) {
      debugPrint('🚨 Erreur Auth Supabase : ${e.message}');
      state = AsyncError(e.message, StackTrace.current);
    } on PostgrestException catch (e) {
      // Intercepte les erreurs de la base de données (ex: le trigger ou RLS a échoué)
      debugPrint('🚨 Erreur Base de données : ${e.message} \nDétails: ${e.details}');
      state = AsyncError("Erreur BDD : ${e.message}", StackTrace.current);
    } on StorageException catch (e) {
      // Intercepte les erreurs d'upload de l'avatar
      debugPrint('🚨 Erreur Storage : ${e.message}');
      state = AsyncError("Erreur d'image : ${e.message}", StackTrace.current);
    } catch (e, st) {
      // L'erreur inattendue avec le vrai message
      debugPrint('🚨 Erreur Inattendue : $e');
      state = AsyncError("Erreur: $e", st);
    }
  }
}