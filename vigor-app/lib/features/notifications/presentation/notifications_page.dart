import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../application/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  // Marquer une seule notification comme lue
  Future<void> _markAsRead(String notifId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notifId);
  }

  // Marquer toutes les notifications comme lues
  Future<void> _markAllAsRead() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.checkmark_alt_circle),
            tooltip: 'mark_all_read'.tr(),
            onPressed: () => _markAllAsRead(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bell_slash, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'no_notifications'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.isRead
                      ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                      : Colors.blue.withOpacity(0.2),
                  child: Icon(
                    CupertinoIcons.bell_solid,
                    color: n.isRead ? Colors.grey : Colors.blue,
                    size: 18,
                  ),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(n.body),
                ),
                trailing: !n.isRead
                    ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
                    : null,
                onTap: () {
                  if (!n.isRead) _markAsRead(n.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}