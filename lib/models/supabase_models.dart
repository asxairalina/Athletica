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
  });

  factory TrainerWorkout.fromJson(Map<String, dynamic> json) {
    String? trainerName;
    if (json['users'] != null && json['users'] is Map) {
      trainerName = (json['users'] as Map)['name'] as String?;
    }
    return TrainerWorkout(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      duration: json['duration'] as int,
      muscleGroups: List<String>.from(json['muscle_groups'] as List),
      equipment: List<String>.from(json['equipment'] as List),
      videoUrl: json['video_url'] as String,
      isPublished: json['is_published'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      trainerName: trainerName,
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
}
