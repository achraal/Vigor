import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';
import '../../home/home_page.dart';

class RegisterStep2Page extends ConsumerStatefulWidget {
  const RegisterStep2Page({super.key});

  @override
  ConsumerState<RegisterStep2Page> createState() => _RegisterStep2PageState();
}

class _RegisterStep2PageState extends ConsumerState<RegisterStep2Page> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _budgetController = TextEditingController();

  HealthGoal _selectedGoal = HealthGoal.maintenance;
  String _selectedDiet = 'Standard';
  bool _isLoading = false;

  final List<String> _diets = ['Standard', 'Halal', 'Végétarien', 'Vegan'];

  bool get _darkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _bgSurface => _darkMode ? const Color(0xFF121317) : const Color(0xFFFAF9FE);
  Color get _primary => _darkMode ? const Color(0xFF3E90FF) : const Color(0xFF0A84FF);

  Future<void> _submitHealthProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'age': int.tryParse(_ageController.text),
        'height_cm': double.tryParse(_heightController.text),
        'weight_kg': double.tryParse(_weightController.text),
        'daily_budget_mad': double.tryParse(_budgetController.text),
        'goal': _selectedGoal.name,
        'diet_type': _selectedDiet,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Mise à jour du profil existant généré par le trigger SQL
      await Supabase.instance.client
          .from('profiles')
          .update(updateData)
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil santé configuré avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
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
    return Scaffold(
      backgroundColor: _bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.grey),
        title: const Text('Profil Santé', style: TextStyle(color: Colors.grey, fontSize: 14)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Personnalisons votre Coach IA',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _darkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ces données permettront au système RAG et à la génération de menus de s\'adapter à vous.',
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildTextField(_ageController, 'Âge', 'ex: 22', TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_heightController, 'Taille (cm)', 'ex: 180', TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_weightController, 'Poids (kg)', 'ex: 75', TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_budgetController, 'Budget (MAD/jour)', 'ex: 25', TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Objectif principal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              SegmentedButton<HealthGoal>(
                segments: HealthGoal.values.map((goal) {
                  return ButtonSegment<HealthGoal>(
                    value: goal,
                    label: Text(goal.label, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
                selected: {_selectedGoal},
                onSelectionChanged: (Set<HealthGoal> newSelection) {
                  setState(() => _selectedGoal = newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) return _primary.withOpacity(0.2);
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Préférence alimentaire', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDiet,
                dropdownColor: _darkMode ? const Color(0xFF1E1F23) : Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _darkMode ? const Color(0xFF292A2E) : Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _diets.map((String diet) {
                  return DropdownMenuItem(value: diet, child: Text(diet, style: TextStyle(color: _darkMode ? Colors.white : Colors.black)));
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) setState(() => _selectedDiet = newValue);
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _submitHealthProfile,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text('Terminer l\'inscription', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: _darkMode ? const Color(0xFF292A2E) : Colors.grey.shade200,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}