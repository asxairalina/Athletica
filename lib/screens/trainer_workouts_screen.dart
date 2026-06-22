import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import '../models/exercise_video.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/video_player_widget.dart';
import 'create_workout_screen.dart';

class TrainerWorkoutsScreen extends StatefulWidget {
  const TrainerWorkoutsScreen({super.key});

  @override
  State<TrainerWorkoutsScreen> createState() => _TrainerWorkoutsScreenState();
}

class _TrainerWorkoutsScreenState extends State<TrainerWorkoutsScreen> {
  List<TrainerWorkout> _workouts = [];
  bool _isLoading = true;
  String? _error;
  int _ratingFilter = 0;
  int _durationFilterIndex = 0; 

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final workouts = await SupabaseService().getTrainerWorkouts(
        trainerId: user.id,
      );

      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TrainerWorkout> get _filteredWorkouts {
    var list = _workouts;
    if (_ratingFilter > 0) {
      list = list.where((workout) => workout.rating >= _ratingFilter).toList();
    }

    switch (_durationFilterIndex) {
      case 1:
        list = list.where((w) => w.duration < 15).toList();
        break;
      case 2:
        list = list.where((w) => w.duration >= 15 && w.duration <= 30).toList();
        break;
      case 3:
        list = list.where((w) => w.duration > 30 && w.duration <= 45).toList();
        break;
      case 4:
        list = list.where((w) => w.duration > 45).toList();
        break;
      default:
        break;
    }

    return list;
  }

  Future<void> _rateWorkout(TrainerWorkout workout, int rating) async {
    try {
      final updatedRating = await SupabaseService().rateTrainerWorkout(workout.id, rating);
      setState(() {
        _workouts = _workouts.map((item) {
          if (item.id != workout.id) return item;
          return item.copyWith(
            rating: updatedRating['rating'] as double,
            ratingCount: updatedRating['rating_count'] as int,
          );
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тренировка оценена: $rating ${rating == 1 ? 'звезда' : 'звезды'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения оценки: $e')),
        );
      }
    }
  }

  Widget _buildRatingFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Все'),
              selected: _ratingFilter == 0,
              onSelected: (_) {
                setState(() {
                  _ratingFilter = 0;
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
                  selected: _ratingFilter == value,
                  onSelected: (_) {
                    setState(() {
                      _ratingFilter = value;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationFilter() {
    final options = [
      'Все',
      '<15 мин',
      '15–30 мин',
      '30–45 мин',
      '>45 мин',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(options[index]),
                selected: _durationFilterIndex == index,
                onSelected: (_) {
                  setState(() {
                    _durationFilterIndex = index;
                  });
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _togglePublishStatus(TrainerWorkout workout) async {
    try {
      await SupabaseService().updateTrainerWorkout(workout.id, {
        'is_published': !workout.isPublished,
      });
      await _loadWorkouts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _deleteWorkout(TrainerWorkout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тренировку'),
        content: Text('Вы уверены, что хотите удалить тренировку "${workout.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService().deleteTrainerWorkout(workout.id);
        await _loadWorkouts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkouts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWorkouts,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _workouts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'У вас пока нет тренировок',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _navigateToCreateWorkout(),
                            child: const Text('Создать первую тренировку'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildRatingFilter(),
                        _buildDurationFilter(),
                        Expanded(
                          child: _filteredWorkouts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                        _noWorkoutsMessage(),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredWorkouts.length,
                                  itemBuilder: (context, index) {
                                    final workout = _filteredWorkouts[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: ListTile(
                                        title: Text(workout.title),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(workout.description),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                StarRating(
                                                  rating: workout.rating,
                                                  onRatingChanged: (rating) => _rateWorkout(workout, rating),
                                                ),
                                                Text(
                                                  workout.ratingCount > 0
                                                      ? '${workout.rating.toStringAsFixed(1)} (${workout.ratingCount})'
                                                      : 'Нет оценок',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Chip(
                                                  label: Text(_getDifficultyText(workout.difficulty)),
                                                  backgroundColor: _getDifficultyColor(workout.difficulty),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('${workout.duration} мин'),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  workout.isPublished ? Icons.public : Icons.lock,
                                                  size: 16,
                                                  color: workout.isPublished ? Colors.green : Colors.orange,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (workout.videoUrl.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.play_circle_outline, color: Colors.blue),
                                                tooltip: 'Смотреть видео',
                                                onPressed: () => _showVideoPlayer(context, workout),
                                              ),
                                            PopupMenuButton(
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Редактировать'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'publish',
                                                  child: Text(workout.isPublished ? 'Скрыть' : 'Опубликовать'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Удалить'),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'edit':
                                                    _navigateToEditWorkout(workout);
                                                    break;
                                                  case 'publish':
                                                    _togglePublishStatus(workout);
                                                    break;
                                                  case 'delete':
                                                    _deleteWorkout(workout);
                                                    break;
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: () => _navigateToEditWorkout(workout),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateWorkout(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, TrainerWorkout workout) {
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerWidget(video: video),
      ),
    );
  }

  void _navigateToCreateWorkout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateWorkoutScreen(),
      ),
    ).then((_) => _loadWorkouts());
  }

  void _navigateToEditWorkout(TrainerWorkout workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(workout: workout),
      ),
    ).then((_) => _loadWorkouts());
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Начинающий';
      case 'intermediate':
        return 'Средний';
      case 'advanced':
        return 'Продвинутый';
      default:
        return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green.withOpacity(0.2);
      case 'intermediate':
        return Colors.orange.withOpacity(0.2);
      case 'advanced':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  String _noWorkoutsMessage() {
    final ratingPart = _ratingFilter > 0 ? 'рейтинг ${_ratingFilter}+' : 'любой рейтинг';
    final durationPart = (() {
      switch (_durationFilterIndex) {
        case 1:
          return '<15 мин';
        case 2:
          return '15–30 мин';
        case 3:
          return '30–45 мин';
        case 4:
          return '>45 мин';
        default:
          return 'любой длительности';
      }
    })();

    return 'Нет тренировок с $ratingPart и длительностью $durationPart.';
  }
}
