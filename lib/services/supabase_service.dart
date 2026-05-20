import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_level.dart';
import '../models/daily_task.dart';
import '../models/muscle_group.dart';
import '../models/exercise_video.dart';
import '../models/supabase_models.dart';
import '../config/supabase_config.dart';
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _supabase;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      print('Initializing SupaBase service...');
      
      _supabase = Supabase.instance.client;
      _isInitialized = true;
      
      print('SupaBase service initialized successfully');
      
    } catch (e) {
      print('SupaBase service initialization error: $e');
      print('URL: ${SupabaseConfig.supabaseUrl}');
      print('Key starts with eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9: ${SupabaseConfig.supabaseAnonKey.startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')}');
      
      rethrow;
    }
  }

  SupabaseClient get client {
    if (!_isInitialized) {
      try {
        final instance = Supabase.instance;
        _supabase = instance.client;
        _isInitialized = true;
        print('SupabaseService auto-initialized');
      } catch (e) {
        throw Exception(
          'Supabase не инициализирован. Перезапустите приложение (не hot reload). Ошибка: $e',
        );
      }
    }
    return _supabase;
  }

  bool get isInitialized => _isInitialized;

  // Аутентификация
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Пользователи
  Future<UserProfile?> getCurrentUser() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final response = await client
          .from('users')
          .select()
          .eq('user_id', user.id)
          .single()
          .timeout(const Duration(seconds: 5));

      return response != null ? UserProfile.fromJson(response) : null;
    } catch (e) {
      print('Error getting current user: $e');
      // Если таблица users не существует или другая ошибка, возвращаем null
      return null;
    }
  }

  // Создание базового пользователя при регистрации
  Future<void> createBasicUser(
    String userId,
    String email, {
    String? name,
  }) async {
    try {
      await client.from('users').insert({
        'user_id': userId,
        'email': email,
        'name': (name != null && name.isNotEmpty) ? name : 'Пользователь',
        'age': 18,
        'gender': 'male',
        'height': 170.0,
        'weight': 70.0,
        'fitness_goal': 'general_fitness',
        'total_experience': 0,
        'current_level': 1,
        'profile_completed': false, // Профиль не завершен
        'role': 'user', // Базовая роль
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Basic user created successfully');
    } catch (e) {
      print('Error creating basic user: $e');
      rethrow;
    }
  }

  // Работа с ролями
  Future<void> updateUserRole(String userId, String role) async {
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут менять роли');
    }

    if (role != 'user' && role != 'trainer') {
      throw Exception(
        'Через приложение можно назначить только роли «пользователь» или «тренер». '
        'Роль администратора выдаётся в Supabase.',
      );
    }

    try {
      await client
          .from('users')
          .update({'role': role})
          .eq('user_id', userId);
      print('User role updated successfully');
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  Future<List<UserProfile>> getAllUsersForAdmin() async {
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут просматривать всех пользователей');
    }

    try {
      final response = await client
          .from('users')
          .select()
          .order('created_at', ascending: false) as List<dynamic>;

      final list = response.cast<Map<String, dynamic>>();
      final users = list.map((user) => UserProfile.fromJson(user)).toList();
      return users;
    } catch (e) {
      print('Error getting all users for admin: $e');
      rethrow;
    }
  }

  // Добавление опыта пользователю
  Future<void> addExperience(int experiencePoints) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final currentUser = await getCurrentUser();
      if (currentUser == null) throw Exception('Профиль пользователя не найден');

      final newExperience = currentUser.totalExperience + experiencePoints;
      final newLevel = (newExperience ~/ 100) + 1; // Каждые 100 XP - новый уровень

      await client
          .from('users')
          .update({
            'total_experience': newExperience,
            'current_level': newLevel,
          })
          .eq('user_id', user.id);

      print('Experience added: +$experiencePoints XP (Total: $newExperience, Level: $newLevel)');
    } catch (e) {
      print('Error adding experience: $e');
      rethrow;
    }
  }

  Future<List<UserProfile>> getUsersByRole(String role) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false) as List<dynamic>;

      final list = response.cast<Map<String, dynamic>>();
      return list.map((user) => UserProfile.fromJson(user)).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }

  // Тренерские тренировки
  Future<void> createTrainerWorkout(Map<String, dynamic> workoutData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что пользователь - тренер или администратор
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'trainer' && userProfile?.role != 'admin') {
      throw Exception('Только тренеры и администраторы могут создавать тренировки');
    }

    await client.from('trainer_workouts').insert({
      ...workoutData,
      'trainer_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<TrainerWorkout>> getTrainerWorkouts({String? trainerId, bool onlyPublished = false}) async {
    try {
      var query = client.from('trainer_workouts').select('*, users(name)');

      if (trainerId != null) {
        query = query.eq('trainer_id', trainerId);
      }

      if (onlyPublished) {
        query = query.eq('is_published', true);
      }

      final response = await query.order('created_at', ascending: false) as List<dynamic>;

      final List<Map<String, dynamic>> workoutsList;
      workoutsList = response.cast<Map<String, dynamic>>();

      return workoutsList.map((workout) => TrainerWorkout.fromJson(workout)).toList();
    } catch (e) {
      print('Error getting trainer workouts: $e');
      return [];
    }
  }

  Future<void> updateTrainerWorkout(String workoutId, Map<String, dynamic> workoutData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем роль пользователя
    final userProfile = await getCurrentUser();
    final isAdmin = userProfile?.role == 'admin';

    var query = client.from('trainer_workouts').select().eq('id', workoutId);
    
    // Если не администратор, проверяем, что это тренировка текущего тренера
    if (!isAdmin) {
      query = query.eq('trainer_id', user.id);
    }

    final workout = await query.single();

    if (workout == null) {
      throw Exception('Тренировка не найдена или нет прав доступа');
    }

    await client
        .from('trainer_workouts')
        .update({
          ...workoutData,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', workoutId);
  }

  Future<void> deleteTrainerWorkout(String workoutId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что это тренировка текущего тренера или админ
    final userProfile = await getCurrentUser();
    final isAdmin = userProfile?.role == 'admin';

    var query = client.from('trainer_workouts').delete().eq('id', workoutId);
    
    if (!isAdmin) {
      query = query.eq('trainer_id', user.id);
    }

    await query;
  }

  Future<void> createMuscleGroup(Map<String, dynamic> groupData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут создавать группы мышц');
    }

    await client.from('muscle_groups').insert({
      ...groupData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteMuscleGroup(String groupId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут удалять группы мышц');
    }

    try {
      await client.from('muscle_groups').delete().eq('id', groupId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUserProfile(Map<String, dynamic> userData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client
        .from('users')
        .update({
          ...userData,
          'profile_completed': true, // Профиль завершен
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client
        .from('users')
        .update({
          ...userData,
          'profile_completed': true, // Отмечаем профиль как завершенный
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  static const String avatarsBucket = 'avatars';

  String _avatarContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  String _normalizeAvatarExtension(String? rawName) {
    final name = rawName?.toLowerCase() ?? '';
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    if (name.endsWith('.gif')) return 'gif';
    return 'jpg';
  }

  /// Загружает фото в Storage и сохраняет публичный URL в users.avatar_path.
  Future<String> uploadUserAvatar({
    required Uint8List bytes,
    String? fileName,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final extension = _normalizeAvatarExtension(fileName);
    final storagePath = '${user.id}/avatar.$extension';

    await client.storage.from(avatarsBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: _avatarContentType(extension),
      ),
    );

    final publicUrl = client.storage.from(avatarsBucket).getPublicUrl(storagePath);
    await updateUserProfile({'avatar_path': publicUrl});
    return publicUrl;
  }

  /// Удаляет файл аватара и очищает avatar_path в профиле.
  Future<void> removeUserAvatar() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'gif']) {
      try {
        await client.storage.from(avatarsBucket).remove(['${user.id}/avatar.$ext']);
      } catch (_) {}
    }

    await client
        .from('users')
        .update({
          'avatar_path': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  // Тренеры
  Future<List<Trainer>> getTrainers() async {
    final response = await client
        .from('trainers')
        .select()
        .order('created_at', ascending: false) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((trainer) => Trainer.fromJson(trainer)).toList();
  }

  Future<Trainer?> getTrainer(String trainerId) async {
    final response = await client
        .from('trainers')
        .select()
        .eq('id', trainerId)
        .single();

    return response != null ? Trainer.fromJson(response) : null;
  }

  // Новости
  Future<List<News>> getNews({int limit = 10}) async {
    final response = await client
        .from('news')
        .select()
        .eq('is_published', true)
        .order('published_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((news) => News.fromJson(news)).toList();
  }

  Future<List<News>> getNewsByCategory(String category, {int limit = 10}) async {
    final response = await client
        .from('news')
        .select()
        .eq('is_published', true)
        .eq('category', category)
        .order('published_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((news) => News.fromJson(news)).toList();
  }

  Map<String, dynamic> _newsPayloadWithPublishDate(Map<String, dynamic> newsData) {
    final payload = Map<String, dynamic>.from(newsData);
    final isPublished = payload['is_published'] == true;
    if (isPublished) {
      payload['published_at'] ??= DateTime.now().toIso8601String();
    } else if (payload.containsKey('is_published') && !isPublished) {
      payload['published_at'] = null;
    }
    return payload;
  }

  // Администрирование новостей
  Future<void> createNews(Map<String, dynamic> newsData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что пользователь - администратор
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут создавать новости');
    }

    final payload = _newsPayloadWithPublishDate(newsData);
    await client.from('news').insert({
      ...payload,
      'author_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateNews(String newsId, Map<String, dynamic> newsData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что пользователь - администратор
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут редактировать новости');
    }

    final payload = _newsPayloadWithPublishDate(newsData);
    await client
        .from('news')
        .update({
          ...payload,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', newsId);
  }

  Future<void> deleteNews(String newsId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что пользователь - администратор
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут удалять новости');
    }

    await client.from('news').delete().eq('id', newsId);
  }

  Future<void> publishNews(String newsId) async {
    await updateNews(newsId, {
      'is_published': true,
      'published_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unpublishNews(String newsId) async {
    await updateNews(newsId, {
      'is_published': false,
      'published_at': null,
    });
  }

  Future<List<News>> getAllNews({bool includeUnpublished = false}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что пользователь - администратор
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'admin') {
      throw Exception('Только администраторы могут видеть все новости');
    }

    var query = client.from('news').select();
    if (!includeUnpublished) {
      query = query.eq('is_published', true);
    }

    final response = await query.order('created_at', ascending: false) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((news) => News.fromJson(news)).toList();
  }

  // Тренировочные программы
  Future<List<WorkoutProgram>> getWorkoutPrograms({String? category}) async {
    var query = client
        .from('workout_programs')
        .select()
        .eq('is_published', true);

    if (category != null) {
      query = query.eq('category', category);
    }

    final response = await query.order('created_at', ascending: false) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((program) => WorkoutProgram.fromJson(program)).toList();
  }

  Future<List<WorkoutProgram>> getTrainerPrograms(String trainerId) async {
    final response = await client
        .from('workout_programs')
        .select()
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((program) => WorkoutProgram.fromJson(program)).toList();
  }

  // Обновленные видео с тренерами
  Future<List<SupabaseExerciseVideo>> getExerciseVideosByTrainer(String trainerId) async {
    final response = await client
        .from('exercise_videos')
        .select()
        .eq('trainer_id', trainerId)
        .order('created_at', ascending: false) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((video) => SupabaseExerciseVideo.fromJson(video)).toList();
  }

  // Управление видео упражнениями для тренеров
  Future<void> createExerciseVideo(Map<String, dynamic> videoData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем, что пользователь - тренер или администратор
    final userProfile = await getCurrentUser();
    if (userProfile?.role != 'trainer' && userProfile?.role != 'admin') {
      throw Exception('Только тренеры и администраторы могут создавать видео упражнения');
    }

    await client.from('exercise_videos').insert({
      ...videoData,
      'trainer_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateExerciseVideo(String videoId, Map<String, dynamic> videoData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем роль пользователя
    final userProfile = await getCurrentUser();
    final isAdmin = userProfile?.role == 'admin';

    var query = client.from('exercise_videos').select().eq('id', videoId);
    
    // Если не администратор, проверяем, что это видео текущего тренера
    if (!isAdmin) {
      query = query.eq('trainer_id', user.id);
    }

    final video = await query.single();

    if (video == null) {
      throw Exception('Видео не найдено или нет прав доступа');
    }

    await client
        .from('exercise_videos')
        .update(videoData)
        .eq('id', videoId);
  }

  Future<void> deleteExerciseVideo(String videoId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Проверяем роль пользователя
    final userProfile = await getCurrentUser();
    final isAdmin = userProfile?.role == 'admin';

    var query = client.from('exercise_videos').select().eq('id', videoId);
    
    // Если не администратор, проверяем, что это видео текущего тренера
    if (!isAdmin) {
      query = query.eq('trainer_id', user.id);
    }

    final video = await query.single();

    if (video == null) {
      throw Exception('Видео не найдено или нет прав доступа');
    }

    await client.from('exercise_videos').delete().eq('id', videoId);
  }

  // Real-time подписки для новостей
  Stream<List<News>> subscribeToNews() {
    return client
        .from('news')
        .stream(primaryKey: ['id'])
        .eq('is_published', true)
        .order('published_at', ascending: false)
        .limit(10)
        .map((events) => events.map((event) => News.fromJson(event)).toList());
  }

  // Real-time подписки для тренировочных программ
  Stream<List<WorkoutProgram>> subscribeToWorkoutPrograms({String? category}) {
    var query = client
        .from('workout_programs')
        .stream(primaryKey: ['id'])
        .eq('is_published', true);

    if (category != null) {
      query = query.eq('category', category);
    }

    return query
        .order('created_at', ascending: false)
        .map((events) => events.map((event) => WorkoutProgram.fromJson(event)).toList());
  }

  // Ежедневные задания
  Future<List<SupabaseDailyTask>> getDailyTasks() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('daily_tasks')
        .select()
        .eq('user_id', user.id)
        .eq('date', todayStr) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((task) => SupabaseDailyTask.fromJson(task)).toList();
  }

  Future<void> updateTaskCompletion(String taskId, bool completed) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client
        .from('daily_tasks')
        .update({
          'completed': completed,
          'completed_at': completed ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', taskId)
        .eq('user_id', user.id);
  }

  // Прогресс тренировок
  Future<void> logWorkout(Map<String, dynamic> workoutData) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client.from('workout_logs').insert({
      'workout_type': workoutData['workout_type'] ?? 'Тренировка',
      'muscle_group': workoutData['muscle_group'],
      'duration': workoutData['duration'] ?? 0,
      'experience': workoutData['experience'] ?? 0,
      'calories': workoutData['calories'],
      'user_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWorkoutHistory({
    int limit = 30,
    DateTime? forDay,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    var query = client.from('workout_logs').select().eq('user_id', user.id);

    if (forDay != null) {
      final startLocal = DateTime(forDay.year, forDay.month, forDay.day);
      final endLocal = startLocal.add(const Duration(days: 1));
      query = query
          .gte('created_at', startLocal.toUtc().toIso8601String())
          .lt('created_at', endLocal.toUtc().toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;
    final rawList = response.cast<Map<String, dynamic>>();

    final parsedList = rawList.map((item) {
      final rawCreatedAt = item['created_at'];
      DateTime? createdAt;
      if (rawCreatedAt is String) {
        createdAt = DateTime.tryParse(rawCreatedAt);
      } else if (rawCreatedAt is DateTime) {
        createdAt = rawCreatedAt;
      }

      return {
        ...item,
        'created_at': createdAt ?? DateTime.now(),
        'duration': item['duration'] is String
            ? int.tryParse(item['duration'] as String) ?? 0
            : item['duration'] as int? ?? 0,
        'calories': item['calories'] is String
            ? int.tryParse(item['calories'] as String) ?? 0
            : item['calories'] as int? ?? 0,
        'experience': item['experience'] is String
            ? int.tryParse(item['experience'] as String) ?? 0
            : item['experience'] as int? ?? 0,
      };
    }).toList();
    return parsedList;
  }

  // Вес и прогресс
  Future<void> logWeight(double weight) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client.from('weight_logs').insert({
      'user_id': user.id,
      'weight': weight,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWeightHistory({int limit = 100}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final response = await client
        .from('weight_logs')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .limit(limit) as List<dynamic>;

    return response.cast<Map<String, dynamic>>().toList();
  }

  // Группы мышц и упражнения
  Future<List<SupabaseMuscleGroup>> getMuscleGroups(String category) async {
    final response = await client
        .from('muscle_groups')
        .select()
        .eq('category', category)
        .order('name', ascending: true) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((group) => SupabaseMuscleGroup.fromJson(group)).toList();
  }

  Future<List<SupabaseMuscleGroup>> getAllMuscleGroups() async {
    final response = await client
        .from('muscle_groups')
        .select()
        .order('name', ascending: true) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((group) => SupabaseMuscleGroup.fromJson(group)).toList();
  }

  Future<List<SupabaseExerciseVideo>> getExerciseVideos(String muscleGroupId) async {
    final response = await client
        .from('exercise_videos')
        .select()
        .eq('muscle_group_id', muscleGroupId)
        .order('created_at', ascending: false) as List<dynamic>;

    final list = response.cast<Map<String, dynamic>>();
    return list.map((video) => SupabaseExerciseVideo.fromJson(video)).toList();
  }

  // Статистика и аналитика
  Future<Map<String, dynamic>> getUserStats() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    // Получаем общую статистику
    final response = await client.rpc('get_user_stats', params: {
      'user_id_param': user.id,
    });

    return response ?? {};
  }

  // Стрик тренировок
  Future<int> getCurrentStreak() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final response = await client.rpc('get_current_streak', params: {
      'user_id_param': user.id,
    });

    return response ?? 0;
  }

  // Личные рекорды
  Future<List<Map<String, dynamic>>> getPersonalRecords() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final response = await client
        .from('personal_records')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false) as List<dynamic>;

    return response.cast<Map<String, dynamic>>().toList();
  }

  // Вода и шаги
  Future<void> logWaterIntake(int amount) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client.from('water_intake').insert({
      'user_id': user.id,
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logSteps(int steps) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    await client.from('step_logs').insert({
      'user_id': user.id,
      'steps': steps,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // Получение сегодняшнего прогресса
  Future<Map<String, dynamic>> getTodayProgress() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final response = await client.rpc('get_today_progress', params: {
      'user_id_param': user.id,
      'date_param': todayStr,
    });

    return response ?? {};
  }

  // Подписки на реальное время
  Stream<List<Map<String, dynamic>>> subscribeToWorkoutUpdates() {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    return client
        .from('workout_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> subscribeToTaskUpdates() {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return client
        .from('daily_tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .eq('date', todayStr);
  }
}
