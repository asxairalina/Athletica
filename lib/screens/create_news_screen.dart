import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';

class CreateNewsScreen extends StatefulWidget {
  final News? news;

  const CreateNewsScreen({super.key, this.news});

  @override
  State<CreateNewsScreen> createState() => _CreateNewsScreenState();
}

class _CreateNewsScreenState extends State<CreateNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isPublished = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'general',
    'fitness', 
    'nutrition',
    'tips',
    'events',
    'announcements'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.news != null) {
      _loadNewsData();
    }
  }

  void _loadNewsData() {
    final news = widget.news!;
    _titleController.text = news.title;
    _contentController.text = news.content;
    _selectedCategory = news.category;
    _isPublished = news.isPublished;
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newsData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'is_published': _isPublished,
      };

      if (widget.news == null) {
        await SupabaseService().createNews(newsData);
      } else {
        await SupabaseService().updateNews(widget.news!.id, newsData);
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
        title: Text(widget.news == null ? 'Создать новость' : 'Редактировать новость'),
        actions: [
          if (widget.news != null)
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
                  labelText: 'Заголовок новости',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок новости';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Категория
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryText(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Содержание
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Содержание новости',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите содержание новости';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Статус публикации (для новой новости)
              if (widget.news == null) ...[
                SwitchListTile(
                  title: const Text('Опубликовать сразу'),
                  subtitle: const Text('Если выключено, новость будет сохранена как черновик'),
                  value: _isPublished,
                  onChanged: (value) {
                    setState(() {
                      _isPublished = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Кнопка сохранения
              ElevatedButton(
                onPressed: _isLoading ? null : _saveNews,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.news == null ? 'Создать новость' : 'Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'general':
        return 'Общее';
      case 'fitness':
        return 'Фитнес';
      case 'nutrition':
        return 'Питание';
      case 'tips':
        return 'Советы';
      case 'events':
        return 'События';
      case 'announcements':
        return 'Объявления';
      default:
        return category;
    }
  }
}
