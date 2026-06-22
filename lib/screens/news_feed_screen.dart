import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/app_messenger.dart';
import '../utils/avatar_picker.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final posts = await _supabase.getNewsPosts();
      // mark which posts are liked by current user
      final postIds = posts.map((p) => p['id'] as String?).whereType<String>().toList();
      final likedSet = await SupabaseService().getLikedPostIdsForCurrentUser(postIds);
      for (final p in posts) {
        p['_liked'] = likedSet.contains(p['id']);
      }
      setState(() {
        _posts = posts;
      });
    } catch (e) {
      // ignore errors for now
    } finally {
      setState(() => _loading = false);
    }
  }

  bool get _supportsNativeCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _showNewsImageOptions(Future<void> Function() onGallery, Future<void> Function() onCamera) async {
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
                onGallery();
              },
            ),
            if (_supportsNativeCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  onCamera();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickNewsImageFromFiles(Future<void> Function(Uint8List, String?) uploadCallback) async {
    try {
      final picked = await pickAvatarFromGallery();
      if (picked == null) return;
      await uploadCallback(Uint8List.fromList(picked.bytes), picked.fileName);
    } catch (e) {
      if (mounted) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Не удалось выбрать изображение: $e')),
        );
      }
    }
  }

  Future<void> _pickNewsImageFromCamera(Future<void> Function(Uint8List, String?) uploadCallback) async {
    try {
      final picked = await pickAvatarFromCamera();
      if (picked == null) return;
      await uploadCallback(Uint8List.fromList(picked.bytes), picked.fileName);
    } catch (e) {
      if (mounted) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Камера недоступна. Выберите фото из галереи: $e')),
        );
      }
    }
  }

  Future<String?> _uploadNewsImageBytes(Uint8List bytes, String? fileName) async {
    try {
      final url = await SupabaseService().uploadNewsImage(
        bytes: bytes,
        fileName: fileName ?? 'news_image.png',
      );
      return url;
    } catch (e) {
      if (mounted) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Ошибка загрузки изображения: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _toggleLike(String postId) async {
    try {
      final idx = _posts.indexWhere((p) => p['id'] == postId);
      if (idx == -1) return;
     
      bool liked = _posts[idx]['_liked'] ?? await SupabaseService().userHasLikedPost(postId);

      setState(() {
        _posts[idx]['_liked'] = !liked;
        final count = (_posts[idx]['like_count'] ?? 0) as int;
        _posts[idx]['like_count'] = liked ? (count - 1) : (count + 1);
      });

      await _supabase.toggleLikeOnNews(postId);
    } catch (e) {
      appScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Ошибка постановки лайка')));
      await _loadPosts();
    }
  }

  Future<void> _addComment(String postId) async {
    await _showComments(postId);
  }

  Future<void> _showComments(String postId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final commentController = TextEditingController();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _supabase.getNewsComments(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Нет комментариев')));
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          final author = (c['users'] as Map<String, dynamic>?)?['name'] ?? 'Пользователь';
                          final avatar = (c['users'] as Map<String, dynamic>?)?['avatar_path'] as String?;
                          final text = c['comment_text'] ?? '';
                          final createdAtRaw = c['created_at'];
                          DateTime? createdAtDt;
                          try {
                            if (createdAtRaw is DateTime) {
                              createdAtDt = createdAtRaw;
                            } else if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
                              createdAtDt = DateTime.tryParse(createdAtRaw);
                            }
                          } catch (_) {
                            createdAtDt = null;
                          }

                          String createdAtText = '';
                          if (createdAtDt != null) {
                            final d = createdAtDt.toLocal();
                            String two(int v) => v.toString().padLeft(2, '0');
                            createdAtText = '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
                          }

                          return ListTile(
                            leading: avatar != null && avatar.isNotEmpty
                                ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(author),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(text),
                                const SizedBox(height: 6),
                                if (createdAtText.isNotEmpty) Text(createdAtText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(hintText: 'Написать комментарий'),
                            onSubmitted: (value) async {
                              if (value.trim().isEmpty) return;
                              final navigator = Navigator.of(context);
                              try {
                                await _supabase.addNewsComment(postId, value.trim());
                                navigator.pop();
                                await _showComments(postId);
                              } catch (e) {
                                appScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Ошибка добавления комментария')));
                              }
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final v = commentController.text.trim();
                          if (v.isEmpty) return;
                          final navigator = Navigator.of(context);
                          try {
                            await _supabase.addNewsComment(postId, v);
                            navigator.pop();
                            await _showComments(postId);
                          } catch (e) {
                            appScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Ошибка добавления комментария')));
                          }
                        },
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    await _loadPosts();
  }

  Future<void> _createPost() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? pickedImageUrl;

    final res = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Создать пост'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Заголовок')),
                    const SizedBox(height: 8),
                    TextField(controller: bodyCtrl, decoration: const InputDecoration(hintText: 'Текст поста'), maxLines: 4),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.photo),
                            label: const Text('Добавить изображение'),
                            onPressed: () {
                              _showNewsImageOptions(
                                () async {
                                  await _pickNewsImageFromFiles((bytes, fileName) async {
                                    final url = await _uploadNewsImageBytes(bytes, fileName);
                                    if (url != null) {
                                      setState(() {
                                        pickedImageUrl = url;
                                      });
                                    }
                                  });
                                },
                                () async {
                                  await _pickNewsImageFromCamera((bytes, fileName) async {
                                    final url = await _uploadNewsImageBytes(bytes, fileName);
                                    if (url != null) {
                                      setState(() {
                                        pickedImageUrl = url;
                                      });
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pickedImageUrl != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                pickedImageUrl = null;
                              });
                            },
                            child: const Text('Удалить'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Создать')),
            ],
          );
        });
      },
    );

    if (res == true) {
      final title = titleCtrl.text.trim();
      final body = bodyCtrl.text.trim();
      if (title.isEmpty || body.isEmpty) return;
      try {
        final created = await _supabase.createNewsPost(title, body, imageUrl: pickedImageUrl);
        if (created != null) {
          if (created['is_published'] == true) {
            await _loadPosts();
          } else {
            setState(() {
              _posts.insert(0, created);
            });
          }
        } else {
          await _loadPosts();
        }
        appScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Пост успешно создан')));
      } catch (e) {
        print('news_feed: create post error: $e');
        final msg = e?.toString() ?? 'Неизвестная ошибка';
        appScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Ошибка создания поста: $msg')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? ListView(children: const [Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Постов нет')))])
                : ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final author = (post['users'] as Map<String, dynamic>?)?['name'] ?? 'Автор';
                      final likeCount = post['like_count'] ?? 0;
                      final commentCount = post['comment_count'] ?? 0;
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((post['image_url'] as String?)?.isNotEmpty ?? false)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      post['image_url'] as String,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              Text(post['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(post['content'] ?? ''),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Автор: $author'),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.thumb_up,
                                          color: (post['_liked'] ?? false) ? Colors.blue : null,
                                        ),
                                        onPressed: () => _toggleLike(post['id'] as String),
                                      ),
                                      Text('$likeCount'),
                                      const SizedBox(width: 12),
                                      IconButton(icon: const Icon(Icons.comment), onPressed: () => _addComment(post['id'] as String)),
                                      Text('$commentCount'),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _supabase.currentUserIsTrainerOrAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
          final allowed = snapshot.data ?? false;
          if (!allowed) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _createPost,
            child: const Icon(Icons.create),
          );
        },
      ),
    );
  }
}
