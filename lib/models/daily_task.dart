import 'package:flutter/material.dart';

enum TaskDifficulty {
  easy,
  medium,
  hard,
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final TaskDifficulty difficulty;
  final int experience;
  final bool isCompleted;
  final DateTime? completedDate;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.experience,
    this.isCompleted = false,
    this.completedDate,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskDifficulty? difficulty,
    int? experience,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      experience: experience ?? this.experience,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  String get difficultyText {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Легкий';
      case TaskDifficulty.medium:
        return 'Средний';
      case TaskDifficulty.hard:
        return 'Сложный';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
    }
  }
}
