class UserLevel {
  final int level;
  final int currentExperience;
  final int experienceToNextLevel;
  final int totalExperience;

  const UserLevel({
    required this.level,
    required this.currentExperience,
    required this.experienceToNextLevel,
    required this.totalExperience,
  });

  static UserLevel calculateLevel(int totalExperience) {
    if (totalExperience < 100) {
      return UserLevel(
        level: 1,
        currentExperience: totalExperience,
        experienceToNextLevel: 100,
        totalExperience: totalExperience,
      );
    }

    int level = 1;
    int experienceNeeded = 100;
    int remainingExperience = totalExperience;

    for (int i = 2; i <= 5; i++) {
      experienceNeeded = i * 100;
      if (remainingExperience < experienceNeeded) {
        return UserLevel(
          level: level,
          currentExperience: remainingExperience,
          experienceToNextLevel: experienceNeeded,
          totalExperience: totalExperience,
        );
      }
      remainingExperience -= experienceNeeded;
      level = i;
    }

    for (int i = 6; i <= 9; i++) {
      experienceNeeded = i * 100;
      if (remainingExperience < experienceNeeded) {
        return UserLevel(
          level: level,
          currentExperience: remainingExperience,
          experienceToNextLevel: experienceNeeded,
          totalExperience: totalExperience,
        );
      }
      remainingExperience -= experienceNeeded;
      level = i;
    }

    while (remainingExperience >= 1000) {
      remainingExperience -= 1000;
      level++;
    }

    return UserLevel(
      level: level,
      currentExperience: remainingExperience,
      experienceToNextLevel: 1000,
      totalExperience: totalExperience,
    );
  }

  static int getExperienceRequired(int level) {
    if (level == 1) return 0;
    if (level <= 5) return level * 100;
    if (level <= 9) return level * 100;
    return 1000;
  }

  static String getLevelTitle(int level) {
    if (level <= 3) return 'Новичок';
    if (level <= 6) return 'Любитель';
    if (level <= 10) return 'Профи';
    if (level <= 20) return 'Мастер';
    if (level <= 30) return 'Эксперт';
    if (level <= 50) return 'Легенда';
    return 'Бог фитнеса';
  }

  static String getLevelIcon(int level) {
    if (level <= 3) return '🌱';
    if (level <= 6) return '🌿';
    if (level <= 10) return '🌳';
    if (level <= 20) return '🔥';
    if (level <= 30) return '⚡';
    if (level <= 50) return '👑';
    return '🏆';
  }

  double get progress {
    return currentExperience / experienceToNextLevel;
  }

  String get progressText {
    return '$currentExperience/$experienceToNextLevel XP';
  }
}
