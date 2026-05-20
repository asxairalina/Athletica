import '../models/daily_task.dart';
import '../services/task_service.dart';

class ProgressService {
  static int _workoutsCompleted = 0;
  static bool _hasDoneWarmup = false;
  static bool _hasDoneStretching = false;
  static bool _hasDoneCardio = false;
  static bool _hasDoneStrength = false;
  static int _waterIntake = 0; // в стаканах
  static int _stepsCount = 0;
  static bool _hasDoneLongWorkout = false;
  static bool _hasDonePeakLoad = false;
  static bool _hasCompletedAllTasks = false;

  // Методы для отслеживания действий
  static void completeWorkout({Duration? duration}) {
    _workoutsCompleted++;
    _checkTaskProgress();
  }

  static void completeWarmup() {
    _hasDoneWarmup = true;
    _checkTaskProgress();
  }

  static void completeStretching() {
    _hasDoneStretching = true;
    _checkTaskProgress();
  }

  static void completeCardio() {
    _hasDoneCardio = true;
    _checkTaskProgress();
  }

  static void completeStrength() {
    _hasDoneStrength = true;
    _checkTaskProgress();
  }

  static void addWaterIntake() {
    _waterIntake++;
    _checkTaskProgress();
  }

  static void addSteps(int steps) {
    _stepsCount += steps;
    _checkTaskProgress();
  }

  static void completeLongWorkout() {
    _hasDoneLongWorkout = true;
    _checkTaskProgress();
  }

  static void completePeakLoad() {
    _hasDonePeakLoad = true;
    _checkTaskProgress();
  }

  static void checkAllTasksCompletion() {
    final tasks = TaskService.getDailyTasks();
    final completedCount = tasks.where((task) => _isTaskCompleted(task)).length;
    
    if (completedCount == tasks.length) {
      _hasCompletedAllTasks = true;
    }
  }

  static void _checkTaskProgress() {
    // Проверяем все задания после каждого действия
    final tasks = TaskService.getDailyTasks();
    
    for (final task in tasks) {
      if (_isTaskCompleted(task) && !task.isCompleted) {
        // Автоматически отмечаем задание как выполненное и добавляем опыт
        TaskService.completeTaskWithExperience(task.id);
      }
    }
    
    checkAllTasksCompletion();
  }


  static bool _isTaskCompleted(DailyTask task) {
    switch (task.id) {
      case '1': // Первая тренировка
        return _workoutsCompleted >= 1;
      case '2': // Разминка
        return _hasDoneWarmup;
      case '3': // Гидратация
        return _waterIntake >= 8; // 2 литра = 8 стаканов
      case '4': // Растяжка
        return _hasDoneStretching;
      case '5': // Шаги
        return _stepsCount >= 5000;
      case '6': // Тренировочная неделя
        return _workoutsCompleted >= 5;
      case '7': // Силовая тренировка
        return _hasDoneStrength;
      case '8': // Кардио сессия
        return _hasDoneCardio;
      case '9': // Белковый рацион (пока не реализовано)
        return false;
      case '10': // Прогресс (пока не реализовано)
        return false;
      case '12': // Марафон
        return _hasDoneLongWorkout;
      case '13': // Пиковая нагрузка
        return _hasDonePeakLoad;
      case '15': // Железная воля
        return _hasCompletedAllTasks;
      default:
        return false;
    }
  }

  static void resetDailyProgress() {
    _workoutsCompleted = 0;
    _hasDoneWarmup = false;
    _hasDoneStretching = false;
    _hasDoneCardio = false;
    _hasDoneStrength = false;
    _waterIntake = 0;
    _stepsCount = 0;
    _hasDoneLongWorkout = false;
    _hasDonePeakLoad = false;
    _hasCompletedAllTasks = false;
  }

  static Map<String, dynamic> getProgressStats() {
    return {
      'workoutsCompleted': _workoutsCompleted,
      'hasDoneWarmup': _hasDoneWarmup,
      'hasDoneStretching': _hasDoneStretching,
      'hasDoneCardio': _hasDoneCardio,
      'hasDoneStrength': _hasDoneStrength,
      'waterIntake': _waterIntake,
      'stepsCount': _stepsCount,
      'hasDoneLongWorkout': _hasDoneLongWorkout,
      'hasDonePeakLoad': _hasDonePeakLoad,
      'hasCompletedAllTasks': _hasCompletedAllTasks,
    };
  }
}
