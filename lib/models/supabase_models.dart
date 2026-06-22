import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String userId;
  final String name;
  final String? email;
  final String? avatarPath;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fitnessGoal;
  final int totalExperience;
  final int currentLevel;
  final bool profileCompleted;
  final String role; // 'user', 'trainer', 'admin'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.name,
    this.email,
    this.avatarPath,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.fitnessGoal,
    required this.totalExperience,
    required this.currentLevel,
    required this.profileCompleted,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarPath: json['avatar_path'] as String?,
      age: json['age'] as int,
      gender: json['gender'] as String,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      fitnessGoal: json['fitness_goal'] as String,
      totalExperience: json['total_experience'] as int,
      currentLevel: json['current_level'] as int,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'avatar_path': avatarPath,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'fitness_goal': fitnessGoal,
      'total_experience': totalExperience,
      'current_level': currentLevel,
      'profile_completed': profileCompleted,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class WorkoutLog {
  final String id;
  final String userId;
  final String workoutType;
  final String? muscleGroup;
  final int duration;
  final int experience;
  final DateTime createdAt;

  const WorkoutLog({
    required this.id,
    required this.userId,
    required this.workoutType,
    this.muscleGroup,
    required this.duration,
    required this.experience,
    required this.createdAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutType: json['workout_type'] as String,
      muscleGroup: json['muscle_group'] as String?,
      duration: json['duration'] as int,
      experience: json['experience'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_type': workoutType,
      'muscle_group': muscleGroup,
      'duration': duration,
      'experience': experience,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WeightLog {
  final String id;
  final String userId;
  final double weight;
  final DateTime date;

  const WeightLog({
    required this.id,
    required this.userId,
    required this.weight,
    required this.date,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}

class WaterIntake {
  final String id;
  final String userId;
  final int amount;
  final DateTime date;

  const WaterIntake({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
  });

  factory WaterIntake.fromJson(Map<String, dynamic> json) {
    return WaterIntake(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}

class StepLog {
  final String id;
  final String userId;
  final int steps;
  final DateTime date;

  const StepLog({
    required this.id,
    required this.userId,
    required this.steps,
    required this.date,
  });

  factory StepLog.fromJson(Map<String, dynamic> json) {
    return StepLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      steps: json['steps'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'steps': steps,
      'date': date.toIso8601String(),
    };
  }
}

class PersonalRecord {
  final String id;
  final String userId;
  final String recordType;
  final double value;
  final String unit;
  final DateTime createdAt;

  const PersonalRecord({
    required this.id,
    required this.userId,
    required this.recordType,
    required this.value,
    required this.unit,
    required this.createdAt,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recordType: json['record_type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'record_type': recordType,
      'value': value,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SupabaseDailyTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String difficulty;
  final int experience;
  final bool completed;
  final DateTime date;
  final DateTime? completedAt;

  const SupabaseDailyTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.experience,
    required this.completed,
    required this.date,
    this.completedAt,
  });

  factory SupabaseDailyTask.fromJson(Map<String, dynamic> json) {
    return SupabaseDailyTask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      experience: json['experience'] as int,
      completed: json['completed'] as bool,
      date: DateTime.parse(json['date'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'experience': experience,
      'completed': completed,
      'date': date.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

class SupabaseMuscleGroup {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String color;
  final List<String> exercises;

  const SupabaseMuscleGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.exercises,
  });

  factory SupabaseMuscleGroup.fromJson(Map<String, dynamic> json) {
    return SupabaseMuscleGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      exercises: List<String>.from(json['exercises'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'exercises': exercises,
    };
  }
}

class SupabaseExerciseVideo {
  final String id;
  final String muscleGroupId;
  final String title;
  final String description;
  final String videoUrl;
  final int duration;
  final String difficulty;
  final List<String> instructions;
  final String? trainerId;

  const SupabaseExerciseVideo({
    required this.id,
    required this.muscleGroupId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.difficulty,
    required this.instructions,
    this.trainerId,
  });

  factory SupabaseExerciseVideo.fromJson(Map<String, dynamic> json) {
    return SupabaseExerciseVideo(
      id: json['id'] as String,
      muscleGroupId: json['muscle_group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['video_url'] as String,
      duration: json['duration'] as int,
      difficulty: json['difficulty'] as String,
      instructions: List<String>.from(json['instructions'] as List),
      trainerId: json['trainer_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'muscle_group_id': muscleGroupId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'duration': duration,
      'difficulty': difficulty,
      'instructions': instructions,
      'trainer_id': trainerId,
    };
  }
}

class Trainer {
  final String id;
  final String name;
  final String? avatarPath;
  final String specialization;
  final String bio;
  final double rating;
  final int experience;
  final List<String> certifications;
  final DateTime createdAt;

  const Trainer({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.specialization,
    required this.bio,
    required this.rating,
    required this.experience,
    required this.certifications,
    required this.createdAt,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatar_path'] as String?,
      specialization: json['specialization'] as String,
      bio: json['bio'] as String,
      rating: (json['rating'] as num).toDouble(),
      experience: json['experience'] as int,
      certifications: List<String>.from(json['certifications'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_path': avatarPath,
      'specialization': specialization,
      'bio': bio,
      'rating': rating,
      'experience': experience,
      'certifications': certifications,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatRoom {
  final String id;
  final String userId;
  final String trainerId;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom({
    required this.id,
    required this.userId,
    required this.trainerId,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trainerId: json['trainer_id'] as String,
      lastMessage: json['last_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trainer_id': trainerId,
      'last_message': lastMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String messageText;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageText,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'message_text': messageText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class News {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String category;
  final String? authorId;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const News({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    this.authorId,
    required this.isPublished,
    required this.createdAt,
    this.publishedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String,
      authorId: json['author_id'] as String?,
      isPublished: json['is_published'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'category': category,
      'author_id': authorId,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
    };
  }
}

class WorkoutProgram {
  final String id;
  final String trainerId;
  final String title;
  final String description;
  final String difficulty;
  final int duration;
  final List<String> exercises;
  final String category;
  final bool isPublished;
  final DateTime createdAt;

  const WorkoutProgram({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.exercises,
    required this.category,
    required this.isPublished,
    required this.createdAt,
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    return WorkoutProgram(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      duration: json['duration'] as int,
      exercises: List<String>.from(json['exercises'] as List),
      category: json['category'] as String,
      isPublished: json['is_published'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'exercises': exercises,
      'category': category,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TrainerWorkout {
  final String id;
  final String trainerId;
  final String title;
  final String description;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int duration; // в минутах
  final List<String> muscleGroups;
  final List<String> equipment;
  final String videoUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? trainerName;
  final double rating;
  final int ratingCount;

  const TrainerWorkout({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.muscleGroups,
    required this.equipment,
    required this.videoUrl,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
    this.trainerName,
    this.rating = 0.0,
    this.ratingCount = 0,
  });

  factory TrainerWorkout.fromJson(Map<String, dynamic> json) {
    String? trainerName;
    if (json['users'] != null && json['users'] is Map) {
      trainerName = (json['users'] as Map)['name'] as String?;
    }

    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
      return false;
    }

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      }
      return [];
    }

    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return TrainerWorkout(
      id: parseString(json['id']),
      trainerId: parseString(json['trainer_id']),
      title: parseString(json['title']),
      description: parseString(json['description']),
      difficulty: parseString(json['difficulty']).isNotEmpty ? parseString(json['difficulty']) : 'beginner',
      duration: parseInt(json['duration']),
      muscleGroups: parseStringList(json['muscle_groups']),
      equipment: parseStringList(json['equipment']),
      videoUrl: parseString(json['video_url']),
      isPublished: parseBool(json['is_published']),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: json['updated_at'] != null ? parseDateTime(json['updated_at']) : null,
      trainerName: trainerName,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'muscle_groups': muscleGroups,
      'equipment': equipment,
      'video_url': videoUrl,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TrainerWorkout copyWith({
    double? rating,
    int? ratingCount,
    String? id,
    String? trainerId,
    String? title,
    String? description,
    String? difficulty,
    int? duration,
    List<String>? muscleGroups,
    List<String>? equipment,
    String? videoUrl,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? trainerName,
  }) {
    return TrainerWorkout(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      duration: duration ?? this.duration,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      equipment: equipment ?? this.equipment,
      videoUrl: videoUrl ?? this.videoUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trainerName: trainerName ?? this.trainerName,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }
}

class WorkoutComment {
  final String id;
  final String workoutId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? userName;
  final String? avatarPath;

  WorkoutComment({
    required this.id,
    required this.workoutId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.userName,
    this.avatarPath,
  });

  factory WorkoutComment.fromJson(Map<String, dynamic> json) {
    String? userName;
    String? avatarPath;
    if (json['users'] != null && json['users'] is Map<String, dynamic>) {
      userName = (json['users'] as Map<String, dynamic>)['name'] as String?;
      avatarPath = (json['users'] as Map<String, dynamic>)['avatar_path'] as String?;
    }

    return WorkoutComment(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      userId: json['user_id'] as String,
      text: json['comment_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: userName,
      avatarPath: avatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'user_id': userId,
      'comment_text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Family {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Family({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class FamilyMember {
  final String id;
  final String familyId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? userName;
  final String? userEmail;
  final String? avatarPath;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userName,
    this.userEmail,
    this.avatarPath,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    String? userName;
    String? userEmail;
    String? avatarPath;
    if (json['users'] != null && json['users'] is Map<String, dynamic>) {
      final users = json['users'] as Map<String, dynamic>;
      userName = users['name'] as String?;
      userEmail = users['email'] as String?;
      avatarPath = users['avatar_path'] as String?;
    }

    return FamilyMember(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userName: userName,
      userEmail: userEmail,
      avatarPath: avatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
