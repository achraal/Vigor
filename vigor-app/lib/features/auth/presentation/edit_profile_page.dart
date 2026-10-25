import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/domain/user_profile.dart';
import '../../home/home_page.dart'; // Pour rafraîchir le provider

class EditProfilePage extends ConsumerStatefulWidget {
  final UserProfile profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _budgetController;
  late TextEditingController _allergiesController;

  late HealthGoal _selectedGoal;
  late String _selectedDiet;
  bool _isLoading = false;

  final List<String> _diets = ['Standard', 'Halal', 'Végétarien', 'Vegan'];

  @override
  void initState() {
    super.initState();
    // Pré-remplissage des champs avec les données actuelles
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _ageController = TextEditingController(text: widget.profile.age?.toString() ?? '');
    _heightController = TextEditingController(text: widget.profile.heightCm?.toString() ?? '');
    _weightController = TextEditingController(text: widget.profile.weightKg?.toString() ?? '');
    _budgetController = TextEditingController(text: widget.profile.dailyBudgetMad?.toString() ?? '');
    _allergiesController = TextEditingController(
      text: (widget.profile.allergies ?? []).join(', '),
    );

    _selectedGoal = widget.profile.goal ?? HealthGoal.maintenance;
    _selectedDiet = widget.profile.dietType ?? 'Standard';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _budgetController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      // Transformation des allergies (séparées par des virgules) en liste propre
      final allergiesList = _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text),
        'height_cm': double.tryParse(_heightController.text),
        'weight_kg': double.tryParse(_weightController.text),
        'daily_budget_mad': double.tryParse(_budgetController.text),
        'goal': _selectedGoal.name,
        'diet_type': _selectedDiet,
        'allergies': allergiesList,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('profiles')
          .update(updateData)
          .eq('id', widget.profile.id);

      if (mounted) {
        // Rafraîchir le state global pour que ProfilePage et le Drawer se mettent à jour
        ref.invalidate(userProfileProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Retour à la page profil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF3E90FF) : const Color(0xFF0A84FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121317) : const Color(0xFFFAF9FE),
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Informations personnelles'),
              _buildTextField(_nameController, 'Nom complet', TextInputType.name, isDark),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Téléphone', TextInputType.phone, isDark),
              const SizedBox(height: 24),

              _buildSectionTitle('Données Biométriques'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_ageController, 'Âge', TextInputType.number, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_heightController, 'Taille (cm)', TextInputType.number, isDark)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_weightController, 'Poids (kg)', TextInputType.number, isDark),
              const SizedBox(height: 24),

              _buildSectionTitle('Nutrition & Préférences'),
              _buildTextField(_budgetController, 'Budget quotidien (MAD)', TextInputType.number, isDark),
              const SizedBox(height: 16),
              _buildTextField(_allergiesController, 'Allergies (séparées par des virgules)', TextInputType.text, isDark, hint: 'ex: Arachides, Gluten'),
              const SizedBox(height: 24),

              const Text('Objectif principal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              SegmentedButton<HealthGoal>(
                segments: HealthGoal.values.map((goal) => ButtonSegment<HealthGoal>(value: goal, label: Text(goal.label, style: const TextStyle(fontSize: 11)))).toList(),
                selected: {_selectedGoal},
                onSelectionChanged: (Set<HealthGoal> newSelection) => setState(() => _selectedGoal = newSelection.first),
              ),
              const SizedBox(height: 24),

              const Text('Préférence alimentaire', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDiet,
                dropdownColor: isDark ? const Color(0xFF1E1F23) : Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF292A2E) : Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _diets.map((diet) => DropdownMenuItem(value: diet, child: Text(diet, style: TextStyle(color: isDark ? Colors.white : Colors.black)))).toList(),
                onChanged: (newValue) {
                  if (newValue != null) setState(() => _selectedDiet = newValue);
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('Sauvegarder les modifications', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, bool isDark, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: isDark ? const Color(0xFF292A2E) : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}