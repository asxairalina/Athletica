import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import 'create_news_screen.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  List<News> _news = [];
  bool _isLoading = true;
  bool _showUnpublished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final news = await SupabaseService().getAllNews(
        includeUnpublished: _showUnpublished,
      );

      setState(() {
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePublishStatus(News news) async {
    try {
      if (news.isPublished) {
        await SupabaseService().unpublishNews(news.id);
      } else {
        await SupabaseService().publishNews(news.id);
      }
      await _loadNews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _deleteNews(News news) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить новость'),
        content: Text('Вы уверены, что хотите удалить новость "${news.title}"?'),
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
        await SupabaseService().deleteNews(news.id);
        await _loadNews();
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
        title: const Text('Управление новостями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_unpublished',
                child: Text(_showUnpublished ? 'Скрыть черновики' : 'Показать черновики'),
              ),
            ],
            onSelected: (value) {
              if (value == 'toggle_unpublished') {
                setState(() {
                  _showUnpublished = !_showUnpublished;
                });
                _loadNews();
              }
            },
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
                        onPressed: _loadNews,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _news.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Новостей пока нет',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _navigateToCreateNews(),
                            child: const Text('Создать первую новость'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _news.length,
                      itemBuilder: (context, index) {
                        final news = _news[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            title: Text(news.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(news.category),
                                      backgroundColor: _getCategoryColor(news.category),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      news.isPublished ? Icons.visibility : Icons.visibility_off,
                                      size: 16,
                                      color: news.isPublished ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      news.isPublished ? 'Опубликовано' : 'Черновик',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: news.isPublished ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Создано: ${_formatDate(news.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: const Text('Редактировать'),
                                ),
                                PopupMenuItem(
                                  value: 'publish',
                                  child: Text(news.isPublished ? 'Скрыть' : 'Опубликовать'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: const Text('Удалить'),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _navigateToEditNews(news);
                                    break;
                                  case 'publish':
                                    _togglePublishStatus(news);
                                    break;
                                  case 'delete':
                                    _deleteNews(news);
                                    break;
                                }
                              },
                            ),
                            onTap: () => _navigateToEditNews(news),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateNews(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateNews() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateNewsScreen(),
      ),
    ).then((_) => _loadNews());
  }

  void _navigateToEditNews(News news) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateNewsScreen(news: news),
      ),
    ).then((_) => _loadNews());
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'fitness':
        return Colors.blue.withOpacity(0.2);
      case 'nutrition':
        return Colors.green.withOpacity(0.2);
      case 'tips':
        return Colors.orange.withOpacity(0.2);
      case 'events':
        return Colors.purple.withOpacity(0.2);
      case 'announcements':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}
