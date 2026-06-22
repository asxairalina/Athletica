import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import '../widgets/profile_avatar.dart';
import '../services/navigation_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _activityMap = {};
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _records = {};
  int _currentStreak = 0;
  List<Map<String, dynamic>> _weightHistory = [];
  List<Map<String, dynamic>> _monthlyWorkoutCounts = [];

  Map<String, dynamic>? _familyProgress;
  Future<Family?>? _familyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadAnalyticsData();
    _familyFuture = _loadFamily();
    NavigationService.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    NavigationService.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (NavigationService.currentIndexNotifier.value == 2) {
      _loadAnalyticsData();
      _familyFuture = _loadFamily();
    }
  }

  Future<void> _loadAnalyticsData() async {
    DateTime parseCreatedAt(dynamic rawCreatedAt) {
      if (rawCreatedAt is DateTime) return rawCreatedAt;
      return DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now();
    }

    try {
      // Получаем реальные данные из Supabase
      final workoutHistory = await SupabaseService().getWorkoutHistory(limit: 200);
      final weightHistory = await SupabaseService().getWeightHistory(limit: 100);
      
      // Сортируем и преобразуем историю веса
      final parsedWeightHistory = weightHistory.map((item) {
        DateTime? entryDate;
        final rawDate = item['date'];
        if (rawDate is String) {
          entryDate = DateTime.tryParse(rawDate);
        } else if (rawDate is DateTime) {
          entryDate = rawDate;
        }
        return {
          'date': entryDate ?? DateTime.now(),
          'weight': item['weight'] is num
              ? (item['weight'] as num).toDouble()
              : double.tryParse(item['weight']?.toString() ?? '') ?? 0.0,
        };
      }).toList();
      parsedWeightHistory.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      if (parsedWeightHistory.isEmpty) {
        final profile = await SupabaseService().getCurrentUser();
        if (profile != null && profile.weight > 0) {
          parsedWeightHistory.add({
            'date': profile.updatedAt ?? profile.createdAt,
            'weight': profile.weight,
          });
        }
      }
      
      // Формируем карту активности для календаря
      final Map<DateTime, int> activityMap = {};
      for (final workout in workoutHistory) {
        final createdAt = parseCreatedAt(workout['created_at']);
        final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
        activityMap[date] = (activityMap[date] ?? 0) + 1;
      }
      
      // Считаем статистику за 30 дней
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentWorkouts = workoutHistory.where((w) {
        final createdAt = parseCreatedAt(w['created_at']);
        return !createdAt.isBefore(thirtyDaysAgo);
      }).toList();
      
      final totalWorkouts = recentWorkouts.length;
      final totalDuration = recentWorkouts.fold<num>(0, (sum, w) => sum + (w['duration'] ?? 0)).toInt();
      final totalCalories = recentWorkouts.fold<num>(0, (sum, w) => sum + (w['calories'] ?? 0)).toInt();
      final avgDuration = totalWorkouts > 0 ? (totalDuration / totalWorkouts / 60).round() : 0;
      
      final monthlyAverages = await SupabaseService().getMonthlyAverageWaterAndSteps();
      final avgWater = monthlyAverages['avgWater'] as int? ?? 0;
      final avgSteps = monthlyAverages['avgSteps'] as int? ?? 0;
      
      // Вычисляем персональные рекорды по истории тренировок
      final longestWorkoutSeconds = workoutHistory.fold<int>(0, (max, w) {
        final duration = w['duration'] is int ? w['duration'] as int : int.tryParse(w['duration']?.toString() ?? '0') ?? 0;
        return duration > max ? duration : max;
      });
      final longestWorkoutMinutes = (longestWorkoutSeconds / 60).ceil();
      final mostCalories = workoutHistory.fold<int>(0, (max, w) {
        final calories = w['calories'] is int ? w['calories'] as int : int.tryParse(w['calories']?.toString() ?? '0') ?? 0;
        return calories > max ? calories : max;
      });
      final totalWorkoutCount = workoutHistory.length;
      
      if (!mounted) return;
      setState(() {
        _activityMap = activityMap;
        _weightHistory = parsedWeightHistory;
        _monthlyWorkoutCounts = _buildMonthlyWorkoutCounts(workoutHistory);
        _stats = {
          'totalWorkouts': totalWorkouts,
          'totalDuration': (totalDuration / 60).round(), // конвертируем в минуты
          'totalCalories': totalCalories,
          'avgDuration': avgDuration,
          'avgWater': avgWater,
          'avgSteps': avgSteps,
        };
        _records = {
          'longest_workout': '${longestWorkoutMinutes} мин',
          'most_calories': '$mostCalories ккал',
          'total_workouts': '$totalWorkoutCount',
        };
        _currentStreak = _calculateCurrentStreak(workoutHistory);
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      // В случае ошибки показываем пустые данные
      if (!mounted) return;
      setState(() {
        _activityMap = {};
        _stats = {
          'totalWorkouts': 0,
          'totalDuration': 0,
          'totalCalories': 0,
          'avgDuration': 0,
          'avgWater': 0,
          'avgSteps': 0,
        };
        _records = {};
        _currentStreak = 0;
      });
    }
  }

  Future<void> _loadFamilyProgress() async {
    final family = await SupabaseService().getUserFamily();
    if (family == null) return;

    final progress = await SupabaseService().getFamilyProgress(family.id);
    
    if (!mounted) return;
    setState(() {
      _familyProgress = progress;
    });
  }
  
  int _calculateCurrentStreak(List<Map<String, dynamic>> workoutHistory) {
    if (workoutHistory.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    
    // Получаем уникальные даты тренировок
    DateTime parseCreatedAt(dynamic rawCreatedAt) {
      if (rawCreatedAt is DateTime) return rawCreatedAt;
      return DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now();
    }

    final workoutDates = workoutHistory
        .map((w) {
          final createdAt = parseCreatedAt(w['created_at']);
          return DateTime(createdAt.year, createdAt.month, createdAt.day);
        })
        .toSet()
        .toList()
        ..sort((a, b) => b.compareTo(a)); // Сортируем по убыванию
    
    // Если сегодня нет тренировки и вчера тоже нет, серия равна 0
    if (!workoutDates.contains(todayDate) && !workoutDates.contains(yesterday)) {
      return 0;
    }
    
    // Считаем серию подряд идущих дней
    int streak = 0;
    DateTime checkDate = workoutDates.contains(todayDate) ? todayDate : yesterday;
    
    for (int i = 0; i < workoutDates.length; i++) {
      if (workoutDates[i].isAtSameMomentAs(checkDate) || 
          workoutDates[i].isAtSameMomentAs(checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мой прогресс'),
            Tab(text: 'Моя семья'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка "Мой прогресс"
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStreakCard(),
                const SizedBox(height: 16),
                _buildCalendar(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildCharts(),
                const SizedBox(height: 24),
                _buildRecords(),
              ],
            ),
          ),
          // Вкладка "Моя семья"
          _buildFamilyTab(),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return FutureBuilder<Family?>(
      key: ValueKey(_familyProgress),
      future: _familyFuture ??= _loadFamily(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'У вас еще нет семейной группы',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Создайте семейную группу, чтобы\nслеживать прогресс вместе',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showCreateFamilyDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать группу'),
                ),
              ],
            ),
          );
        }

        final family = snapshot.data as Family?;
        if (family == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                family.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_familyProgress != null) ...[
                _buildFamilyProgressCard(),
                const SizedBox(height: 16),
                _buildFamilyMembersCard(family.id),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddMemberDialog(context, family.id),
                icon: const Icon(Icons.person_add),
                label: const Text('Добавить участника'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Family?> _loadFamily() async {
    final family = await SupabaseService().getUserFamily();
    if (family != null) {
      _loadFamilyProgress();
    }
    return family;
  }

  Widget _buildFamilyProgressCard() {
    if (_familyProgress == null) return const SizedBox.shrink();

    final totalSteps = _familyProgress!['totalSteps'] as int? ?? 0;
    final totalWorkouts = _familyProgress!['totalWorkouts'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прогресс семьи',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalSteps.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'шагов',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalWorkouts.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'тренировок',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembersCard(String familyId) {
    return FutureBuilder(
      future: SupabaseService().getFamilyMembers(familyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Участники (${members.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...members.map((member) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ProfileAvatar(
                      avatarUrl: member.avatarPath,
                      displayName: member.userName ?? member.userEmail ?? 'У',
                      radius: 20,
                    ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.userName ?? member.userEmail ?? 'Участник',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              member.role == 'owner' ? 'Владелец' : 'Участник',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateFamilyDialog(BuildContext context) {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext innerDialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Создать семейную группу'),
            content: TextField(
              controller: controller,
              enabled: !isLoading,
              onChanged: (_) => setDialogState(() {}),
              decoration: const InputDecoration(
                hintText: 'Название группы',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: isLoading || controller.text.isEmpty
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          await SupabaseService().createFamily(controller.text);
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          setState(() {
                            _familyProgress = null;
                            _familyFuture = _loadFamily();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Семейная группа создана')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                          setDialogState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }


  void _showAddMemberDialog(BuildContext context, String familyId) {
    final controller = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext innerDialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Добавить участника'),
            content: TextField(
              controller: controller,
              enabled: !isLoading,
              onChanged: (_) => setDialogState(() {}),
              decoration: const InputDecoration(
                hintText: 'Email участника',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: isLoading || controller.text.isEmpty
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          await SupabaseService().addFamilyMemberByEmail(familyId, controller.text);
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Участник добавлен')),
                          );
                          setState(() {
                            _familyProgress = null;
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                          setDialogState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildStreakCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Текущая серия',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_currentStreak дней подряд',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Календарь активности',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: (day) {
                final activity = _activityMap[DateTime(day.year, day.month, day.day)];
                return activity != null && activity > 0 ? [activity] : [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика за 30 дней',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                'Тренировки',
                '${_stats['totalWorkouts'] ?? 0}',
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                'Время',
                '${_stats['totalDuration'] ?? 0} мин',
                Icons.access_time,
                Colors.green,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                'Калории',
                '${_stats['totalCalories'] ?? 0}',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                'Среднее',
                '${_stats['avgDuration'] ?? 0} мин',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                'Воды/день',
                '${_stats['avgWater'] ?? 0} мл',
                Icons.water,
                Colors.cyan,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                'Шагов/день',
                '${_stats['avgSteps'] ?? 0}',
                Icons.directions_walk,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Графики прогресса',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Динамика веса',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildWeightChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тренировки по месяцам',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildWorkoutChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    // Получаем реальные данные о весе
    final weightData = _getWeightChartData();
    
    if (weightData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Нет данных о весе')),
      );
    }
    
    // Находим минимальный и максимальный вес для шкалы Y
    final weights = weightData.map((w) => w['weight'] as double).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    final interval = weightRange > 0 ? weightRange / 5 : 1.0;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)} кг',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < weightData.length) {
                  final date = weightData[value.toInt()]['date'] as DateTime;
                  return Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: weightData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['weight'] as double);
            }).toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
        minY: minWeight - weightRange * 0.1,
        maxY: maxWeight + weightRange * 0.1,
      ),
    );
  }

  Widget _buildWorkoutChart() {
    final chartData = _getWorkoutChartData();
    
    if (chartData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Нет данных о тренировках')),
      );
    }
    
    final counts = chartData.map((item) => item['count'] as int).toList();
    final maxCount = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b).toDouble() : 1.0;
    final displayMax = maxCount > 0 ? maxCount : 1.0;
    
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: displayMax / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: displayMax / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 35,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < chartData.length) {
                  final month = chartData[value.toInt()]['month'] as DateTime;
                  return Transform.rotate(
                    angle: -45 * 3.14159 / 180,
                    child: Text(
                      "${month.month.toString().padLeft(2, '0')}.${month.year % 100}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        ),
        barGroups: chartData.asMap().entries.map((entry) {
          final count = entry.value['count'] as int;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: Theme.of(context).colorScheme.secondary,
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
        maxY: displayMax * 1.2,
      ),
    );
  }

  Widget _buildRecords() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Личные рекорды',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecordItem(
              'Самая длинная тренировка',
              _records['longest_workout']?.toString() ?? '0 мин',
              Icons.timer,
            ),
            const SizedBox(height: 12),
            _buildRecordItem(
              'Больше всего калорий',
              _records['most_calories']?.toString() ?? '0 ккал',
              Icons.local_fire_department,
            ),
            const SizedBox(height: 12),
            _buildRecordItem(
              'Всего тренировок',
              _records['total_workouts']?.toString() ?? '0',
              Icons.fitness_center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getWeightChartData() {
    return _weightHistory;
  }

  List<Map<String, dynamic>> _getWorkoutChartData() {
    return _monthlyWorkoutCounts;
  }

  List<Map<String, dynamic>> _buildMonthlyWorkoutCounts(List<Map<String, dynamic>> workoutHistory) {
    final now = DateTime.now();
    final months = List<DateTime>.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index, 1);
      return DateTime(month.year, month.month, 1);
    });

    final counts = <DateTime, int>{};
    for (final month in months) {
      counts[month] = 0;
    }

    for (final workout in workoutHistory) {
      final createdAt = _parseDate(workout['created_at']);
      final monthKey = DateTime(createdAt.year, createdAt.month, 1);
      if (counts.containsKey(monthKey)) {
        counts[monthKey] = counts[monthKey]! + 1;
      }
    }

    return months.map((month) {
      return {
        'month': month,
        'count': counts[month] ?? 0,
      };
    }).toList();
  }

  DateTime _parseDate(dynamic rawCreatedAt) {
    if (rawCreatedAt is DateTime) return rawCreatedAt;
    return DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now();
  }
}
