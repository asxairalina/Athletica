import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import 'admin_news_screen.dart';
import 'admin_muscle_groups_screen.dart';
import 'trainer_workouts_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserProfile> _allUsers = [];
  List<UserProfile> _trainers = [];
  List<UserProfile> _users = [];
  List<News> _news = [];
  List<TrainerWorkout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    var allUsers = <UserProfile>[];
    var trainers = <UserProfile>[];
    var users = <UserProfile>[];
    var news = <News>[];
    var workouts = <TrainerWorkout>[];

    try {
      allUsers = await SupabaseService().getAllUsersForAdmin();
      trainers = allUsers.where((u) => u.role == 'trainer').toList();
      users = allUsers.where((u) => u.role == 'user').toList();
    } catch (e) {
      print('Error loading users for admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось загрузить пользователей: $e. '
              'Выполните в Supabase SQL: database/full_portable_setup.sql',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }

    try {
      news = await SupabaseService().getAllNews(includeUnpublished: true);
    } catch (e) {
      print('Error loading news: $e');
    }

    try {
      workouts = await SupabaseService().getTrainerWorkouts();
    } catch (e) {
      print('Error loading workouts: $e');
    }

    if (mounted) {
      setState(() {
        _allUsers = allUsers;
        _trainers = trainers;
        _users = users;
        _news = news;
        _workouts = workouts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildManagementSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Пользователи',
              _users.length.toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Тренеры',
              _trainers.length.toString(),
              Icons.fitness_center,
              Colors.green,
            ),
            _buildStatCard(
              'Новости',
              '${_news.where((n) => n.isPublished).length}/${_news.length}',
              Icons.article,
              Colors.orange,
            ),
            _buildStatCard(
              'Тренировки',
              '${_workouts.where((w) => w.isPublished).length}/${_workouts.length}',
              Icons.sports,
              Colors.purple,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Управление',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildManagementCard(
              'Новости',
              'Управление новостями и публикациями',
              Icons.article,
              Colors.blue,
              () => _navigateToNewsManagement(),
            ),
            _buildManagementCard(
              'Тренировки',
              'Управление тренировками тренеров',
              Icons.fitness_center,
              Colors.green,
              () => _navigateToWorkoutManagement(),
            ),
            _buildManagementCard(
              'Группы мышц',
              'Список, создание и удаление групп',
              Icons.fitness_center,
              Colors.teal,
              () => _navigateToMuscleGroupManagement(),
            ),
            _buildManagementCard(
              'Пользователи',
              'Роли: пользователь и тренер (admin — только в Supabase)',
              Icons.people,
              Colors.orange,
              () => _showUserManagement(),
            ),
            _buildManagementCard(
              'Тренеры',
              'Управление тренерами',
              Icons.sports,
              Colors.purple,
              () => _showTrainerManagement(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNewsManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminNewsScreen(),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToWorkoutManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TrainerWorkoutsScreen(),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _navigateToMuscleGroupManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminMuscleGroupsScreen(),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _showUserManagement() {
    final accounts = _allUsers.where((u) => u.role != 'admin').toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Управление аккаунтами (${accounts.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: accounts.isEmpty
              ? const Center(
                  child: Text(
                    'Нет аккаунтов в таблице users.\n'
                    'Выполните full_portable_setup.sql в Supabase.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final user = accounts[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(
                        '${user.email ?? 'без email'} · роль: ${user.role}'
                        '${user.profileCompleted ? '' : ' · профиль не завершён'}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'make_user',
                            child: Text('Сделать пользователем'),
                          ),
                          const PopupMenuItem(
                            value: 'make_trainer',
                            child: Text('Сделать тренером'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'make_user') {
                            _changeUserRole(user.userId, 'user');
                          } else if (value == 'make_trainer') {
                            _changeUserRole(user.userId, 'trainer');
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showTrainerManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление тренерами'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _trainers.length,
            itemBuilder: (context, index) {
              final trainer = _trainers[index];
              return ListTile(
                title: Text(trainer.name),
                subtitle: Text(trainer.email ?? ''),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'make_user',
                      child: Text('Сделать пользователем'),
                    ),
                    const PopupMenuItem(
                      value: 'make_trainer',
                      child: Text('Сделать тренером'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'make_user') {
                      _changeUserRole(trainer.userId, 'user');
                    } else if (value == 'make_trainer') {
                      _changeUserRole(trainer.userId, 'trainer');
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    try {
      await SupabaseService().updateUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Роль пользователя изменена')),
      );
      _loadDashboardData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка изменения роли: $e')),
      );
    }
  }
}
