enum HealthGoal {
  weight_loss('Perte de poids'),
  muscle_gain('Prise de masse'),
  maintenance('Maintien'),
  diabetic('Diabétique');

  final String label;
  const HealthGoal(this.label);
}

class UserProfile {
  final String id;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final HealthGoal? goal;
  final List<String>? allergies;
  final String? dietType;
  final double? dailyBudgetMad;

  UserProfile({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.age,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.allergies,
    this.dietType,
    this.dailyBudgetMad,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    HealthGoal? mappedGoal;
    if (map['goal'] != null) {
      mappedGoal = HealthGoal.values.firstWhere(
            (e) => e.name == map['goal'],
        orElse: () => HealthGoal.maintenance,
      );
    }

    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
      age: map['age'],
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      goal: mappedGoal,
      allergies: List<String>.from(map['allergies'] ?? []),
      dietType: map['diet_type'],
      dailyBudgetMad: (map['daily_budget_mad'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal': goal?.name,
      'allergies': allergies,
      'diet_type': dietType,
      'daily_budget_mad': dailyBudgetMad,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}