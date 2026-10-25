import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/home_page.dart';
import 'edit_profile_page.dart'; // Import de la future page d'édition

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF3E90FF) : const Color(0xFF0A84FF);
    final Color cardBg = isDark ? const Color(0xFF1E1F23) : Colors.white;

    final profileAsync = ref.watch(userProfileProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121317) : const Color(0xFFFAF9FE),
      appBar: AppBar(
        title: const Text('Mon Profil Santé'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profil introuvable'));

          final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
          final allergiesText = (profile.allergies != null && profile.allergies!.isNotEmpty)
              ? profile.allergies!.join(', ')
              : 'Aucune';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? const Color(0xFF292A2E) : Colors.grey.shade200,
                  backgroundImage: hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
                  onBackgroundImageError: (_, __) {},
                  child: !hasAvatar ? Icon(CupertinoIcons.person_fill, size: 50, color: primaryColor) : null,
                ),
                const SizedBox(height: 16),
                Text(profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(currentUser?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(child: _buildHighlightCard(icon: CupertinoIcons.scope, title: 'Objectif', value: profile.goal?.label ?? 'Non défini', color: primaryColor, cardBg: cardBg)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildHighlightCard(icon: CupertinoIcons.leaf_arrow_circlepath, title: 'Régime', value: profile.dietType ?? 'Standard', color: Colors.green, cardBg: cardBg)),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildDataRow('Téléphone', profile.phone ?? "--", CupertinoIcons.phone),
                      const Divider(height: 1),
                      _buildDataRow('Âge', '${profile.age ?? "--"} ans', CupertinoIcons.calendar),
                      const Divider(height: 1),
                      _buildDataRow('Taille', '${profile.heightCm ?? "--"} cm', CupertinoIcons.arrow_up_down),
                      const Divider(height: 1),
                      _buildDataRow('Poids', '${profile.weightKg ?? "--"} kg', CupertinoIcons.speedometer),
                      const Divider(height: 1),
                      _buildDataRow('Budget Repas', '${profile.dailyBudgetMad ?? "--"} MAD', CupertinoIcons.money_dollar),
                      const Divider(height: 1),
                      _buildDataRow('Allergies', allergiesText, CupertinoIcons.exclamationmark_triangle),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigation vers la page d'édition en passant le profil actuel
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage(profile: profile)),
                      );
                    },
                    icon: const Icon(CupertinoIcons.pencil),
                    label: const Text('Modifier le profil'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHighlightCard({required IconData icon, required String title, required String value, required Color color, required Color cardBg}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDataRow(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
    );
  }
}