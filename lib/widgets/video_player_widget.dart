import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:rutube_videoplayer/rutube_videoplayer.dart';
import '../models/exercise_video.dart';
import '../models/supabase_models.dart';
import '../services/supabase_service.dart';
import '../services/progress_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final ExerciseVideo video;

  const VideoPlayerWidget({super.key, required this.video});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFullScreen = false;
  String _playerType = ''; // 'youtube', 'rutube', 'video'
  String _rutubeUrl = ''; // Для RuTube URL


  // Система учета тренировок
  final Stopwatch _workoutStopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _workoutStarted = false;
  int _elapsedSeconds = 0;
  bool _workoutSaved = false;
  bool _youtubeReady = false;

  final TextEditingController _commentController = TextEditingController();
  final List<WorkoutComment> _comments = [];
  int _commentPage = 1;
  static const int _commentsPageSize = 10;
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  String _commentError = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadComments();
  }

  void _initializePlayer() {
    final rawUrl = widget.video.videoUrl;
    final url = _extractUrlFromEmbedCode(rawUrl);

    if (url.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Ссылка на видео отсутствует';
        _isLoading = false;
      });
      return;
    }

    if (_isYouTubeUrl(url)) {
      _playerType = 'youtube';
      _initYouTubePlayer(url);
    } else if (_isRuTubeUrl(url)) {
      _playerType = 'rutube';
      _initRuTubePlayer(url);
    } else if (url.contains('http')) {
      _playerType = 'video';
      _initVideoPlayer(url);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Неподдерживаемый формат видео';
        _isLoading = false;
      });
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  bool _isRuTubeUrl(String url) {
    return url.contains('rutube.ru');
  }

  String _extractUrlFromEmbedCode(String rawUrl) {
    final iframeRegex = RegExp(r'src="([^"]+)"');
    final match = iframeRegex.firstMatch(rawUrl);
    if (match != null) {
      return match.group(1)!;
    }
    return rawUrl.trim();
  }

  String? _extractRuTubeId(String url) {
    // Извлечение ID из ссылки вроде https://rutube.ru/play/embed/5b446ec7276c03730210cc64c37833f0
    final RegExp regex = RegExp(r'rutube\.ru/(?:play/embed/|video/)?([a-f0-9]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  void _initYouTubePlayer(String url) {
    String? videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null || videoId.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Не удалось извлечь ID YouTube видео';
        _isLoading = false;
      });
      return;
    }

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        showLiveFullscreenButton: true,
      ),
    );

    _youtubeController!.addListener(() {
      if (_youtubeController!.value.isReady && !_youtubeReady) {
        setState(() => _youtubeReady = true);
      }
    });

    setState(() {
      _isLoading = false;
      _isPlaying = true;
    });
  }

  void _initRuTubePlayer(String url) {
    String? rutubeId = _extractRuTubeId(url);
    if (rutubeId == null || rutubeId.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Не удалось извлечь ID RuTube видео';
        _isLoading = false;
      });
      return;
    }

    _rutubeUrl = 'https://rutube.ru/video/$rutubeId/';

    setState(() {
      _isLoading = false;
      _isPlaying = true;
    });
  }

  Future<void> _initVideoPlayer(String url) async {
    try {
      print('Initializing video player for URL: $url');
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: true,
        ),
      );

      _videoController!.addListener(_onVideoPlayerUpdate);

      await _videoController!.initialize().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Видео не загрузилось за 10 секунд. Возможно, проблема с CORS или ссылка недоступна.');
        },
      );

      print('Video initialized successfully, duration: ${_videoController!.value.duration}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });
        _videoController!.play();
      }
    } on TimeoutException catch (e) {
      _videoController?.removeListener(_onVideoPlayerUpdate);
      _videoController?.dispose();
      _videoController = null;
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message ?? 'Превышено время ожидания загрузки видео';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Video init error: $e');
      _videoController?.removeListener(_onVideoPlayerUpdate);
      _videoController?.dispose();
      _videoController = null;
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Ошибка загрузки видео: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onVideoPlayerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _saveWorkoutOnExit();
    _uiTimer?.cancel();
    _workoutStopwatch.stop();
    _commentController.dispose();
    _videoController?.removeListener(_onVideoPlayerUpdate);
    _videoController?.dispose();
    _youtubeController?.dispose();
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _saveWorkoutOnExit() async {
    if (_workoutSaved) return;
    _workoutSaved = true;

    final duration = _workoutStopwatch.elapsed;
    if (duration.inSeconds < 10) return; // Минимум 10 секунд для засчета

    try {
      await SupabaseService().logWorkout({
        'workout_type': widget.video.title,
        'muscle_group': widget.video.difficulty,
        'duration': duration.inSeconds,
        'experience': duration.inMinutes > 0 ? duration.inMinutes : 1,
        'calories': _estimateCalories(duration),
      });

      ProgressService.completeWorkout(duration: duration);

      if (duration.inMinutes >= 60) {
        ProgressService.completeLongWorkout();
      }
    } catch (e) {
      print('Error saving workout log: $e');
    }
  }

  int _estimateCalories(Duration duration) {
    // Базовая оценка: ~5-8 ккал в минуту в зависимости от интенсивности
    final diff = widget.video.difficulty.toLowerCase();
    int kcalPerMinute;
    if (diff == 'advanced' || diff == 'продвинутый') {
      kcalPerMinute = 8;
    } else if (diff == 'intermediate' || diff == 'средний') {
      kcalPerMinute = 6;
    } else {
      kcalPerMinute = 5;
    }
    return duration.inMinutes * kcalPerMinute;
  }

  Future<void> _loadComments({int page = 1}) async {
    setState(() {
      _isLoadingComments = true;
      _commentError = '';
    });

    try {
      final comments = await SupabaseService().getWorkoutComments(
        widget.video.id,
        page: page,
        pageSize: _commentsPageSize,
      );
      setState(() {
        _commentPage = page;
        _comments.clear();
        _comments.addAll(comments);
      });
    } catch (e) {
      setState(() {
        _commentError = 'Ошибка загрузки комментариев';
      });
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
      _commentError = '';
    });

    try {
      await SupabaseService().createWorkoutComment(widget.video.id, text);
      _commentController.clear();
      await _loadComments(page: 1);
    } catch (e) {
      setState(() {
        _commentError = 'Не удалось отправить комментарий: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  Future<void> _finishWorkout() async {
    if (!_workoutStarted) return;
    _uiTimer?.cancel();
    _workoutStopwatch.stop();

    await _saveWorkoutOnExit();

    setState(() {
      _workoutStarted = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тренировка сохранена')),
      );
    }
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Комментарии',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingComments)
          Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        else if (_commentError.isNotEmpty)
          Text(
            _commentError,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          )
        else if (_comments.isEmpty)
          Text(
            'Пока нет комментариев. Оставьте первый!',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.75)),
          )
        else
          Column(
            children: _comments.map((comment) {
              final author = comment.userName ?? comment.userId;
              final created = comment.createdAt.toLocal();
              final createdAtText = '${created.day.toString().padLeft(2, '0')}.${created.month.toString().padLeft(2, '0')} ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          author,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          createdAtText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.text,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.9)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Новый комментарий',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmittingComment ? null : _postComment,
                child: _isSubmittingComment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Отправить'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startWorkout() {
    if (_workoutStarted) return;
    setState(() {
      _workoutStarted = true;
    });
    _workoutStopwatch.start();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = _workoutStopwatch.elapsed.inSeconds;
        });
      }
    });

    // Запускаем видео если не играет (YouTube autoPlay уже true)
    try {
      if (_videoController != null && _videoController!.value.isInitialized && !_videoController!.value.isPlaying) {
        _videoController!.play();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      print('Error starting video playback: $e');
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
          if (_workoutStarted) _workoutStopwatch.stop();
        } else {
          _videoController!.play();
          _isPlaying = true;
          if (_workoutStarted) _workoutStopwatch.start();
        }
      });
    } else if (_youtubeController != null) {
      if (_isPlaying) {
        _youtubeController!.pause();
        if (_workoutStarted) _workoutStopwatch.stop();
      } else {
        _youtubeController!.play();
        if (_workoutStarted) _workoutStopwatch.start();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        await _saveWorkoutOnExit();
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isFullScreen && _videoController != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildVideoControls(),
              ),
              if (_workoutStarted)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                  onPressed: _toggleFullScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () async {
            await _saveWorkoutOnExit();
            if (mounted) Navigator.of(context).pop();
          },
        ),
        backgroundColor: surfaceColor,
        title: Text(
          widget.video.title,
          style: theme.textTheme.titleMedium?.copyWith(color: onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: onSurface),
        actions: [
          if ((_videoController != null && _videoController!.value.isInitialized) ||
              _youtubeController != null)
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: onSurface,
              ),
              onPressed: _togglePlayPause,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Загрузка видео...',
                    style: theme.textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                            _initializePlayer();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _getAspectRatio(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPlayer(),
                          if (_videoController != null &&
                              _videoController!.value.isInitialized &&
                              !_videoController!.value.isPlaying &&
                              _videoController!.value.position == Duration.zero)
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (_workoutStarted)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_videoController != null && _videoController!.value.isInitialized)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _toggleFullScreen,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_videoController != null && _videoController!.value.isInitialized)
                      _buildVideoControls(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _workoutStarted ? theme.colorScheme.error : theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              onPressed: _workoutStarted ? _finishWorkout : _startWorkout,
                              icon: Icon(
                                _workoutStarted ? Icons.check : Icons.play_arrow,
                                color: theme.colorScheme.onPrimary,
                              ),
                              label: Text(
                                _workoutStarted ? 'Завершить тренировку' : 'Начать тренировку',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.video.title,
                              style: theme.textTheme.headlineSmall?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.video.description,
                              style: theme.textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    widget.video.difficulty,
                                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${(widget.video.duration ~/ 60)}:${(widget.video.duration % 60).toString().padLeft(2, '0')}',
                                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (widget.video.instructions.isNotEmpty) ...[
                              Text(
                                'Инструкции:',
                                style: theme.textTheme.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...widget.video.instructions.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${entry.key + 1}',
                                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: theme.textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            const SizedBox(height: 24),
                            _buildCommentsSection(theme),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  double _getAspectRatio() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return _videoController!.value.aspectRatio;
    }
    return 16 / 9;
  }

  Widget _buildPlayer() {
    if (_youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          print('YouTube player is ready');
        },
      );
    } else if (_playerType == 'rutube' && _rutubeUrl.isNotEmpty) {
      return RutubeVideoPlayer(
        videoUrl: _rutubeUrl,
      );
    } else if (_videoController != null && _videoController!.value.isInitialized) {
      return VideoPlayer(_videoController!);
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
  }

  Widget _buildVideoControls() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final newPosition = _videoController!.value.position - const Duration(seconds: 10);
                  _videoController!.seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
                },
              ),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final newPosition = _videoController!.value.position + const Duration(seconds: 10);
                  final duration = _videoController!.value.duration;
                  _videoController!.seekTo(newPosition < duration ? newPosition : duration);
                },
              ),
              IconButton(
                icon: Icon(
                  _videoController!.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  _videoController!.setVolume(_videoController!.value.volume > 0 ? 0 : 1);
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}