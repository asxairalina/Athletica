import 'dart:math';
import '../models/daily_task.dart';

class WorkoutStreakService {
  static List<DateTime> _workoutDates = [];

  static void addWorkoutDate() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    if (!_workoutDates.any((date) => 
        date.year == todayOnly.year && 
        date.month == todayOnly.month && 
        date.day == todayOnly.day)) {
      _workoutDates.add(todayOnly);
      _workoutDates.sort((a, b) => b.compareTo(a)); // Сортируем по убыванию
    }
  }

  static int getCurrentStreak() {
    if (_workoutDates.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    
    int streak = 0;
    DateTime currentDate = todayOnly;
    
    for (int i = 0; i < 365; i++) { // Проверяем до года назад
      if (_workoutDates.any((date) => 
          date.year == currentDate.year && 
          date.month == currentDate.month && 
          date.day == currentDate.day)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  static List<DailyTask> getStreakBasedTasks() {
    final streak = getCurrentStreak();
    final tasks = <DailyTask>[];
    
    if (streak >= 7) {
      tasks.add(DailyTask(
        id: 'streak_7',
        title: 'Неделя без пропусков',
        description: 'Тренируйтесь 7 дней подряд без перерывов',
        difficulty: TaskDifficulty.hard,
        experience: 500,
        isCompleted: true,
      ));
    }
    
    if (streak >= 30) {
      tasks.add(DailyTask(
        id: 'streak_30',
        title: 'Месяц дисциплины',
        description: 'Тренируйтесь 30 дней подряд',
        difficulty: TaskDifficulty.hard,
        experience: 1000,
        isCompleted: true,
      ));
    }
    
    return tasks;
  }

  static Map<String, dynamic> getStreakStats() {
    final streak = getCurrentStreak();
    final longestStreak = _getLongestStreak();
    final totalWorkouts = _workoutDates.length;
    
    return {
      'currentStreak': streak,
      'longestStreak': longestStreak,
      'totalWorkouts': totalWorkouts,
      'nextMilestone': _getNextMilestone(streak),
    };
  }

  static int _getLongestStreak() {
    if (_workoutDates.isEmpty) return 0;
    
    int longestStreak = 0;
    int currentStreak = 0;
    
    // Сортируем даты по возрастанию
    final sortedDates = List<DateTime>.from(_workoutDates);
    sortedDates.sort((a, b) => a.compareTo(b));
    
    DateTime? previousDate;
    
    for (final date in sortedDates) {
      if (previousDate == null) {
        currentStreak = 1;
      } else {
        final difference = date.difference(previousDate).inDays;
        if (difference == 1) {
          currentStreak++;
        } else {
          longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
          currentStreak = 1;
        }
      }
      previousDate = date;
    }
    
    longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
    return longestStreak;
  }

  static String _getNextMilestone(int currentStreak) {
    if (currentStreak < 7) return '7 дней';
    if (currentStreak < 30) return '30 дней';
    if (currentStreak < 100) return '100 дней';
    if (currentStreak < 365) return '365 дней';
    return 'Марафонец!';
  }
}
