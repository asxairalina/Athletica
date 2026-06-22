import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/news_widget.dart';
import '../services/navigation_service.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _currentUser;
  bool _isLoading = true;
  int _todayWorkoutCount = 0;
  int _todayCalories = 0;
  int _todayMinutes = 0;
  int _todayWaterIntake = 0;
  int _todaySteps = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    NavigationService.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (NavigationService.currentIndexNotifier.value == 0 && mounted) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    NavigationService.removeListener(_onTabChanged);
    super.dispose();
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  Future<void> _loadUserData() async {
    // Получаем пользователя отдельно, чтобы имя загрузилось даже если workout history упадет
    UserProfile? effectiveUser;
    try {
      final user = await SupabaseService().getCurrentUser();
      effectiveUser = user;
    } catch (e) {
      print('Error loading current user: $e');
    }

    // Fallback на auth данные если getCurrentUser не сработал
    if (effectiveUser == null) {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser != null) {
        final nameFromMeta = authUser.userMetadata?['name'] as String?;
        final nameFromEmail = authUser.email?.split('@').first;
        effectiveUser = UserProfile(
          userId: authUser.id,
          name: nameFromMeta ?? nameFromEmail ?? 'Пользователь',
          email: authUser.email,
          age: 0,
          gender: '',
          height: 0,
          weight: 0,
          fitnessGoal: '',
          totalExperience: 0,
          currentLevel: 1,
          profileCompleted: false,
          role: 'user',
          createdAt: DateTime.now(),
        );
      }
    }

    // Только тренировки за сегодня (локальный календарный день)
    final today = DateTime.now();
    List<Map<String, dynamic>> workoutHistory = [];
    try {
      workoutHistory = await SupabaseService().getWorkoutHistory(
        limit: 100,
        forDay: today,
      );
    } catch (e) {
      print('Error loading workout history: $e');
    }
    int todayCount = 0;
    int todayCalories = 0;
    int todayMinutes = 0;

    for (final workout in workoutHistory) {
      final createdAt = workout['created_at'];
      final workoutDate = createdAt is DateTime
          ? createdAt.toLocal()
          : DateTime.tryParse(createdAt?.toString() ?? '')?.toLocal();
      if (workoutDate != null && _isSameLocalDay(workoutDate, today)) {
        todayCount++;
        todayCalories += (workout['calories'] as int? ?? 0);
        todayMinutes += ((workout['duration'] as int? ?? 0) / 60).round();
      }
    }

    int todayWater = 0;
    int todaySteps = 0;
    try {
      final todayProgress = await SupabaseService().getTodayProgress();
      todayWater = (todayProgress['water_intake'] as int?) ?? 0;
      todaySteps = (todayProgress['steps_taken'] as int?) ?? 0;
    } catch (e) {
      print('Error loading today progress: $e');
    }

    if (mounted) {
      setState(() {
        _currentUser = effectiveUser;
        _todayWorkoutCount = todayCount;
        _todayCalories = todayCalories;
        _todayMinutes = todayMinutes;
        _todayWaterIntake = todayWater;
        _todaySteps = todaySteps;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const NewsWidget(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),
                  _buildQuickStats(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добро пожаловать, ${_currentUser?.name ?? 'Пользователь'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Готов к новой тренировке сегодня?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сегодняшняя статистика',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                context,
                'Калории',
                _todayCalories.toString(),
                'ккал',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                context,
                'Время',
                _todayMinutes.toString(),
                'мин',
                Icons.access_time,
                Colors.blue,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                context,
                'Тренировки',
                _todayWorkoutCount.toString(),
                'шт',
                Icons.fitness_center,
                Colors.green,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                context,
                'Вода',
                _todayWaterIntake.toString(),
                'мл',
                Icons.water,
                Colors.cyan,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 24,
              child: _buildStatCard(
                context,
                'Шаги',
                _todaySteps.toString(),
                '',
                Icons.directions_walk,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Начать тренировку',
                Icons.play_arrow,
                () {
                  NavigationService.switchToTab(4);
                },
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Записать вес',
                Icons.monitor_weight,
                () {
                  _showWeightDialog(context);
                },
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onTap, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeightDialog(BuildContext context) {
    final TextEditingController weightController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Записать вес'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Введите ваш текущий вес:'),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Вес (кг)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'кг',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight != null && weight > 0) {
                  Navigator.of(context).pop();
                  // Обновляем вес в SupaBase и сохраняем запись в историю веса
                  await SupabaseService().updateUserProfile({'weight': weight});
                  await SupabaseService().logWeight(weight);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Вес $weight кг записан!')),
                  );
                  _loadUserData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите корректный вес')),
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}
