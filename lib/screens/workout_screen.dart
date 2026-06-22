import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/progress_service.dart';
import '../services/supabase_service.dart';
import '../models/muscle_group.dart';
import '../models/exercise_video.dart';
import '../models/supabase_models.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/video_player_widget.dart';
import 'create_workout_screen.dart';

class _MuscleGroupCategoryData {
  final List<SupabaseMuscleGroup> groups;
  final Map<String, int> workoutCounts;

  const _MuscleGroupCategoryData({
    required this.groups,
    required this.workoutCounts,
  });
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = await SupabaseService().getCurrentUser();
      print('Проверка роли пользователя: ${user?.role}');
      if (mounted) {
        setState(() {
          _userRole = user?.role;
        });
        print('Роль установлена: $_userRole');
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildAgeTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWorkoutContent('infants', 'Младенцы'),
                _buildWorkoutContent('pregnant', 'Беременные'),
                _buildWorkoutContent('young', 'Молодежь'),
                _buildWorkoutContent('senior', 'Взрослые'),
              ],
            ),
          ),
        ],
      ),
      // Кнопка создания тренировок для тренеров и администраторов
      floatingActionButton: (_userRole == 'trainer' || _userRole == 'admin')
          ? FloatingActionButton.extended(
              onPressed: _showCreateWorkoutDialog,
              icon: const Icon(Icons.add),
              label: const Text('Создать тренировку'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildAgeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        tabs: const [
          Tab(
            icon: Icon(Icons.child_care),
            text: 'До года',
          ),
          Tab(
            icon: Icon(Icons.pregnant_woman),
            text: 'Беременные',
          ),
          Tab(
            icon: Icon(Icons.sports_gymnastics),
            text: 'Молодежь',
          ),
          Tab(
            icon: Icon(Icons.accessibility),
            text: 'Взрослые',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutContent(String category, String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Тренировки для $title',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCategoryDescription(category),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          _buildMuscleGroups(context, category),
          const SizedBox(height: 24),
          _buildTrackingSection(context),
        ],
      ),
    );
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'infants':
        return 'Безопасные упражнения для развития младенцев до 1 года. Всегда консультируйтесь с педиатром.';
      case 'pregnant':
        return 'Специальные упражнения для беременных. Учитывайте рекомендации врача и триместры.';
      case 'young':
        return 'Интенсивные тренировки для молодых и активных. Идеально для набора формы и силы.';
      case 'senior':
        return 'Щадящие упражнения для взрослой возрастной группы. Фокус на гибкости и здоровье.';
      default:
        return '';
    }
  }

  Future<_MuscleGroupCategoryData> _loadMuscleGroupsWithCounts(String category) async {
    try {
      final dbCategory = _getDatabaseMuscleCategory(category);
      final groups = await SupabaseService().getMuscleGroups(dbCategory);
      final workouts = await SupabaseService().getTrainerWorkouts(onlyPublished: true);

      final counts = <String, int>{};
      for (final group in groups) {
        counts[group.name] = workouts.where((w) => _matchesMuscleGroup(w, group.name)).length;
      }

      return _MuscleGroupCategoryData(groups: groups, workoutCounts: counts);
    } catch (e) {
      print('Error loading muscle groups with counts: $e');
      return _MuscleGroupCategoryData(groups: [], workoutCounts: {});
    }
  }

  Widget _buildMuscleGroups(BuildContext context, String category) {
    return FutureBuilder<_MuscleGroupCategoryData>(
      future: _loadMuscleGroupsWithCounts(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Ошибка загрузки групп: ${snapshot.error}'),
            ),
          );
        }

        final data = snapshot.data;
        final muscleGroups = data?.groups ?? [];
        final counts = data?.workoutCounts ?? {};

        if (muscleGroups.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Группы мышц еще не настроены в базе данных для этой категории.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == 'infants' ? 'Группы упражнений' : 'Группы мышц',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: muscleGroups.length,
                  itemBuilder: (context, index) {
                    final muscleGroup = muscleGroups[index];
                    final count = counts[muscleGroup.name] ?? 0;
                    return _buildSupabaseMuscleGroupCard(context, muscleGroup, count);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getDatabaseMuscleCategory(String category) {
    switch (category) {
      case 'infants':
        return 'infants';
      case 'pregnant':
        return 'basic';
      case 'young':
        return 'standard';
      case 'senior':
        return 'gentle';
      default:
        return 'infants';
    }
  }

  Widget _buildSupabaseMuscleGroupCard(BuildContext context, SupabaseMuscleGroup muscleGroup, int workoutCount) {
    final color = _colorFromHex(muscleGroup.color);
    final icon = _iconFromName(muscleGroup.icon);

    return GestureDetector(
      onTap: () {
        print('ТАП: Нажата группа мышц: ${muscleGroup.id} (${muscleGroup.name})');
        _showMuscleGroupDetails(context, muscleGroup);
      },
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      muscleGroup.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                muscleGroup.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$workoutCount ${_pluralizeWorkouts(workoutCount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _pluralizeWorkouts(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'тренировка';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) return 'тренировки';
    return 'тренировок';
  }

  Future<void> _showMuscleGroupDetails(BuildContext context, SupabaseMuscleGroup muscleGroup) async {
    print('Нажата группа мышц: ${muscleGroup.name}');

    try {
      final trainerWorkouts = await _loadTrainerWorkouts(muscleGroup.name);
      print('Загруженные тренировки: ${trainerWorkouts.length}');

      if (trainerWorkouts.isNotEmpty) {
        _showTrainerWorkouts(context, trainerWorkouts, muscleGroup);
        return;
      }

      final supabaseVideos = await SupabaseService().getExerciseVideos(muscleGroup.id);
      if (supabaseVideos.isNotEmpty) {
        final videos = supabaseVideos.map((v) => ExerciseVideo(
          id: v.id,
          title: v.title,
          description: v.description,
          videoUrl: v.videoUrl,
          duration: v.duration,
          difficulty: v.difficulty,
          instructions: v.instructions,
        )).toList();

        _showSupabaseVideosBottomSheet(context, videos, muscleGroup);
        return;
      }

      _showEmptyGroupBottomSheet(context, muscleGroup);
    } catch (error) {
      print('Ошибка загрузки деталей группы: $error');
      _showEmptyGroupBottomSheet(context, muscleGroup);
    }
  }

  Future<List<TrainerWorkout>> _loadTrainerWorkouts(String muscleGroupName) async {
    try {
      final workouts = await SupabaseService().getTrainerWorkouts(onlyPublished: true);
      return workouts.where((workout) {
        return _matchesMuscleGroup(workout, muscleGroupName);
      }).toList();
    } catch (e) {
      print('Ошибка получения тренировок: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _rateWorkout(TrainerWorkout workout, int rating) async {
    try {
      final updatedRating = await SupabaseService().rateTrainerWorkout(workout.id, rating);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Вы поставили ${rating} ${rating == 1 ? 'звезду' : 'звезды'}')),
      );
      return updatedRating;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения оценки: $e')),
      );
      return null;
    }
  }

  void _showEmptyGroupBottomSheet(BuildContext context, SupabaseMuscleGroup muscleGroup) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              muscleGroup.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Для этой группы мышц пока нет доступных тренировок или видео в базе данных.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrainerWorkouts(BuildContext context, List<TrainerWorkout> trainerWorkouts, SupabaseMuscleGroup muscleGroup) {
    final color = _colorFromHex(muscleGroup.color);
    final icon = _iconFromName(muscleGroup.icon);
    final displayedWorkouts = List<TrainerWorkout>.from(trainerWorkouts);
    var selectedRatingFilter = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        maxChildSize: 0.98,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setState) {
            final filteredWorkouts = selectedRatingFilter <= 0
                ? displayedWorkouts
                : displayedWorkouts.where((workout) => workout.rating >= selectedRatingFilter).toList();

            return Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                muscleGroup.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                muscleGroup.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Все'),
                            selected: selectedRatingFilter == 0,
                            onSelected: (_) {
                              setState(() {
                                selectedRatingFilter = 0;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (index) {
                            final value = index + 1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$value+'),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                  ],
                                ),
                                selected: selectedRatingFilter == value,
                                onSelected: (_) {
                                  setState(() {
                                    selectedRatingFilter = value;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: filteredWorkouts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Нет тренировок с рейтингом $selectedRatingFilter и выше.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredWorkouts.length,
                              itemBuilder: (context, index) {
                                final workout = filteredWorkouts[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.fitness_center,
                                        color: color,
                                        size: 30,
                                      ),
                                    ),
                                    title: Text(
                                      workout.title,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text(workout.description),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            StarRating(
                                              rating: workout.rating,
                                              onRatingChanged: (rating) async {
                                                final workoutIndex = displayedWorkouts.indexWhere((w) => w.id == workout.id);
                                                if (workoutIndex < 0) return;
                                                final updatedRating = await _rateWorkout(workout, rating);
                                                if (updatedRating == null) return;
                                                setState(() {
                                                  displayedWorkouts[workoutIndex] = displayedWorkouts[workoutIndex].copyWith(
                                                    rating: updatedRating['rating'] as double,
                                                    ratingCount: updatedRating['rating_count'] as int,
                                                  );
                                                });
                                              },
                                            ),
                                            Text(
                                              workout.ratingCount > 0
                                                  ? '${workout.rating.toStringAsFixed(1)} (${workout.ratingCount})'
                                                  : 'Нет оценок',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Длительность: ${workout.duration} мин • Сложность: ${workout.difficulty}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Future.microtask(() {
                                        if (workout.videoUrl.isNotEmpty) {
                                          final video = ExerciseVideo(
                                            id: workout.id,
                                            title: workout.title,
                                            description: workout.description,
                                            videoUrl: workout.videoUrl,
                                            duration: workout.duration * 60,
                                            difficulty: workout.difficulty,
                                            instructions: [
                                              'Длительность: ${workout.duration} минут',
                                              'Сложность: ${workout.difficulty}',
                                            ],
                                          );
                                          _showVideoPlayer(context, video);
                                        } else {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (c) => CreateWorkoutScreen(workout: workout),
                                            ),
                                          );
                                        }
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    final buffer = StringBuffer();
    if (normalized.length == 6) buffer.write('ff');
    buffer.write(normalized);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _iconFromName(String iconName) {
    switch (iconName) {
      case 'spa':
        return Icons.spa;
      case 'child_care':
        return Icons.child_care;
      case 'psychology':
        return Icons.psychology;
      case 'pool':
        return Icons.pool;
      case 'accessibility':
        return Icons.accessibility;
      case 'favorite':
        return Icons.favorite;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'balance':
        return Icons.balance;
      default:
        return Icons.fitness_center;
    }
  }

  void _showVideosBottomSheet(BuildContext context, List<ExerciseVideo> videos, MuscleGroup muscleGroup) {
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        maxChildSize: 0.98,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: muscleGroup.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        muscleGroup.icon,
                        color: muscleGroup.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            muscleGroup.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            muscleGroup.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Список видео
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: muscleGroup.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.play_circle,
                              color: muscleGroup.color,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            video.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                video.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(video.difficulty),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      video.difficulty,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(video.duration ~/ 60)}:${(video.duration % 60).toString().padLeft(2, '0')}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.play_arrow),
                          onTap: () => _showVideoPlayer(context, video),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupabaseVideosBottomSheet(BuildContext context, List<ExerciseVideo> videos, dynamic muscleGroup) {
    // Supabase muscle group uses simple fields (color as hex string, icon as name)
    final color = muscleGroup != null && muscleGroup.color != null
        ? _colorFromHex(muscleGroup.color as String)
        : Theme.of(context).colorScheme.primary;
    final icon = muscleGroup != null && muscleGroup.icon != null
        ? _iconFromName(muscleGroup.icon as String)
        : Icons.fitness_center;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        maxChildSize: 0.98,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            muscleGroup?.name ?? 'Видео',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            muscleGroup?.description ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Video list
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.play_circle_fill, color: color, size: 36),
                          ),
                          title: Text(video.title),
                          subtitle: Text(video.description ?? ''),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showVideoPlayer(context, video);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Легкий':
        return Colors.green;
      case 'Средний':
        return Colors.orange;
      case 'Сложный':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.fitness_center,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тренировки',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Отслеживайте свой прогресс',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const Map<String, List<String>> _muscleGroupAliases = {
    'chest': ['chest', 'грудь'],
    'back': ['back', 'спина'],
    'shoulders': ['shoulders', 'плечи'],
    'biceps': ['biceps', 'бицепс'],
    'triceps': ['triceps', 'трицепс'],
    'legs': ['legs', 'ноги'],
    'core': ['core', 'пресс'],
    'calves': ['calves', 'икры'],
    'forearms': ['forearms', 'предплечья'],
    'arms': ['arms', 'руки'],
    'posture': ['posture', 'осанка'],
    'balance': ['balance', 'баланс'],
    'breathing': ['breathing', 'дыхание'],
    'flexibility': ['flexibility', 'гибкость'],
    'joints': ['joints', 'суставы'],
    'relaxation': ['relaxation', 'релаксация', 'расслабление'],
    'massage': ['massage', 'массаж'],
    'strengthening': ['strengthening', 'укрепление'],
    'sensory': ['sensory', 'сенсорика'],
    'coordination': ['coordination', 'координация'],
    'development': ['development', 'развитие'],
    'water': ['water', 'водные процедуры'],
  };

  bool _matchesMuscleGroup(TrainerWorkout workout, String groupId) {
    final aliases = _muscleGroupAliases[groupId] ?? [groupId];
    return workout.muscleGroups.any((muscleGroup) {
      final normalized = muscleGroup.toLowerCase();
      return aliases.any((alias) => normalized == alias.toLowerCase());
    });
  }

  Widget _buildTrackingSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отслеживание',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTrackingItem(
              context,
              'Выпить воды',
              'Стакан воды (250мл)',
              Icons.local_drink,
              () async {
                try {
                  await SupabaseService().logWaterIntake(250);
                  ProgressService.addWaterIntake();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Стакан воды добавлен')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка записи воды: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            _buildTrackingItem(
              context,
              'Добавить шаги',
              '1000 шагов',
              Icons.directions_walk,
              () async {
                try {
                  await SupabaseService().logSteps(1000);
                  ProgressService.addSteps(1000);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('1000 шагов добавлено')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка записи шагов: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.add),
      onTap: onTap,
    );
  }

  // Заменяем тестовые URL на рабочие YouTube ссылки
  String _getWorkingVideoUrl(String originalUrl) {
    // Если это тестовый URL, заменяем на реальные YouTube видео
    if (originalUrl.contains('example.com')) {
      // Реальные YouTube видео для фитнеса
      final demoUrls = {
        'massage': 'https://www.youtube.com/watch?v=j1Ia2rM_UvI', 
        'gymnastics': 'https://www.youtube.com/watch?v=VHG2c9h7t3E',
        'reflexes': 'https://www.youtube.com/watch?v=KXKjGqZjKkM', 
        'water': 'https://www.youtube.com/watch?v=0hP1KvQz1k8', 
        'chest': 'https://www.youtube.com/watch?v=IODxDxX7oi4',
        'back': 'https://www.youtube.com/watch?v=eGo4IYlbE5g', 
      };
      
      // Ищем ключевые слова в URL и возвращаем соответствующее видео
      for (final key in demoUrls.keys) {
        if (originalUrl.contains(key)) {
          return demoUrls[key]!;
        }
      }
      return demoUrls['massage']!;
    }
    
    return originalUrl;
  }

  void _showVideoPlayer(BuildContext context, ExerciseVideo video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerWidget(video: video),
      ),
    );
  }

  void _showCreateWorkoutDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final videoUrlController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    String selectedAgeGroup = 'young';
    String selectedMuscleGroup = '';
    String selectedDifficulty = 'beginner';
    Future<List<SupabaseMuscleGroup>> muscleGroupsFuture = SupabaseService()
        .getMuscleGroups(_getDatabaseMuscleCategory(selectedAgeGroup));

    void refreshMuscleGroups(StateSetter setState, String ageGroup) {
      setState(() {
        selectedAgeGroup = ageGroup;
        selectedMuscleGroup = '';
        muscleGroupsFuture = SupabaseService().getMuscleGroups(_getDatabaseMuscleCategory(ageGroup));
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Создать тренировку'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название тренировки',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: videoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Ссылка на видео',
                    border: OutlineInputBorder(),
                    hintText: 'https://www.youtube.com/watch?v=...',
                    helperText: 'Поддерживаются YouTube, Rutube, MP4 ссылки',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: const InputDecoration(
                          labelText: 'Длительность (минут)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedDifficulty,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'beginner', child: Text('Начальный')),
                          DropdownMenuItem(value: 'intermediate', child: Text('Средний')),
                          DropdownMenuItem(value: 'advanced', child: Text('Продвинутый')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedDifficulty = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Возрастная группа:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedAgeGroup,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'infants', child: Text('Младенцы')),
                    DropdownMenuItem(value: 'pregnant', child: Text('Беременные')),
                    DropdownMenuItem(value: 'young', child: Text('Молодежь')),
                    DropdownMenuItem(value: 'senior', child: Text('Взрослые')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    refreshMuscleGroups(setState, value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Группа мышц:', style: TextStyle(fontWeight: FontWeight.bold)),
                FutureBuilder<List<SupabaseMuscleGroup>>(
                  future: muscleGroupsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Ошибка загрузки групп: ${snapshot.error}'),
                      );
                    }

                    final groups = snapshot.data ?? [];
                    if (groups.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('В выбранной категории нет групп мышц в базе.'),
                      );
                    }

                    if (selectedMuscleGroup.isEmpty) {
                      selectedMuscleGroup = groups.first.name;
                    }

                    return DropdownButton<String>(
                      value: selectedMuscleGroup,
                      isExpanded: true,
                      items: groups.map((group) {
                        return DropdownMenuItem(
                          value: group.name,
                          child: Text(group.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedMuscleGroup = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Заполните название и описание')),
                    );
                    return;
                  }

                  final durationValue = int.tryParse(durationController.text);
                  if (durationValue == null || durationValue <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Введите корректное время тренировки: целое число больше 0')),
                    );
                    return;
                  }

                  if (selectedMuscleGroup.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Выберите группу мышц для выбранной категории.')),
                    );
                    return;
                  }

                  final videoUrl = videoUrlController.text.trim();
                  if (videoUrl.isNotEmpty) {
                    final rutubePattern = RegExp(r'^https?://(www\.)?rutube\.ru/');
                    if (!rutubePattern.hasMatch(videoUrl)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ссылка должна быть ссылкой RuTube и начинаться с https://rutube.ru/')),
                      );
                      return;
                    }
                  }

                  final workoutData = {
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'difficulty': selectedDifficulty,
                    'duration': durationValue,
                    'muscle_groups': [selectedMuscleGroup],
                    'equipment': [],
                    'is_published': true,
                  };

                  if (videoUrlController.text.trim().isNotEmpty) {
                    workoutData['video_url'] = videoUrlController.text.trim();
                  }

                  await SupabaseService().createTrainerWorkout(workoutData);
                  Navigator.of(dialogContext).pop();
                } catch (e, stackTrace) {
                  print('Ошибка создания тренировки: $e');
                  print('Stack trace: $stackTrace');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка создания тренировки: $e')),
                  );
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }
}
