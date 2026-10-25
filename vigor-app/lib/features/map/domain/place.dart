class Place {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final int priceLevel;
  final bool isPartner;
  final double? distanceKm;
  final String? cuisineType;

  Place({
    required this.id, required this.name, required this.category,
    required this.latitude, required this.longitude,
    required this.priceLevel, required this.isPartner, this.distanceKm, this.cuisineType,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      priceLevel: map['price_level'] ?? 1,
      isPartner: map['is_partner'] ?? false,
      distanceKm: map['distance_km'] != null ? (map['distance_km'] as num).toDouble() : null,
      cuisineType: map['cuisine_type'],
    );
  }
}