import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../application/map_controller.dart';
import '../domain/place.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;

  // États des filtres
  String? _selectedCategory;
  String? _selectedCuisine;
  double? _maxDistance;
  int? _maxPrice;

  // Gestion du chargement
  bool _isLoadingLocation = true; // Démarre à true car on cherche le GPS au lancement

  static const LatLng _casablancaCenter = LatLng(33.5731, -7.5898);

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    setState(() => _isLoadingLocation = true); // Début du chargement

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position pos = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);

      ref.read(userLocationProvider.notifier).state = userLatLng;
      GeofenceController.startProximityListener(ref);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14.0));
    } catch (e) {
      debugPrint("Erreur de localisation: $e");
    } finally {
      // Fin du chargement GPS (même en cas d'erreur)
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filtres avancés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // 1. FILTRE DE DISTANCE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Distance : ${_maxDistance != null ? "${_maxDistance!.toInt()} km" : "Désactivée"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Switch(
                          value: _maxDistance != null,
                          onChanged: (val) => setModalState(() => _maxDistance = val ? 5.0 : null),
                        ),
                      ],
                    ),
                    if (_maxDistance != null)
                      Slider(
                        value: _maxDistance!,
                        min: 1.0, max: 20.0, divisions: 19,
                        onChanged: (val) => setModalState(() => _maxDistance = val),
                      ),
                    const Divider(),

                    // 2. FILTRE DE BUDGET
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget : ${_maxPrice != null ? "Activé" : "Tous les prix"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Switch(
                          value: _maxPrice != null,
                          onChanged: (val) => setModalState(() => _maxPrice = val ? 3 : null),
                        ),
                      ],
                    ),
                    if (_maxPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ChoiceChip(
                              label: const Text('€ (Étudiant)'),
                              selected: _maxPrice == 1,
                              onSelected: (val) { if(val) setModalState(() => _maxPrice = 1); },
                            ),
                            ChoiceChip(
                              label: const Text('€€'),
                              selected: _maxPrice == 2,
                              onSelected: (val) { if(val) setModalState(() => _maxPrice = 2); },
                            ),
                            ChoiceChip(
                              label: const Text('€€€'),
                              selected: _maxPrice == 3,
                              onSelected: (val) { if(val) setModalState(() => _maxPrice = 3); },
                            ),
                          ],
                        ),
                      ),
                    const Divider(),

                    // 3. FILTRE DE CUISINE (Uniquement si on cherche des restaurants ou "Tous")
                    if (_selectedCategory == null || _selectedCategory == 'restaurant') ...[
                      const Text('Type de cuisine', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButton<String?>(
                        value: _selectedCuisine,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Toutes les cuisines (Désactivé)')),
                          DropdownMenuItem(value: 'Marocaine', child: Text('Marocaine')),
                          DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
                          DropdownMenuItem(value: 'Asiatique', child: Text('Asiatique')),
                        ],
                        onChanged: (val) => setModalState(() => _selectedCuisine = val),
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      // Message informatif si l'utilisateur est sur l'onglet Gym/Marché
                      const Text('Le filtre de cuisine est réservé aux restaurants.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 32),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Si l'utilisateur a changé de catégorie pour Gym/Market, on efface le filtre cuisine
                          if (_selectedCategory != null && _selectedCategory != 'restaurant') {
                            _selectedCuisine = null;
                          }
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Appliquer les filtres', style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }
    );
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(place.category == 'gym' ? Icons.fitness_center : Icons.restaurant, size: 40, color: place.isPartner ? Colors.orange : Colors.green),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(place.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${place.distanceKm?.toStringAsFixed(1) ?? "--"} km - ${place.cuisineType ?? place.category}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (place.isPartner)
                  const Chip(label: Text('Partenaire Vigor', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange),
                if (place.priceLevel == 1)
                  const Chip(label: Text('Prix Étudiant', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
              ],
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final userLoc = ref.watch(userLocationProvider) ?? _casablancaCenter;
    final placesAsync = ref.watch(nearbyPlacesProvider(_selectedCategory));

    Set<Marker> allMarkers = {};

    if (placesAsync.value != null) {
      final filteredPlaces = placesAsync.value!.where((p) {
        final matchPrice = _maxPrice == null || p.priceLevel <= _maxPrice!;
        final matchDistance = _maxDistance == null || (p.distanceKm ?? 0) <= _maxDistance!;

        // CORRECTION DU BUG "City Club" :
        // Le lieu doit être un restaurant ET avoir la cuisine sélectionnée (en ignorant la casse)
        final matchCuisine = _selectedCuisine == null ||
            (p.category == 'restaurant' && p.cuisineType?.toLowerCase() == _selectedCuisine!.toLowerCase());

        return matchPrice && matchDistance && matchCuisine;
      });

      for (var place in filteredPlaces) {
        allMarkers.add(
            Marker(
              markerId: MarkerId(place.id),
              position: LatLng(place.latitude, place.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(place.isPartner ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen),
              onTap: () => _showPlaceDetails(place),
            )
        );
      }
    }

/*    allMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLoc,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Ma position actuelle'),
          zIndex: 2,
        )
    );*/

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer à proximité'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterModal),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildFilterChip('Tous', null),
                _buildFilterChip('Restaurants', 'restaurant'),
                _buildFilterChip('Salles de sport', 'gym'),
                _buildFilterChip('Marchés', 'market'),
              ],
            ),
          ),
          Expanded(
            // Utilisation d'un Stack pour superposer le loader sur la carte
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: userLoc, zoom: 13.0),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                  markers: allMarkers,
                  circles: {
                    Circle(
                      circleId: const CircleId('user_dot'),
                      center: userLoc,
                      radius: 80,
                      fillColor: Colors.blueAccent,
                      strokeColor: Colors.white,
                      strokeWidth: 3,
                      zIndex: 2,
                    ),
                    if (_maxDistance != null)
                      Circle(
                        circleId: const CircleId('user_radius'),
                        center: userLoc,
                        radius: _maxDistance! * 1000,
                        fillColor: Colors.blue.withOpacity(0.1),
                        strokeColor: Colors.blue,
                        strokeWidth: 1,
                      )
                  },
                ),

                // GESTION DU CHARGEMENT VISUEL
                if (_isLoadingLocation || placesAsync.isLoading)
                  Center(
                    child: Card(
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Recherche en cours...", style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedCategory == category,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
            // Si on ne sélectionne plus un restaurant ou "Tous", on réinitialise la cuisine
            if (_selectedCategory != null && _selectedCategory != 'restaurant') {
              _selectedCuisine = null;
            }
          });
        },
      ),
    );
  }
}