import 'dart:math';

class AnalyticsService {
  static List<Map<String, dynamic>> _workoutHistory = [];
  static List<Map<String, dynamic>> _weightHistory = [];
  static List<Map<String, dynamic>> _taskHistory = [];

  // Инициализация тестовыми данными
  static void initializeTestData() {
    final now = DateTime.now();
    final random = Random();
    
    // Генерируем историю тренировок за последние 30 дней
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final hasWorkout = random.nextDouble() > 0.3; // 70% шанс тренировки
      
      if (hasWorkout) {
        _workoutHistory.add({
          'date': date,
          'duration': 30 + random.nextInt(90), // 30-120 минут
          'calories': 200 + random.nextInt(400), // 200-600 калорий
          'type': ['strength', 'cardio', 'flexibility', 'mixed'][random.nextInt(4)],
        });
      }
    }
    
    // Генерируем историю веса за последние 30 дней
    double currentWeight = 75.0;
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      if (i % 3 == 0) { // Вес записываем каждые 3 дня
        currentWeight += (random.nextDouble() - 0.5) * 2; // +/- 1 кг
        _weightHistory.add({
          'date': date,
          'weight': currentWeight,
        });
      }
    }
    
    // Генерируем историю выполнения заданий
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final tasksCompleted = random.nextInt(4); // 0-3 задания
      
      if (tasksCompleted > 0) {
        _taskHistory.add({
          'date': date,
          'tasksCompleted': tasksCompleted,
          'experience': tasksCompleted * 150, // ~150 XP за задание
        });
      }
    }
  }

  // Получение активности по дням для календаря
  static Map<DateTime, int> getActivityByDays() {
    final Map<DateTime, int> activityMap = {};
    
    for (final workout in _workoutHistory) {
      final date = DateTime(workout['date'].year, workout['date'].month, workout['date'].day);
      activityMap[date] = (activityMap[date] ?? 0) + 1;
    }
    
    return activityMap;
  }

  // Получение статистики за период
  static Map<String, dynamic> getStatsForPeriod(DateTime start, DateTime end) {
    final workoutsInPeriod = _workoutHistory.where((w) => 
        w['date'].isAfter(start.subtract(const Duration(days: 1))) && 
        w['date'].isBefore(end.add(const Duration(days: 1)))).toList();
    
    final totalWorkouts = workoutsInPeriod.length;
    final totalDuration = workoutsInPeriod.fold<int>(0, (sum, w) => sum + w['duration'] as int);
    final totalCalories = workoutsInPeriod.fold<int>(0, (sum, w) => sum + w['calories'] as int);
    final avgDuration = totalWorkouts > 0 ? totalDuration / totalWorkouts : 0;
    final avgCalories = totalWorkouts > 0 ? totalCalories / totalWorkouts : 0;
    
    // Статистика по типам тренировок
    final typeStats = <String, int>{};
    for (final workout in workoutsInPeriod) {
      final type = workout['type'] as String;
      typeStats[type] = (typeStats[type] ?? 0) + 1;
    }
    
    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'avgDuration': avgDuration.round(),
      'avgCalories': avgCalories.round(),
      'typeStats': typeStats,
    };
  }

  // Получение данных для графиков веса
  static List<Map<String, dynamic>> getWeightChartData() {
    return _weightHistory.map((entry) => {
      'date': entry['date'],
      'weight': (entry['weight'] as double).toStringAsFixed(1),
    }).toList();
  }

  // Получение данных для графиков прогресса
  static List<Map<String, dynamic>> getProgressChartData() {
    return _taskHistory.map((entry) => {
      'date': entry['date'],
      'experience': entry['experience'],
      'tasks': entry['tasksCompleted'],
    }).toList();
  }

  // Получение текущего streak (дней подряд с тренировками)
  static int getCurrentStreak() {
    if (_workoutHistory.isEmpty) return 0;
    
    final sortedDates = _workoutHistory.map((w) => w['date'] as DateTime).toList();
    sortedDates.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) { // Проверяем до года назад
      final hasWorkout = sortedDates.any((date) => 
          date.year == currentDate.year && 
          date.month == currentDate.month && 
          date.day == currentDate.day);
      
      if (hasWorkout) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  // Получение личных рекордов
  static Map<String, dynamic> getPersonalRecords() {
    if (_workoutHistory.isEmpty) {
      return {
        'longestWorkout': 0,
        'mostCalories': 0,
        'totalWorkouts': 0,
      };
    }
    
    final longestWorkout = _workoutHistory.fold<int>(0, (max, w) => 
        max > w['duration'] ? max : w['duration'] as int);
    
    final mostCalories = _workoutHistory.fold<int>(0, (max, w) => 
        max > w['calories'] ? max : w['calories'] as int);
    
    return {
      'longestWorkout': longestWorkout,
      'mostCalories': mostCalories,
      'totalWorkouts': _workoutHistory.length,
    };
  }

  // Добавление новой тренировки
  static void addWorkout({
    required int duration,
    required int calories,
    required String type,
  }) {
    _workoutHistory.add({
      'date': DateTime.now(),
      'duration': duration,
      'calories': calories,
      'type': type,
    });
  }

  // Добавление записи веса
  static void addWeightEntry(double weight) {
    _weightHistory.add({
      'date': DateTime.now(),
      'weight': weight,
    });
  }

  // Добавление выполнения заданий
  static void addTaskCompletion(int tasksCompleted, int experience) {
    _taskHistory.add({
      'date': DateTime.now(),
      'tasksCompleted': tasksCompleted,
      'experience': experience,
    });
  }
}
