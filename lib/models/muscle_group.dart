import 'package:flutter/material.dart';

enum MuscleGroupCategory {
  infants,    // Младенцы
  basic,      // Беременные
  standard,   // Молодежь
  gentle,     // Взрослые
}

class MuscleGroup {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> exercises;
  final MuscleGroupCategory category;

  const MuscleGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.exercises,
    required this.category,
  });
}

class MuscleGroupsData {
  static List<MuscleGroup> getMuscleGroupsForCategory(MuscleGroupCategory category) {
    switch (category) {
      case MuscleGroupCategory.infants:
        return _infantsExerciseGroups;
      case MuscleGroupCategory.basic:
        return _pregnantMuscleGroups;
      case MuscleGroupCategory.standard:
        return _youngMuscleGroups;
      case MuscleGroupCategory.gentle:
        return _seniorMuscleGroups;
    }
  }

  static final List<MuscleGroup> _infantsExerciseGroups = [
    MuscleGroup(
      id: 'massage',
      name: 'Массаж',
      description: 'Общий массаж для развития мышц и кровообращения',
      icon: Icons.spa,
      color: Colors.pink,
      exercises: ['Поглаживание', 'Растирание', 'Разминание', 'Вибрация'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'gymnastics',
      name: 'Гимнастика',
      description: 'Базовая гимнастика для развития моторики',
      icon: Icons.child_care,
      color: Colors.purple,
      exercises: ['Пассивные упражнения', 'Активные движения', 'Координация'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'reflexes',
      name: 'Рефлексы',
      description: 'Упражнения для развития врожденных рефлексов',
      icon: Icons.psychology,
      color: Colors.indigo,
      exercises: ['Ползание', 'Хватание', 'Перевороты', 'Сидение'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'water',
      name: 'Водные процедуры',
      description: 'Плавание и водные занятия для развития',
      icon: Icons.pool,
      color: Colors.blue,
      exercises: ['Плавание с кругом', 'Ныряние', 'Игра в воде', 'Движение в воде'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'balance',
      name: 'Баланс',
      description: 'Упражнения для развития чувства равновесия',
      icon: Icons.balance,
      color: Colors.teal,
      exercises: ['Сидение на мяче', 'Поддержание головы', 'Первые шаги', 'Стояние с поддержкой'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'sensory',
      name: 'Сенсорика',
      description: 'Развитие чувств и восприятия мира',
      icon: Icons.touch_app,
      color: Colors.orange,
      exercises: ['Тактильные игры', 'Звуковые упражнения', 'Цветовая стимуляция', 'Текстурные поверхности'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'coordination',
      name: 'Координация',
      description: 'Развитие координации движений',
      icon: Icons.sync_alt,
      color: Colors.green,
      exercises: ['Ловля предметов', 'Перекладывание', 'Мелкая моторика', 'Глазомер'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'breathing',
      name: 'Дыхание',
      description: 'Дыхательные упражнения для здоровья легких',
      icon: Icons.air,
      color: Colors.cyan,
      exercises: ['Грудное дыхание', 'Диафрагмальное', 'Полное дыхание', 'Дыхание по методике'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'strengthening',
      name: 'Укрепление',
      description: 'Общее укрепление мышц и костей',
      icon: Icons.fitness_center,
      color: Colors.red,
      exercises: ['Упражнения на спину', 'Укрепление пресса', 'Развитие ног', 'Мышечный тонус'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'relaxation',
      name: 'Расслабление',
      description: 'Техники расслабления и снятия напряжения',
      icon: Icons.spa,
      color: Colors.brown,
      exercises: ['Легкий массаж', 'Укачивание', 'Колыбельные', 'Спокойные игры'],
      category: MuscleGroupCategory.infants,
    ),
    MuscleGroup(
      id: 'development',
      name: 'Развитие',
      description: 'Комплексные упражнения для общего развития',
      icon: Icons.trending_up,
      color: Colors.amber,
      exercises: ['Комплекс 1-3 месяца', 'Комплекс 4-6 месяцев', 'Комплекс 7-9 месяцев', 'Комплекс 10-12 месяцев'],
      category: MuscleGroupCategory.infants,
    ),
  ];

  static final List<MuscleGroup> _pregnantMuscleGroups = [
    MuscleGroup(
      id: 'spine',
      name: 'Спина',
      description: 'Укрепление мышц спины для поддержки позвоночника',
      icon: Icons.accessibility,
      color: Colors.blue,
      exercises: ['Кошка-корова', 'Планка на предплечьях', 'Мостик'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'pelvis',
      name: 'Тазовое дно',
      description: 'Упражнения Кегеля для укрепления мышц тазового дна',
      icon: Icons.favorite,
      color: Colors.pink,
      exercises: ['Сжатие и расслабление', 'Удержание', 'Быстрые сокращения'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'legs',
      name: 'Ноги',
      description: 'Безопасные упражнения для ног и бедер',
      icon: Icons.directions_walk,
      color: Colors.green,
      exercises: ['Приседания у стены', 'Подъемы на икрышки', 'Выпады'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'breathing',
      name: 'Дыхание',
      description: 'Дыхательные практики для расслабления',
      icon: Icons.air,
      color: Colors.teal,
      exercises: ['Грудное дыхание', 'Брюшное дыхание', 'Полное дыхание'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'core',
      name: 'Кор',
      description: 'Укрепление мышц кора',
      icon: Icons.fitness_center,
      color: Colors.orange,
      exercises: ['Мягкая планка', 'Подъемы ног', 'Велосипед'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'arms',
      name: 'Руки',
      description: 'Легкие упражнения для рук',
      icon: Icons.front_hand,
      color: Colors.purple,
      exercises: ['Круги в плечах', 'Сгибание рук', 'Разведение рук'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'balance',
      name: 'Баланс',
      description: 'Упражнения на баланс и координацию',
      icon: Icons.balance,
      color: Colors.indigo,
      exercises: ['Стояние на одной ноге', 'Ходьба по линии', 'Повороты'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'relaxation',
      name: 'Расслабление',
      description: 'Упражнения для снятия напряжения',
      icon: Icons.spa,
      color: Colors.brown,
      exercises: ['Наклоны', 'Растяжка', 'Массаж'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'posture',
      name: 'Осанка',
      description: 'Упражнения для красивой осанки',
      icon: Icons.accessibility_new,
      color: Colors.cyan,
      exercises: ['Стена', 'Лодочка', 'Растягивание позвоночника'],
      category: MuscleGroupCategory.basic,
    ),
    MuscleGroup(
      id: 'circulation',
      name: 'Кровообращение',
      description: 'Улучшение кровообращения',
      icon: Icons.favorite_border,
      color: Colors.red,
      exercises: ['Ходьба', 'Махи ногами', 'Вращение стопами'],
      category: MuscleGroupCategory.basic,
    ),
  ];

  static final List<MuscleGroup> _youngMuscleGroups = [
    MuscleGroup(
      id: 'chest',
      name: 'Грудь',
      description: 'Развитие грудных мышц',
      icon: Icons.fitness_center,
      color: Colors.red,
      exercises: ['Отжимания', 'Жим лежа', 'Разводка гантелей'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'back',
      name: 'Спина',
      description: 'Мощные мышцы спины',
      icon: Icons.accessibility,
      color: Colors.blue,
      exercises: ['Подтягивания', 'Тяга штанги', 'Горизонтальная тяга'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'shoulders',
      name: 'Плечи',
      description: 'Развитие дельтовидных мышц',
      icon: Icons.sports_gymnastics,
      color: Colors.orange,
      exercises: ['Жим стоя', 'Махи гантелями', 'Армейский жим'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'biceps',
      name: 'Бицепс',
      description: 'Развитие бицепса',
      icon: Icons.front_hand,
      color: Colors.purple,
      exercises: ['Сгибание рук', 'Молотки', 'Концентрированные сгибания'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'triceps',
      name: 'Трицепс',
      description: 'Развитие трицепса',
      icon: Icons.back_hand,
      color: Colors.indigo,
      exercises: ['Французский жим', 'Отжимания на брусьях', 'Разгибание рук'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'legs',
      name: 'Ноги',
      description: 'Мощные ноги и ягодицы',
      icon: Icons.directions_walk,
      color: Colors.green,
      exercises: ['Приседания со штангой', 'Жим ногами', 'Выпады', 'Сгибание ног'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'core',
      name: 'Пресс',
      description: 'Рельефный пресс',
      icon: Icons.local_fire_department,
      color: Colors.amber,
      exercises: ['Скручивания', 'Подъемы ног', 'Планка', 'Велосипед'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'calves',
      name: 'Икры',
      description: 'Развитие икроножных мышц',
      icon: Icons.trending_up,
      color: Colors.teal,
      exercises: ['Подъемы на икрышки', 'Жим носками', 'Осел'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'forearms',
      name: 'Предплечья',
      description: 'Сильные предплечья',
      icon: Icons.pan_tool,
      color: Colors.brown,
      exercises: ['Сгибание запястий', 'Вращение', 'Удержание'],
      category: MuscleGroupCategory.standard,
    ),
    MuscleGroup(
      id: 'traps',
      name: 'Трапеции',
      description: 'Развитие трапециевидных мышц',
      icon: Icons.terrain,
      color: Colors.cyan,
      exercises: ['Шраги', 'Тяга к подбородку', 'Гиперэкстензия'],
      category: MuscleGroupCategory.standard,
    ),
  ];

  static final List<MuscleGroup> _seniorMuscleGroups = [
    MuscleGroup(
      id: 'posture',
      name: 'Осанка',
      description: 'Улучшение осанки и гибкости',
      icon: Icons.accessibility_new,
      color: Colors.blue,
      exercises: ['Наклоны', 'Растяжка', 'Планка у стены'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'balance',
      name: 'Баланс',
      description: 'Улучшение баланса и координации',
      icon: Icons.balance,
      color: Colors.green,
      exercises: ['Стояние на одной ноге', 'Ходьба по линии', 'Тайчи'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'legs',
      name: 'Ноги',
      description: 'Поддержание силы ног',
      icon: Icons.directions_walk,
      color: Colors.orange,
      exercises: ['Приседания без веса', 'Ходьба', 'Подъемы на ступеньку'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'core',
      name: 'Кор',
      description: 'Умеренное укрепление кора',
      icon: Icons.fitness_center,
      color: Colors.purple,
      exercises: ['Планка на коленях', 'Подъемы таза', 'Кошка-корова'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'arms',
      name: 'Руки',
      description: 'Поддержание тонуса рук',
      icon: Icons.front_hand,
      color: Colors.teal,
      exercises: ['Круги в плечах', 'Легкие отжимания', 'Сгибание с гантелями 1кг'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'flexibility',
      name: 'Гибкость',
      description: 'Увеличение гибкости суставов',
      icon: Icons.accessibility,
      color: Colors.cyan,
      exercises: ['Растяжка', 'Йога', 'Пилатес'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'breathing',
      name: 'Дыхание',
      description: 'Дыхательные практики',
      icon: Icons.air,
      color: Colors.indigo,
      exercises: ['Глубокое дыхание', 'Диафрагмальное дыхание', 'Расслабление'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'joints',
      name: 'Суставы',
      description: 'Здоровье суставов',
      icon: Icons.sync_alt,
      color: Colors.brown,
      exercises: ['Вращения суставами', 'Махи', 'Легкая растяжка'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'circulation',
      name: 'Кровообращение',
      description: 'Улучшение кровообращения',
      icon: Icons.favorite_border,
      color: Colors.red,
      exercises: ['Ходьба', 'Махи ногами', 'Велосипед сидя'],
      category: MuscleGroupCategory.gentle,
    ),
    MuscleGroup(
      id: 'relaxation',
      name: 'Расслабление',
      description: 'Снятие напряжения',
      icon: Icons.spa,
      color: Colors.pink,
      exercises: ['Медитация', 'Прогрессивная релаксация', 'Легкий массаж'],
      category: MuscleGroupCategory.gentle,
    ),
  ];
}
