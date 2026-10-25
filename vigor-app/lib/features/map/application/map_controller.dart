import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/place.dart';
import 'notification_service.dart';

final userLocationProvider = StateProvider<LatLng?>((ref) => null);

final nearbyPlacesProvider = FutureProvider.family<List<Place>, String?>((ref, categoryFilter) async {
  final userLoc = ref.watch(userLocationProvider);
  if (userLoc == null) return [];

  // Appel de la fonction SQL RPC
  final response = await Supabase.instance.client.rpc(
    'get_nearby_places',
    params: {
      'user_lat': userLoc.latitude,
      'user_lng': userLoc.longitude,
      'radius_km': 5.0, // Rayon de 5 km
      'filter_category': categoryFilter,
    },
  );

  final List<Place> places = (response as List<dynamic>).map((e) => Place.fromMap(e)).toList();
  return places;
});

class GeofenceController {
  // Variable pour éviter de spammer la base de données si l'utilisateur reste au même endroit
  static String? _lastNotifiedPlaceId;

  static void startProximityListener(WidgetRef ref) {
    // Initialise le service de notification native uniquement sur mobile (optionnel pour le web)
    if (!kIsWeb) {
      NotificationService.init();
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 50), // Vérifie tous les 50 mètres
    ).listen((Position position) async {
      ref.read(userLocationProvider.notifier).state = LatLng(position.latitude, position.longitude);

      final places = ref.read(nearbyPlacesProvider(null)).value ?? [];
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      for (var place in places) {
        // Si le lieu partenaire est à moins de 200 mètres (< 0.2 km)
        if (place.isPartner && place.distanceKm != null && place.distanceKm! < 1) {

          // Vérifie qu'on n'a pas déjà notifié pour ce même endroit récemment
          if (_lastNotifiedPlaceId != place.id) {
            _lastNotifiedPlaceId = place.id;

            // 1. Insertion dans Supabase (pour alimenter la cloche et la page de notifications)
            try {
              await supabase.from('notifications').insert({
                'user_id': userId,
                'title': 'Partenaire Vigor à proximité ! 🎯',
                'body': 'Tu es près de ${place.name}. Profite de tes avantages exclusifs !',
                'is_read': false,
              });
            } catch (e) {
              debugPrint("Erreur lors de l'insertion de la notification: $e");
            }

            // 2. Notification native mobile (uniquement si on est sur Android/iOS)
            if (!kIsWeb) {
              NotificationService.showGeofenceAlert(
                  'Partenaire à proximité !',
                  'Tu es près de ${place.name}. C\'est le moment de t\'entraîner !'
              );
            }
          }
        }
      }
    });
  }
}