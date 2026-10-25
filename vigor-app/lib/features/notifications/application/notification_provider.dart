import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({required this.id, required this.title, required this.body, required this.isRead, required this.createdAt});

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// Écoute en temps réel de la table notifications
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((map) => AppNotification.fromMap(map)).toList());
});