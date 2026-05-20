import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final TrainerWorkout? workout;

  const CreateWorkoutScreen({super.key, this.workout});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  String _selectedDifficulty = 'beginner';
  String? _selectedAgeCategory;
  final Map<String, String> _ageCategoryLabels = {
    'infants': 'Младенцы',
    'basic': 'Беременные',
    'standard': 'Молодежь',
    'gentle': 'Взрослые',
  };
  List<String> _selectedMuscleGroups = [];
  List<String> _selectedEquipment = [];
  bool _isPublished = false;
  bool _isLoading = false;
  List<String> _invalidMuscleGroups = [];

  final List<String> _difficulties = ['beginner', 'intermediate', 'advanced'];
  List<String> _availableMuscleGroups = [];
  bool _isLoadingGroups = true;
  final List<String> _equipment = [
    'Штанга', 'Гантели', 'Гири', 'Тренажеры', 'Собственный вес', 'Резинки',
    'Скакалка', 'Турник', 'Брусья', 'Боксерская груша'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _loadWorkoutData();
      _determineCategoryForWorkout();
    }
  }

  Future<void> _loadAvailableMuscleGroups() async {
    try {
      if (_selectedAgeCategory == null) return;
      final groups = await SupabaseService().getMuscleGroups(_selectedAgeCategory!);
      if (mounted) {
        setState(() {
          _availableMuscleGroups = groups.map((g) => g.name).toList();
          _sanitizeSelectedMuscleGroups();
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableMuscleGroups = [];
          _isLoadingGroups = false;
        });
      }
      print('Ошибка загрузки групп мышц: $e');
    }
  }

  Future<void> _onAgeCategoryChanged(String? selectedCategory) async {
    if (selectedCategory == null || selectedCategory == _selectedAgeCategory) return;
    setState(() {
      _selectedAgeCategory = selectedCategory;
      _isLoadingGroups = true;
      _selectedMuscleGroups = []; 
    });
    await _loadAvailableMuscleGroups();
  }

  Future<void> _determineCategoryForWorkout() async {
    if (widget.workout == null) return;
    try {
      final allGroups = await SupabaseService().getAllMuscleGroups();
      final selected = widget.workout!.muscleGroups;
      final categories = <String>{};
      for (var g in allGroups) {
        if (selected.contains(g.name)) categories.add(g.category);
      }
      if (categories.length == 1) {
        _selectedAgeCategory = categories.first;
        _isLoadingGroups = true;
        await _loadAvailableMuscleGroups();
        _selectedMuscleGroups = _selectedMuscleGroups.where((s) => _availableMuscleGroups.contains(s)).toList();
      }
    } catch (e) {
      print('Ошибка определения категории тренировки: $e');
    }
  }

  void _loadWorkoutData() {
    final workout = widget.workout!;
    _titleController.text = workout.title;
    _descriptionController.text = workout.description;
    _durationController.text = workout.duration.toString();
    _videoUrlController.text = workout.videoUrl;
    _selectedDifficulty = workout.difficulty;
    _selectedMuscleGroups = List.from(workout.muscleGroups);
    _selectedEquipment = List.from(workout.equipment);
    _isPublished = workout.isPublished;
  }

  void _sanitizeSelectedMuscleGroups() {
    if (_availableMuscleGroups.isEmpty || _selectedMuscleGroups.isEmpty) {
      return;
    }

    final validGroups = _selectedMuscleGroups
        .where((group) => _availableMuscleGroups.contains(group))
        .toList();
    final invalidGroups = _selectedMuscleGroups
        .where((group) => !_availableMuscleGroups.contains(group))
        .toList();

    if (invalidGroups.isNotEmpty) {
      _invalidMuscleGroups = invalidGroups;
      _selectedMuscleGroups = validGroups;
    }
  }

  bool _validateSelectedMuscleGroups() {
    final invalidGroups = _selectedMuscleGroups
        .where((group) => !_availableMuscleGroups.contains(group))
        .toList();

    if (invalidGroups.isNotEmpty) {
      final invalidText = invalidGroups.join(', ');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Невозможно сохранить: группы мышц не найдены в базе ($invalidText)')),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedAgeCategory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пожалуйста, выберите возрастную категорию.')),
          );
          setState(() { _isLoading = false; });
        }
        return;
      }
      final selectedCategory = _selectedAgeCategory!;
      final allowedGroups = await SupabaseService().getMuscleGroups(selectedCategory);
      final allowedNames = allowedGroups.map((g) => g.name).toSet();

      final invalidSelected = _selectedMuscleGroups.where((g) => !allowedNames.contains(g)).toList();
      if (invalidSelected.isNotEmpty) {
        final invalidText = invalidSelected.join(', ');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Невозможно сохранить: выбранные группы не относятся к категории ($_selectedAgeCategory): $invalidText')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final workoutData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'difficulty': _selectedDifficulty,
        'duration': int.parse(_durationController.text),
        'muscle_groups': _selectedMuscleGroups.where((group) => allowedNames.contains(group)).toList(),
        'equipment': _selectedEquipment,
        'video_url': _videoUrlController.text.trim(),
        'is_published': _isPublished,
      };

      if (widget.workout == null) {
        await SupabaseService().createTrainerWorkout(workoutData);
      } else {
        await SupabaseService().updateTrainerWorkout(widget.workout!.id, workoutData);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'Создать тренировку' : 'Редактировать тренировку'),
        actions: [
          if (widget.workout != null)
            Switch(
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Название
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название тренировки',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название тренировки';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Сложность
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Сложность',
                  border: OutlineInputBorder(),
                ),
                items: _difficulties.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(_getDifficultyText(difficulty)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Длительность
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Длительность (минуты)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите длительность';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Введите корректную длительность';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ссылка на видео
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Ссылка на видео (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Возрастная категория
              DropdownButtonFormField<String>(
                value: _selectedAgeCategory,
                decoration: const InputDecoration(
                  labelText: 'Возрастная категория',
                  border: OutlineInputBorder(),
                ),
                items: _ageCategoryLabels.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: _onAgeCategoryChanged,
              ),
              const SizedBox(height: 24),

              // Группы мышц
              const Text(
                'Группы мышц:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_selectedAgeCategory == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Сначала выберите возрастную категорию.'),
                )
              else if (_isLoadingGroups)
                const Center(child: CircularProgressIndicator())
              else if (_availableMuscleGroups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('В выбранной категории нет доступных групп мышц.'),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableMuscleGroups.map((group) {
                    return FilterChip(
                      label: Text(group),
                      selected: _selectedMuscleGroups.contains(group),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedMuscleGroups.add(group);
                          } else {
                            _selectedMuscleGroups.remove(group);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Оборудование
              const Text(
                'Оборудование:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _equipment.map((item) {
                  return FilterChip(
                    label: Text(item),
                    selected: _selectedEquipment.contains(item),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEquipment.add(item);
                        } else {
                          _selectedEquipment.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Кнопка сохранения
              ElevatedButton(
                onPressed: _isLoading ? null : _saveWorkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.workout == null ? 'Создать тренировку' : 'Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
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
}
