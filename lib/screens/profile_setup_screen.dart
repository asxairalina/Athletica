import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import '../main.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _selectedGender = 'male';
  String _selectedGoal = 'weight_loss';
  bool _isLoading = false;

  final List<Map<String, String>> _goals = [
    {'value': 'weight_loss', 'label': 'Похудение'},
    {'value': 'muscle_gain', 'label': 'Набор мышечной массы'},
    {'value': 'endurance', 'label': 'Выносливость'},
    {'value': 'flexibility', 'label': 'Гибкость'},
    {'value': 'general_fitness', 'label': 'Общая физическая форма'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Прямой доступ к Supabase
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован. Пожалуйста, войдите снова.');
      }

      final weight = double.parse(_weightController.text);

      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'height': double.parse(_heightController.text),
        'weight': weight,
        'fitness_goal': _selectedGoal,
        'profile_completed': true, // Отмечаем профиль как завершенный
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentUser.id);

      // График веса в аналитике читает weight_logs, не поле users.weight
      await SupabaseService().logWeight(weight);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения профиля: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Создание профиля'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Расскажите о себе',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Это поможет нам подобрать для вас лучшие тренировки',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Имя
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ваше имя',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Пожалуйста, введите имя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Возраст
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Возраст',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите возраст';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 10 || age > 120) {
                        return 'Введите корректный возраст (10-120)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Пол
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Пол',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Мужской'),
                                  value: 'male',
                                  groupValue: _selectedGender,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Женский'),
                                  value: 'female',
                                  groupValue: _selectedGender,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Рост и вес в одной строке
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Рост (см)',
                            prefixIcon: Icon(Icons.height),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите рост';
                            }
                            final height = double.tryParse(value);
                            if (height == null || height < 50 || height > 250) {
                              return 'Введите корректный рост';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Вес (кг)',
                            prefixIcon: Icon(Icons.monitor_weight),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите вес';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null || weight < 20 || weight > 300) {
                              return 'Введите корректный вес';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Цель тренировок
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ваша цель',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._goals.map((goal) => RadioListTile<String>(
                            title: Text(goal['label']!),
                            value: goal['value']!,
                            groupValue: _selectedGoal,
                            onChanged: (value) {
                              setState(() {
                                _selectedGoal = value!;
                              });
                            },
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Кнопка сохранения
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Сохранить профиль',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
