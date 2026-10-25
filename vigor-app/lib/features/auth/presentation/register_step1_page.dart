import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../application/auth_controller.dart';
import 'register_step2_page.dart'; // N'oublie pas cet import pour la navigation

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  XFile? _selectedImage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- PALETTE DE COULEURS MATERIAL 3 (Reprise de ton design) ---
  bool get _darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _bgSurface => _darkMode ? const Color(0xFF121317) : const Color(0xFFFAF9FE);
  Color get _cardBg => _darkMode ? const Color(0xFF1E1F23).withOpacity(0.85) : Colors.white;
  Color get _inputBg => _darkMode ? const Color(0xFF292A2E).withOpacity(0.60) : const Color(0xFFE3E2E7).withOpacity(0.60);
  Color get _headerButtonBg => _darkMode ? const Color(0xFF292A2E).withOpacity(0.60) : Colors.white;
  Color get _stepBadgeBg => _darkMode ? const Color(0xFF292A2E).withOpacity(0.40) : Colors.black.withOpacity(0.04);
  Color get _trustBadgeBg => _darkMode ? const Color(0xFF1A1B1F).withOpacity(0.60) : Colors.white.withOpacity(0.80);

  Color get _textPrimary => _darkMode ? const Color(0xFFE3E2E7) : const Color(0xFF1A1B1F);
  Color get _textSecondary => _darkMode ? const Color(0xFFC0C6D6) : const Color(0xFF414755);
  Color get _outline => _darkMode ? const Color(0xFF8B91A0) : const Color(0xFF717786);

  Color get _primary => _darkMode ? const Color(0xFF3E90FF) : const Color(0xFF0A84FF);
  Color get _secondary => _darkMode ? const Color(0xFF3630BF) : const Color(0xFF5E5CE6);
  Color get _error => _darkMode ? const Color(0xFFFFB4AB) : const Color(0xFFFF3B30);
  Color get _tertiary => _darkMode ? const Color(0xFF47E266) : const Color(0xFF34C759);

  int get _passwordStrength {
    final pwd = _passwordController.text;
    if (pwd.isEmpty) return 0;
    if (pwd.length < 6) return 1;
    if (pwd.length < 8) return 2;
    if (pwd.length < 12) return 3;
    return 4;
  }

  String get _passwordFeedbackText {
    switch (_passwordStrength) {
      case 1: return 'Trop court';
      case 2: return 'Moyen';
      case 3: return 'Bon';
      case 4: return 'Sécurité forte';
      default: return '';
    }
  }

  void _showToast(String message, {bool isError = false, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _darkMode ? const Color(0xFF0D0E12) : Colors.white,
        elevation: 8,
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isError ? _error : _tertiary).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline),
                color: isError ? _error : _tertiary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImage = pickedFile);
  }

  // --- LOGIQUE RIVERPOD POUR L'INSCRIPTION ---
  Future<void> _executeSignUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showToast('Veuillez remplir les champs obligatoires', isError: true);
      return;
    }

    //final avatarFile = _selectedImage != null ? File(_selectedImage!.path) : null;

    // Appel au contrôleur Riverpod
    await ref.read(authControllerProvider.notifier).register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      avatar: _selectedImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Écoute des résultats de l'inscription (succès / erreur)
    ref.listen<AsyncValue<void>>(
      authControllerProvider,
          (previous, next) {
        next.whenOrNull(
          error: (error, _) => _showToast(error.toString(), isError: true),
          data: (_) {
            _showToast('Inscription réussie !');
            // Navigation vers la page de profil santé
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RegisterStep2Page()),
            );
          },
        );
      },
    );

    // Observer l'état de chargement
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: _bgSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. BARRE DE NAVIGATION SUPÉRIEURE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _headerButtonBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(_darkMode ? 0.08 : 0.0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(_darkMode ? 0.4 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(CupertinoIcons.chevron_left, size: 20, color: _textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _stepBadgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(_darkMode ? 0.05 : 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _primary, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('ÉTAPE 1 SUR 2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _outline, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. EN-TÊTE
              Text('Créer un compte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Rejoignez-nous en quelques secondes', style: TextStyle(fontSize: 15, color: _textSecondary)),
              const SizedBox(height: 24),

              // 3. SÉLECTEUR D'AVATAR
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _darkMode ? const [Color(0xFF3E90FF), Color(0xFF3630BF), Color(0xFF343539)] : [_primary.withOpacity(0.8), _secondary.withOpacity(0.8)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(_darkMode ? 0.4 : 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, color: _darkMode ? const Color(0xFF1E1F23) : Colors.white),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: _selectedImage != null
                                    ? (kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover))
                                    : Container(color: _darkMode ? const Color(0xFF1E1F23) : _bgSurface, child: Icon(CupertinoIcons.person_fill, size: 44, color: _outline)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: _primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]),
                              child: Icon(CupertinoIcons.camera_fill, color: _darkMode ? const Color(0xFF002957) : Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Ajouter une photo (optionnel)', style: TextStyle(fontSize: 12, color: _textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. CARTE DU FORMULAIRE
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(_darkMode ? 0.05 : 0.0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(_darkMode ? 0.5 : 0.04), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Nom complet'),
                    _buildInputField(controller: _nameController, hintText: 'Alexandre Laurent', icon: CupertinoIcons.person_badge_plus),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Téléphone'),
                    _buildInputField(controller: _phoneController, hintText: '06 12 34 56 78', icon: CupertinoIcons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Adresse email'),
                    _buildInputField(controller: _emailController, hintText: 'alexandre@exemple.fr', icon: CupertinoIcons.at, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Mot de passe'),
                    _buildInputField(
                      controller: _passwordController,
                      hintText: '••••••••••••',
                      icon: CupertinoIcons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(_obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash, color: _outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Jauge de sécurité
                    Row(
                      children: List.generate(4, (index) {
                        final step = index + 1;
                        final active = _passwordStrength >= step;
                        Color barColor = _darkMode ? const Color(0xFF343539) : Colors.grey.withOpacity(0.3);
                        if (active) {
                          if (step == 1) barColor = _error;
                          if (step == 2) barColor = _primary;
                          if (step == 3) barColor = _darkMode ? const Color(0xFFC2C1FF) : _secondary;
                          if (step == 4) barColor = _tertiary;
                        }
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 6,
                            margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0),
                            decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(3)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('8 caractères minimum', style: TextStyle(fontSize: 11, color: _textSecondary)),
                        Text(
                          _passwordFeedbackText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _passwordStrength == 4 ? _tertiary : (_passwordStrength >= 2 ? _primary : _error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bouton d'inscription géré par Riverpod
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: [_primary, _secondary], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        boxShadow: [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _executeSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? CupertinoActivityIndicator(color: _darkMode ? const Color(0xFF002957) : Colors.white)
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('S\'inscrire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _darkMode ? const Color(0xFF002957) : Colors.white)),
                            const SizedBox(width: 8),
                            Icon(CupertinoIcons.arrow_right, size: 18, color: _darkMode ? const Color(0xFF002957) : Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. BADGES
              Row(
                children: [
                  Expanded(child: _buildTrustBadge(icon: CupertinoIcons.shield_fill, iconColor: _primary, title: 'Données chiffrées', subtitle: 'Norme bancaire')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTrustBadge(icon: CupertinoIcons.bolt_fill, iconColor: _tertiary, title: 'Validation directe', subtitle: 'Activation rapide')),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'En vous inscrivant, vous acceptez nos Conditions d\'utilisation ainsi que notre politique de confidentialité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _outline, height: 1.4),
              ),
              const SizedBox(height: 16),

              // 7. FOOTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte ? ', style: TextStyle(fontSize: 14, color: _textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Se connecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0, bottom: 6.0),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textSecondary)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: _inputBg, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15, color: _textPrimary),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _outline, fontSize: 15),
          prefixIcon: Icon(icon, color: _outline, size: 20),
          suffixIcon: suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 14.0), child: suffixIcon) : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTrustBadge({required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _trustBadgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(_darkMode ? 0.03 : 0.0)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(fontSize: 11, color: _outline), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}