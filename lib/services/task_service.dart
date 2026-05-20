import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_task.dart';
import 'supabase_service.dart';

class TaskService {
  static bool _isInitialized = false;
  static DateTime? _initializedDate;
  static String? _activeUserId;

  static String _completedTaskIdsKey(String userId) =>
      'daily_task_completed_ids_$userId';
  static String _completedDateKey(String userId) =>
      'daily_task_completed_date_$userId';

  static List<DailyTask> _allTasks = [
    // Легкие задания (100 опыта)
    DailyTask(
      id: '1',
      title: 'Первая тренировка',
      description: 'Сделайте одну тренировку любой сложности',
      difficulty: TaskDifficulty.easy,
      experience: 100,
    ),
    DailyTask(
      id: '2',
      title: 'Разминка',
      description: 'Выполните 10-минутную разминку перед тренировкой',
      difficulty: TaskDifficulty.easy,
      experience: 100,
    ),
    DailyTask(
      id: '3',
      title: 'Гидратация',
      description: 'Выпейте 2 литра воды в течение дня',
      difficulty: TaskDifficulty.easy,
      experience: 100,
    ),
    DailyTask(
      id: '4',
      title: 'Растяжка',
      description: 'Выполните 15-минутную растяжку после тренировки',
      difficulty: TaskDifficulty.easy,
      experience: 100,
    ),
    DailyTask(
      id: '5',
      title: 'Шаги',
      description: 'Пройдите 5000 шагов за день',
      difficulty: TaskDifficulty.easy,
      experience: 100,
    ),

    // Средние задания (250 опыта)
    DailyTask(
      id: '6',
      title: 'Тренировочная неделя',
      description: 'Сделайте 5 тренировок за неделю',
      difficulty: TaskDifficulty.medium,
      experience: 250,
    ),
    DailyTask(
      id: '7',
      title: 'Силовая тренировка',
      description: 'Выполните силовую тренировку на верхнюю часть тела',
      difficulty: TaskDifficulty.medium,
      experience: 250,
    ),
    DailyTask(
      id: '8',
      title: 'Кардио сессия',
      description: 'Проведите 30-минутную кардио тренировку',
      difficulty: TaskDifficulty.medium,
      experience: 250,
    ),
    DailyTask(
      id: '9',
      title: 'Белковый рацион',
      description: 'Употребите 100г белка в течение дня',
      difficulty: TaskDifficulty.medium,
      experience: 250,
    ),
    DailyTask(
      id: '10',
      title: 'Прогресс',
      description: 'Улучшите свой предыдущий результат на 10%',
      difficulty: TaskDifficulty.medium,
      experience: 250,
    ),

    // Сложные задания (500 опыта)
    DailyTask(
      id: '12',
      title: 'Марафон',
      description: 'Проведите тренировку длительностью более 60 минут',
      difficulty: TaskDifficulty.hard,
      experience: 500,
    ),
    DailyTask(
      id: '13',
      title: 'Пиковая нагрузка',
      description: 'Выполните 3 подхода с максимальным весом',
      difficulty: TaskDifficulty.hard,
      experience: 500,
    ),
    DailyTask(
      id: '15',
      title: 'Железная воля',
      description: 'Выполните все 3 ежедневных задания за один день',
      difficulty: TaskDifficulty.hard,
      experience: 500,
    ),
  ];

  static final Set<String> _completedTaskIds = {};
  static List<DailyTask>? _todayTasks;

  static List<DailyTask> getDailyTasks() {
    if (!_isInitialized) {
      initializeDailyTasks();
    }

    // Если уже сгенерированы сегодня — возвращаем с актуальным isCompleted
    if (_todayTasks != null) {
      return _todayTasks!.map((t) => t.copyWith(
        isCompleted: _completedTaskIds.contains(t.id),
      )).toList();
    }

    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = Random(seed);

    // Выбираем 3 случайных задания (по одному каждого уровня сложности)
    final easyTasks = _allTasks.where((t) => t.difficulty == TaskDifficulty.easy).toList();
    final mediumTasks = _allTasks.where((t) => t.difficulty == TaskDifficulty.medium).toList();
    final hardTasks = _allTasks.where((t) => t.difficulty == TaskDifficulty.hard).toList();

    final selectedTasks = <DailyTask>[];
    selectedTasks.add(easyTasks[random.nextInt(easyTasks.length)]);
    selectedTasks.add(mediumTasks[random.nextInt(mediumTasks.length)]);
    selectedTasks.add(hardTasks[random.nextInt(hardTasks.length)]);

    _todayTasks = selectedTasks;
    return selectedTasks.map((t) => t.copyWith(
      isCompleted: _completedTaskIds.contains(t.id),
    )).toList();
  }

  static void completeTask(String taskId) {
    _completedTaskIds.add(taskId);
    _saveCompletedTaskIds();
    print('Задание $taskId выполнено!');
  }

  static Future<void> completeTaskWithExperience(String taskId) async {
    if (_completedTaskIds.contains(taskId)) {
      print('Задание $taskId уже выполнено');
      return;
    }

    _completedTaskIds.add(taskId);
    await _saveCompletedTaskIds();

    // Находим задание и добавляем опыт
    final task = _allTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => DailyTask(
        id: '',
        title: '',
        description: '',
        difficulty: TaskDifficulty.easy,
        experience: 0,
      ),
    );

    if (task.id.isNotEmpty) {
      try {
        await SupabaseService().addExperience(task.experience);
        print('Опыт добавлен: +${task.experience} XP за задание $taskId');
      } catch (e) {
        print('Ошибка при добавлении опыта: $e');
      }
    }
  }

  static bool isTaskCompleted(String taskId) {
    return _completedTaskIds.contains(taskId);
  }

  static void resetDailyTasks() {
    _completedTaskIds.clear();
    _todayTasks = null;
    _isInitialized = false;
    _initializedDate = null;
    if (_activeUserId != null) {
      _saveCompletedTaskIds();
    }
  }

  /// Сброс локального состояния заданий при выходе или смене аккаунта.
  static Future<void> onUserSignedOut() async {
    _activeUserId = null;
    _completedTaskIds.clear();
    _todayTasks = null;
    _isInitialized = false;
    _initializedDate = null;
  }

  static Future<bool> initializeDailyTasks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      await onUserSignedOut();
      return false;
    }

    final userChanged = _activeUserId != userId;
    if (userChanged) {
      _completedTaskIds.clear();
      _todayTasks = null;
      _isInitialized = false;
    }
    _activeUserId = userId;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_isInitialized && _initializedDate == todayDate) {
      return userChanged;
    }

    _todayTasks = null;
    _initializedDate = todayDate;
    _isInitialized = true;
    await _loadCompletedTaskIds(userId);
    return userChanged;
  }

  static Future<void> _loadCompletedTaskIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_completedDateKey(userId));
    final today = DateTime.now();
    final todayString = _formatDateKey(today);

    if (savedDate == todayString) {
      _completedTaskIds
        ..clear()
        ..addAll(prefs.getStringList(_completedTaskIdsKey(userId)) ?? []);
    } else {
      _completedTaskIds.clear();
      await prefs.setString(_completedDateKey(userId), todayString);
      await prefs.remove(_completedTaskIdsKey(userId));
    }
  }

  static Future<void> _saveCompletedTaskIds() async {
    final userId = _activeUserId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _completedTaskIdsKey(userId),
      _completedTaskIds.toList(),
    );
    await prefs.setString(
      _completedDateKey(userId),
      _formatDateKey(DateTime.now()),
    );
  }

  static String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static int getTotalExperience(List<DailyTask> tasks) {
    return tasks.where((t) => t.isCompleted)
        .fold(0, (sum, task) => sum + task.experience);
  }
}
