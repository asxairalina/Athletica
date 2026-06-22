import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/avatar_picker.dart';
import '../models/user_level.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../services/task_service.dart';
import '../services/progress_service.dart';
import '../models/supabase_models.dart' as supabase_models;
import '../widgets/achievement_widget.dart';
import '../widgets/experience_bar.dart';
import '../widgets/profile_avatar.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _userProfile;
  late UserLevel _userLevel;
  supabase_models.UserProfile? _supabaseUser;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final supabaseUser = await SupabaseService().getCurrentUser();
      if (mounted) {
        setState(() {
          _supabaseUser = supabaseUser;
          _isLoading = false;
          
          if (supabaseUser != null) {
            _userProfile = UserProfile(
              fullName: supabaseUser.name,
              height: supabaseUser.height.round(),
              weight: supabaseUser.weight.round(),
              achievements: _getInitialAchievements(supabaseUser),
            );
            _userLevel = UserLevel.calculateLevel(supabaseUser.totalExperience);
          } else {
            // Fallback значения если пользователь не найден
            _userProfile = UserProfile(
              fullName: 'Пользователь',
              height: 170,
              weight: 70,
              achievements: _getInitialAchievements(null),
            );
            _userLevel = UserLevel.calculateLevel(0);
          }
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userProfile = UserProfile(
            fullName: 'Пользователь',
            height: 170,
            weight: 70,
            achievements: _getInitialAchievements(null),
          );
          _userLevel = UserLevel.calculateLevel(0);
        });
      }
    }
  }

  List<Achievement> _getInitialAchievements(supabase_models.UserProfile? user) {
    return [
      Achievement(
        id: '1',
        title: 'Новичок',
        description: 'Зарегистрируйтесь',
        icon: '👶',
        isUnlocked: true,
        unlockedDate: user?.createdAt ?? DateTime.now(),
      ),      Achievement(
        id: '2',
        title: 'Спортсмен',
        description: 'Проведите 30 тренировок',
        icon: '💪',
        isUnlocked: false,
      ),
      Achievement(
        id: '3',
        title: 'Прошаренный',
        description: 'Проведите 100 тренировок',
        icon: '🏆',
        isUnlocked: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_supabaseUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Профиль'),
        ),
        body: const Center(
          child: Text('Профиль не найден'),
        ),
      );
    }

    final user = _supabaseUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileAvatar(
                        avatarUrl: user.avatarPath,
                        displayName: user.name,
                        radius: 40,
                      ),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.black45,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Возраст: ${user.age} лет',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Рост: ${user.height} см',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Вес: ${user.weight} кг',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${_getGoalText(user.fitnessGoal)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${_getRoleText(user.role)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ExperienceBar(userLevel: _userLevel),
            const SizedBox(height: 24),
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            _buildExperienceSection(),
            if (user.role == 'admin') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Открыть админ-панель'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGoalText(String goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Похудение';
      case 'muscle_gain':
        return 'Набор мышечной массы';
      case 'endurance':
        return 'Выносливость';
      case 'flexibility':
        return 'Гибкость';
      case 'general_fitness':
        return 'Общая физическая форма';
      default:
        return 'Не указана';
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Администратор';
      case 'trainer':
        return 'Тренер';
      case 'user':
      default:
        return 'Пользователь';
    }
  }

  Widget _buildProfileField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем профиль при каждом открытии экрана
    _loadUserData();
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Достижения',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._userProfile.achievements.map((achievement) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AchievementWidget(achievement: achievement),
          );
        }),
      ],
    );
  }

  bool get _supportsNativeCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _showAvatarOptions() async {
    final hasAvatar = _supabaseUser?.avatarPath != null &&
        _supabaseUser!.avatarPath!.isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать фото'),
              onTap: () {
                Navigator.pop(context);
                _pickAvatarFromFiles();
              },
            ),
            if (_supportsNativeCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarFromCamera();
                },
              ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Удалить аватар', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatarFromFiles() async {
    try {
      final picked = await pickAvatarFromGallery();
      if (picked == null) return;
      await _uploadAvatarBytes(picked.bytes, picked.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить аватар: $e')),
        );
      }
    }
  }

  Future<void> _pickAvatarFromCamera() async {
    try {
      final picked = await pickAvatarFromCamera();
      if (picked == null) return;
      await _uploadAvatarBytes(picked.bytes, picked.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Камера недоступна. Выберите фото из галереи: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatarBytes(List<int> bytes, String? fileName) async {
    setState(() => _isUploadingAvatar = true);
    try {
      await SupabaseService().uploadUserAvatar(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
      );
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар обновлён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить аватар: $e')),
        );
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      setState(() => _isUploadingAvatar = true);
      await SupabaseService().removeUserAvatar();
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватар удалён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _logout() async {
    try {
      await TaskService.onUserSignedOut();
      ProgressService.resetDailyProgress();
      await SupabaseService().signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы успешно вышли из профиля')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выходе: $e')),
        );
      }
    }
  }

  Widget _buildExperienceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Опыт и уровни',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLevelInfo(),
            const SizedBox(height: 12),
            _buildExperienceTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Как получить опыт:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildExperienceItem('Выполнение ежедневных заданий', '100-500 XP'),
          _buildExperienceItem('Проведение тренировок', '50 XP'),
          _buildExperienceItem('Новые личные рекорды', '100 XP'),
          _buildExperienceItem('Последовательные тренировки', '25 XP'),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(String action, String experience) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            experience,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Требования к уровням:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildLevelRow('1-5', '100-500 XP', 'Новичок'),
        _buildLevelRow('6-9', '600-900 XP', 'Любитель'),
        _buildLevelRow('10+', '1000 XP/уровень', 'Профи и выше'),
      ],
    );
  }

  Widget _buildLevelRow(String levels, String experience, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              levels,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              experience,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
