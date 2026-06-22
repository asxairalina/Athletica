import 'dart:async';
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

  Future<Map<String, dynamic>> rateTrainerWorkout(String workoutId, int rating) async {
    try {
      final existing = await client
          .from('trainer_workouts')
          .select('rating, rating_count')
          .eq('id', workoutId)
          .single() as Map<String, dynamic>?;

      if (existing == null) {
        throw Exception('Тренировка не найдена');
      }

      final currentRating = (existing['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = existing['rating_count'] as int? ?? 0;
      final newCount = currentCount + 1;
      final newRating = ((currentRating * currentCount) + rating) / newCount;

      await client.from('trainer_workouts').update({
        'rating': newRating,
        'rating_count': newCount,
      }).eq('id', workoutId);

      return {
        'rating': newRating,
        'rating_count': newCount,
      };
    } catch (e) {
      print('Error rating trainer workout: $e');
      rethrow;
    }
  }

  Future<List<WorkoutComment>> getWorkoutComments(String workoutId, {int page = 1, int pageSize = 10}) async {
    try {
      final start = (page - 1) * pageSize;
      final end = start + pageSize - 1;
      final response = await client
          .from('workout_comments')
          .select('*, users(name, avatar_path)')
          .eq('workout_id', workoutId)
          .order('created_at', ascending: false)
          .range(start, end) as List<dynamic>;

      return response
          .cast<Map<String, dynamic>>()
          .map((comment) => WorkoutComment.fromJson(comment))
          .toList();
    } catch (e) {
      print('Error getting workout comments: $e');
      return [];
    }
  }

  Future<void> createWorkoutComment(String workoutId, String commentText) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      await client.from('workout_comments').insert({
        'workout_id': workoutId,
        'user_id': currentUser.id,
        'comment_text': commentText,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating workout comment: $e');
      rethrow;
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
  static const String newsBucket = 'news';

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

  String _contentTypeFromExtension(String extension) {
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

  Future<String> uploadNewsImage({required Uint8List bytes, required String fileName}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final ext = fileName.split('.').last;
    final storagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from(newsBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: _contentTypeFromExtension(ext),
      ),
    );

    final publicUrl = client.storage.from(newsBucket).getPublicUrl(storagePath);
    return publicUrl;
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

  Future<List<UserProfile>> getAllTrainers() async {
    try {
      // Always fetch trainers from public.users. Trainers are authoritative in public.users.
      final resp = await client.from('users').select().eq('role', 'trainer').order('created_at', ascending: false) as List<dynamic>;
      final data = resp.cast<Map<String, dynamic>>();
      print('getAllTrainers: returning ${data.length} trainers from public.users');
      return data.map((e) => UserProfile.fromJson(e)).toList();
    
    } catch (e) {
      print('Error fetching trainers: $e');
      return [];
    }
  }

  Future<UserProfile?> getUserById(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response != null ? UserProfile.fromJson(response) : null;
  }

  /// Fallback: try to load basic profile from `auth.users` if `public.users` row is missing.
  Future<UserProfile?> getUserProfileFromAuth(String userId) async {
    try {
      final resp = await client
          .from('auth.users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (resp == null) return null;
      final name = (resp['raw_user_meta_data'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      return UserProfile(
        userId: userId,
        name: name.isNotEmpty ? name : (resp['email'] as String? ?? ''),
        email: resp['email'] as String? ?? '',
        avatarPath: null,
        age: 0,
        gender: '',
        height: 0.0,
        weight: 0.0,
        fitnessGoal: '',
        totalExperience: 0,
        currentLevel: 0,
        profileCompleted: false,
        role: resp['role'] as String? ?? 'user',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching auth user fallback: $e');
      return null;
    }
  }

  Future<List<UserProfile>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final response = await client
        .from('users')
        .select()
        .in_('user_id', userIds) as List<dynamic>;

    return response
        .cast<Map<String, dynamic>>()
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  Future<ChatRoom?> _getRoomByPair(String userId, String trainerId) async {
    print('DEBUG _getRoomByPair: user_id=$userId trainer_id=$trainerId');
    final response = await client
        .from('chat_rooms')
        .select()
        .eq('user_id', userId)
        .eq('trainer_id', trainerId)
        .maybeSingle();

    return response != null ? ChatRoom.fromJson(response) : null;
  }

  Future<ChatRoom> getOrCreateChatRoomWithTrainer(String trainerId) async {
    try {
      print('Getting current user...');
      final currentUser = await getCurrentUser();
      print('Current user: ${currentUser?.userId}, role: ${currentUser?.role}');
      if (currentUser == null) throw Exception('Пользователь не авторизован');

      print('Looking for existing chat room...');
      final existing = await _getRoomByPair(currentUser.userId, trainerId);
      if (existing != null) {
        print('Found existing chat room: ${existing.id}');
        return existing;
      }

      print('Creating new chat room with trainerId: $trainerId');
      print('DEBUG incoming trainerId (from UI layer): $trainerId');

      // Resolve trainerId to a valid public.users.user_id before inserting chat_rooms.
      String finalTrainerId = trainerId;
      final existsInUsers = await client.from('users').select('user_id').eq('user_id', trainerId).maybeSingle();
      print('DEBUG existsInUsers for trainerId $trainerId => $existsInUsers');
      if (existsInUsers == null) {
        // Do not fall back to `trainers` table. The app should pass `public.users.user_id`.
        throw Exception('Trainer with id $trainerId not found in public.users. Pass `public.users.user_id` (the user profile id).');
      }

      final response = await client
          .from('chat_rooms')
          .insert({
            'user_id': currentUser.userId,
            'trainer_id': finalTrainerId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('Chat room created: $response');
      return ChatRoom.fromJson(response);
    } catch (e) {
      print('Error in getOrCreateChatRoomWithTrainer: $e');
      rethrow;
    }
  }

  Future<List<ChatRoom>> getChatRoomsForCurrentUser() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('Пользователь не авторизован');

    final response = await client
        .from('chat_rooms')
        .select()
        .eq('user_id', currentUser.userId)
        .order('updated_at', ascending: false) as List<dynamic>;

    return response
        .cast<Map<String, dynamic>>()
        .map((json) => ChatRoom.fromJson(json))
        .toList();
  }

  Future<List<ChatRoom>> getChatRoomsForCurrentTrainer() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('Пользователь не авторизован');

    final response = await client
        .from('chat_rooms')
        .select()
        .eq('trainer_id', currentUser.userId)
        .order('updated_at', ascending: false) as List<dynamic>;

    return response
        .cast<Map<String, dynamic>>()
        .map((json) => ChatRoom.fromJson(json))
        .toList();
  }

  Future<List<ChatMessage>> getChatMessages(String roomId) async {
    final response = await client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true) as List<dynamic>;

    return response
        .cast<Map<String, dynamic>>()
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  Future<void> sendChatMessage(String roomId, String messageText) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) throw Exception('Пользователь не авторизован');

    await client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': currentUser.userId,
      'message_text': messageText,
    });

    await client.from('chat_rooms').update({
      'last_message': messageText,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId);
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
    // Allow admins to publish; trainers can create drafts only
    final userProfile = await getCurrentUser();
    final role = userProfile?.role ?? 'user';
    final payload = _newsPayloadWithPublishDate(newsData);

    if (role == 'admin') {
      // admin may set is_published=true
      try {
        final insertPayload = {
          ...payload,
          'author_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        };
        print('createNews: inserting payload (admin): $insertPayload');
        final res = await client.from('news').insert(insertPayload).select().single();
        print('createNews: insert response (admin): $res');
      } catch (e) {
        print('createNews: admin insert error: $e');
        rethrow;
      }
      return;
    }

    if (role == 'trainer') {
      // trainers can only create drafts (not published)
      if (payload['is_published'] == true) {
        throw Exception('Тренеры не могут публиковать новости. Снимите флаг is_published или попросите администратора.');
      }
      try {
        final insertPayload = {
          ...payload,
          'author_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        };
        print('createNews: inserting payload (trainer): $insertPayload');
        final res = await client.from('news').insert(insertPayload).select().single();
        print('createNews: insert response (trainer): $res');
      } catch (e) {
        print('createNews: trainer insert error: $e');
        rethrow;
      }
      return;
    }

    throw Exception('Только тренеры и администраторы могут создавать новости');
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

    final now = DateTime.now();
    final dateOnly = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await client.from('water_intake').insert({
      'user_id': user.id,
      'amount': amount,
      'date': dateOnly,
    });
  }

  Future<void> logSteps(int steps) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final now = DateTime.now();
    final dateOnly = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await client.from('step_logs').insert({
      'user_id': user.id,
      'steps': steps,
      'date': dateOnly,
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

  Future<Map<String, int>> getMonthlyAverageWaterAndSteps({int days = 30}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';

    final waterResponse = await client
        .from('water_intake')
        .select('amount, date')
        .eq('user_id', user.id)
        .gte('date', startDateStr) as List<dynamic>;

    final stepResponse = await client
        .from('step_logs')
        .select('steps, date')
        .eq('user_id', user.id)
        .gte('date', startDateStr) as List<dynamic>;

    final totalWater = waterResponse.fold<int>(0, (sum, item) {
      final amount = item['amount'];
      if (amount is int) return sum + amount;
      return sum + (int.tryParse(amount?.toString() ?? '0') ?? 0);
    });

    final totalSteps = stepResponse.fold<int>(0, (sum, item) {
      final steps = item['steps'];
      if (steps is int) return sum + steps;
      return sum + (int.tryParse(steps?.toString() ?? '0') ?? 0);
    });

    final averageWater = days > 0 ? (totalWater / days).round() : 0;
    final averageSteps = days > 0 ? (totalSteps / days).round() : 0;

    return {
      'avgWater': averageWater,
      'avgSteps': averageSteps,
      'totalWater': totalWater,
      'totalSteps': totalSteps,
    };
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

  // Семьи
  Future<Family?> getUserFamily() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('family_members')
          .select('families(*)')
          .eq('user_id', user.id)
          .maybeSingle() as Map<String, dynamic>?;

      if (response == null) return null;
      final familyData = response['families'] as Map<String, dynamic>;
      return Family.fromJson(familyData);
    } catch (e) {
      print('Error getting user family: $e');
      return null;
    }
  }

  Future<void> createFamily(String familyName) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    try {
      print('Creating family: $familyName for user: ${user.id}');
      
      // Создаём семью
      final familyResponse = await client
          .from('families')
          .insert({'name': familyName, 'owner_id': user.id})
          .select()
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (familyResponse == null) {
        throw Exception('Не удалось создать семейную группу');
      }

      final familyData = familyResponse as Map<String, dynamic>;
      final familyId = familyData['id'] as String;

      print('Family created with id: $familyId');

      // Добавляем создателя как owner
      await client
          .from('family_members')
          .insert({
            'family_id': familyId,
            'user_id': user.id,
            'role': 'owner',
          })
          .timeout(const Duration(seconds: 10));

      print('User added to family as owner');
    } on TimeoutException catch (e) {
      print('Timeout creating family: $e');
      throw Exception('Сервер не отвечает при создании семьи. Попробуйте позже.');
    } catch (e) {
      print('Error creating family: $e');
      rethrow;
    }
  }

  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    try {
      final response = await client
          .from('family_members')
          .select('*, users(name, email, avatar_path)')
          .eq('family_id', familyId)
          .order('joined_at', ascending: true) as List<dynamic>;

      return response
          .cast<Map<String, dynamic>>()
          .map((member) => FamilyMember.fromJson(member))
          .toList();
    } catch (e) {
      print('Error getting family members: $e');
      return [];
    }
  }

  Future<void> addFamilyMemberByEmail(String familyId, String email) async {
    try {
      // Ищем пользователя по email
      final userResponse = await client
          .from('users')
          .select('user_id')
          .eq('email', email)
          .single() as Map<String, dynamic>;

      final userId = userResponse['user_id'] as String;

      // Добавляем в семью
      await client.from('family_members').insert({
        'family_id': familyId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      print('Error adding family member: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFamilyProgress(String familyId) async {
    try {
      final members = await getFamilyMembers(familyId);

      final memberProgress = <Map<String, dynamic>>[];
      int totalSteps = 0;
      int totalWorkouts = 0;

      for (final member in members) {
        // Получаем шаги за сегодня
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // step_logs now stores a `date` (YYYY-MM-DD) column — query by date for reliability
        final stepsResponse = await client
          .from('step_logs')
          .select('steps')
          .eq('user_id', member.userId)
          .eq('date', '${todayStr}') as List<dynamic>;

        final steps = stepsResponse.isNotEmpty
            ? (stepsResponse as List)
                .fold<int>(0, (sum, log) => sum + ((log as Map<String, dynamic>)['steps'] as int? ?? 0))
            : 0;

        // Получаем тренировки за сегодня
        final workoutsResponse = await client
          .from('workout_logs')
          .select('duration')
          .eq('user_id', member.userId)
          .gte('created_at', '${todayStr}T00:00:00')
          .lt('created_at', '${todayStr}T23:59:59') as List<dynamic>;

        final workouts = workoutsResponse.length;
        final totalDuration = workoutsResponse.isNotEmpty
            ? (workoutsResponse as List)
                .fold<int>(0, (sum, log) => sum + ((log as Map<String, dynamic>)['duration'] as int? ?? 0))
            : 0;

        memberProgress.add({
          'name': member.userName ?? member.userEmail ?? 'Участник',
          'steps': steps,
          'workouts': workouts,
          'totalDuration': totalDuration,
        });

        totalSteps += steps;
        totalWorkouts += workouts;
      }

      return {
        'totalSteps': totalSteps,
        'totalWorkouts': totalWorkouts,
        'members': memberProgress,
      };
    } catch (e) {
      print('Error getting family progress: $e');
      return {
        'totalSteps': 0,
        'totalWorkouts': 0,
        'members': [],
      };
    }
  }

  // News feed: posts, likes, comments
  Future<List<Map<String, dynamic>>> getNewsPosts({int limit = 20, int offset = 0}) async {
    try {
      final start = offset;
      final end = offset + limit - 1;
        final response = await client
          .from('news')
          .select('*, users(name, avatar_path)')
          .eq('is_published', true)
          .order('published_at', ascending: false)
          .range(start, end) as List<dynamic>;

      final posts = response.cast<Map<String, dynamic>>().toList();

      // For each post, fetch counts for likes and comments (simple implementation)
      for (final post in posts) {
        final postId = post['id'] as String?;
        if (postId == null) continue;

        try {
          final likesResp = await client.from('news_likes').select('id').eq('post_id', postId) as List<dynamic>;
          post['like_count'] = likesResp.length;
        } catch (_) {
          post['like_count'] = 0;
        }

        try {
          final commentsResp = await client.from('news_comments').select('id').eq('post_id', postId) as List<dynamic>;
          post['comment_count'] = commentsResp.length;
        } catch (_) {
          post['comment_count'] = 0;
        }
      }

      return posts;
    } catch (e) {
      print('Error fetching news posts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNewsComments(String postId, {int page = 1, int pageSize = 50}) async {
    try {
      final start = (page - 1) * pageSize;
      final end = start + pageSize - 1;
      final response = await client
          .from('news_comments')
          .select('*, users(name, avatar_path)')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(start, end) as List<dynamic>;

      return response.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      print('Error fetching news comments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createNewsPost(String title, String content, {String category = 'general', bool publishNow = true, String? imageUrl}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final profile = await getCurrentUser();
    if (profile == null) throw Exception('Профиль не найден');
    if (profile.role != 'trainer' && profile.role != 'admin') {
      throw Exception('Нет прав для создания поста');
    }

    // Respect the requested publish flag. Allow publishing immediately when requested.
    final effectivePublish = publishNow;

    final insertPayload = {
      'title': title,
      'content': content,
      'category': category,
      'is_published': effectivePublish,
      'published_at': effectivePublish ? DateTime.now().toIso8601String() : null,
      'author_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
      'image_url': imageUrl,
    };

    try {
      print('createNewsPost: inserting payload: $insertPayload');
      final res = await client.from('news').insert(insertPayload).select().single();
      print('createNewsPost: insert succeeded: $res');
      return (res as Map<String, dynamic>?);
    } catch (e) {
      print('createNewsPost: insert error: $e');
      rethrow;
    }
  }

  Future<void> toggleLikeOnNews(String postId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    try {
      final existing = await client.from('news_likes').select('id').eq('post_id', postId).eq('user_id', user.id).maybeSingle();
      if (existing != null) {
        // unlike
        await client.from('news_likes').delete().eq('post_id', postId).eq('user_id', user.id);
      } else {
        await client.from('news_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  Future<bool> userHasLikedPost(String postId) async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    try {
      final existing = await client.from('news_likes').select('id').eq('post_id', postId).eq('user_id', user.id).maybeSingle();
      return existing != null;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  Future<Set<String>> getLikedPostIdsForCurrentUser(List<String> postIds) async {
    final user = client.auth.currentUser;
    if (user == null || postIds.isEmpty) return {};
    try {
      final resp = await client.from('news_likes').select('post_id').eq('user_id', user.id).in_('post_id', postIds) as List<dynamic>;
      final ids = resp.map((e) => (e as Map<String, dynamic>)['post_id'] as String).toSet();
      return ids;
    } catch (e) {
      print('Error fetching liked post ids: $e');
      return {};
    }
  }

  Future<void> addNewsComment(String postId, String text) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    try {
      await client.from('news_comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'comment_text': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding news comment: $e');
      rethrow;
    }
  }

  Future<bool> currentUserIsTrainerOrAdmin() async {
    final profile = await getCurrentUser();
    if (profile == null) return false;
    return profile.role == 'trainer' || profile.role == 'admin';
  }
}
