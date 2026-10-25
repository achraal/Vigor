import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart'; // <-- IMPORT i18n
import '../auth/presentation/login_page.dart';
import '../auth/domain/user_profile.dart';
import '../auth/presentation/profile_page.dart';
import '../../../features/map/presentation/map_page.dart';
import '../../../features/settings/presentation/settings_page.dart';
import '../../../features/notifications/application/notification_provider.dart';
import '../../../features/notifications/presentation/notifications_page.dart';

// 1. Création du Provider pour récupérer le profil utilisateur
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return UserProfile.fromMap(response);
});

// 2. Transformation en ConsumerWidget pour écouter le Provider
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  // Marquer une seule notification comme lue
  Future<void> _markAsRead(String notifId) async {
    await Supabase.instance.client.from('notifications').update({'is_read': true}).eq('id', notifId);
  }

  // Marquer toutes les notifications comme lues
  Future<void> _markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('notifications').update({'is_read': true}).eq('user_id', user.id).eq('is_read', false);
    }
  }

  // Affichage du menu des notifications
  void _showNotificationsMenu(BuildContext context, List<AppNotification> notifs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('notifications'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      _markAllAsRead();
                      Navigator.pop(context);
                    },
                    child: Text('mark_all_read'.tr()),
                  ),
                ],
              ),
              const Divider(),
              if (notifs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('no_notifications'.tr(), style: const TextStyle(color: Colors.grey)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.isRead ? Colors.grey.shade200 : Colors.blue.withOpacity(0.2),
                          child: Icon(CupertinoIcons.bell_solid, color: n.isRead ? Colors.grey : Colors.blue, size: 18),
                        ),
                        title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(n.body),
                        onTap: () {
                          if (!n.isRead) _markAsRead(n.id);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF3E90FF) : const Color(0xFF0A84FF);

    final profileAsync = ref.watch(userProfileProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    // Calcul du nombre de notifications non lues
    final unreadCount = notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount.toString()),
              child: const Icon(CupertinoIcons.bell_fill),
            ),
            onPressed: () {
              // Navigation vers la page dédiée
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E1F23) : Colors.white,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur : $error')),
          data: (profile) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: primaryColor,
                  ),
                  accountName: Text(
                    profile?.name ?? 'Utilisateur',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  accountEmail: Text(
                    'Objectif : ${profile?.goal?.label ?? "Non défini"}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF121317) : Colors.white,
                    backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                        ? Icon(CupertinoIcons.person_fill, size: 40, color: primaryColor)
                        : null,
                  ),
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.person_crop_circle, color: isDark ? Colors.white70 : Colors.black87),
                  title: const Text('Mon Profil Santé'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.map_pin_ellipse, color: isDark ? Colors.white70 : Colors.black87),
                  title: const Text('Explorer à proximité'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.chart_bar_alt_fill, color: isDark ? Colors.white70 : Colors.black87),
                  title: const Text('Statistiques & Évolution'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(CupertinoIcons.gear_alt_fill, color: isDark ? Colors.white70 : Colors.black87),
                  title: const Text('Préférences & Notifications'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.redAccent),
                  title: const Text('Se déconnecter', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                  onTap: () => _logout(context),
                ),
              ],
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.camera_viewfinder, size: 80, color: primaryColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'ready_scan'.tr(), // Traduit dynamiquement
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'subtitle_scan'.tr(), // Traduit dynamiquement
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(CupertinoIcons.camera_fill, color: Colors.white),
      ),
    );
  }
}