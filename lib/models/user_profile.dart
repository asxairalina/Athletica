class UserProfile {
  final String fullName;
  final int height;
  final int weight;
  final String? avatarUrl;
  final List<Achievement> achievements;

  UserProfile({
    required this.fullName,
    required this.height,
    required this.weight,
    this.avatarUrl,
    this.achievements = const [],
  });

  UserProfile copyWith({
    String? fullName,
    int? height,
    int? weight,
    String? avatarUrl,
    List<Achievement>? achievements,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      achievements: achievements ?? this.achievements,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedDate,
  });
}
