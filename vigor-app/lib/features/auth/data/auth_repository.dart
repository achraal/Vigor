import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    XFile? avatarFile, // Utilisation de XFile au lieu de File
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'phone': phone},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Erreur critique lors de la création de l\'utilisateur.');
    }

    if (avatarFile != null) {
      try {
        // Lecture en octets (Compatible Web, iOS, Android)
        final Uint8List imageBytes = await avatarFile.readAsBytes();

        // Extraction sécurisée de l'extension
        String fileExt = 'png'; // Fallback par défaut
        if (avatarFile.name.contains('.')) {
          fileExt = avatarFile.name.split('.').last.toLowerCase();
          if (fileExt.contains('?')) fileExt = fileExt.split('?').first; // Sécurité Web
        }

        // Validation du type MIME pour éviter l'erreur "Invalid media type"
        if (fileExt != 'png' && fileExt != 'jpg' && fileExt != 'jpeg') {
          fileExt = 'png';
        }

        final filePath = '${user.id}/avatar.$fileExt';

        // Utilisation de uploadBinary (Obligatoire pour le Web)
        await _supabase.storage.from('avatars').uploadBinary(
          filePath,
          imageBytes,
          fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
        );

        final avatarUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

        await _supabase.from('profiles').update({'avatar_url': avatarUrl}).eq('id', user.id);
      } catch (e) {
        // Gestion d'erreur non bloquante : le compte est créé, mais on avertit pour la photo
        throw Exception("Compte créé avec succès, mais l'upload de la photo a échoué : $e");
      }
    }

    return response;
  }
}