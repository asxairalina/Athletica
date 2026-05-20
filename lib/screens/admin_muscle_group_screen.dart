import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';

class AdminMuscleGroupScreen extends StatefulWidget {
  const AdminMuscleGroupScreen({super.key});

  @override
  State<AdminMuscleGroupScreen> createState() => _AdminMuscleGroupScreenState();
}

class _AdminMuscleGroupScreenState extends State<AdminMuscleGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController(text: '#2196f3');
  final _exercisesController = TextEditingController();
  String _selectedCategory = 'infants';
  String _selectedIcon = 'fitness_center';
  bool _isLoading = false;

  final Map<String, String> _categoryLabels = {
    'infants': 'Младенцы',
    'basic': 'Беременные',
    'standard': 'Молодежь',
    'gentle': 'Взрослые',
  };

  final Map<String, String> _iconOptions = {
    'fitness_center': 'Фитнес',
    'spa': 'Массаж',
    'child_care': 'Ребенок',
    'psychology': 'Психология',
    'pool': 'Пловец',
    'accessibility': 'Доступность',
    'favorite': 'Любимая',
    'accessibility_new': 'Новый доступ',
    'balance': 'Баланс',
  };

  String _getCategoryLabel(String key) => _categoryLabels[key] ?? key;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final color = _colorController.text.trim();
    final exercises = _exercisesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService().createMuscleGroup({
        'name': name,
        'description': description,
        'category': _selectedCategory,
        'icon': _selectedIcon,
        'color': color,
        'exercises': exercises,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Группа мышц успешно создана')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания группы: $e')),
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
        title: const Text('Создать группу мышц'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название группы',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название группы';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Возрастная категория',
                    border: OutlineInputBorder(),
                  ),
                  items: _categoryLabels.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedIcon,
                  decoration: const InputDecoration(
                    labelText: 'Иконка группы',
                    border: OutlineInputBorder(),
                  ),
                  items: _iconOptions.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedIcon = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Цвет (HEX)',
                    helperText: 'Например #2196f3',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите цвет';
                    }
                    final normalized = value.trim();
                    final hexMatch = RegExp(r'^#([A-Fa-f0-9]{6})$');
                    if (!hexMatch.hasMatch(normalized)) {
                      return 'Введите цвет в формате #RRGGBB';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _exercisesController,
                  decoration: const InputDecoration(
                    labelText: 'Упражнения',
                    helperText: 'Через запятую, например: Приседания, Планка',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Создать группу'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
