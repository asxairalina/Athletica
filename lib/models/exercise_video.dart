class ExerciseVideo {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final int duration; // в секундах
  final String difficulty;
  final List<String> instructions;

  const ExerciseVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.duration,
    required this.difficulty,
    required this.instructions,
  });
}

class ExerciseVideosData {
  static List<ExerciseVideo> getVideosForMuscleGroup(String muscleGroupId) {
    switch (muscleGroupId) {
      case 'massage':
        return [
          ExerciseVideo(
            id: 'massage_1',
            title: 'Базовый массаж спины',
            description: 'Легкий поглаживающий массаж для улучшения кровообращения',
            videoUrl: 'https://example.com/massage_back.mp4',
            duration: 300, // 5 минут
            difficulty: 'Легкий',
            instructions: [
              'Положите ребенка на живот',
              'Нанесите массажное масло',
              'Поглаживайте спину от шеи до поясницы',
              'Движения должны быть плавными и ритмичными',
            ],
          ),
          ExerciseVideo(
            id: 'massage_2',
            title: 'Массаж ножек',
            description: 'Стимулирующий массаж для развития мышц ног',
            videoUrl: 'https://example.com/massage_legs.mp4',
            duration: 240, // 4 минуты
            difficulty: 'Легкий',
            instructions: [
              'Аккуратно массируйте стопы',
              'Двигайтесь вверх по голени',
              'Массируйте бедро легкими движениями',
              'Завершите поглаживанием',
            ],
          ),
        ];
      case 'gymnastics':
        return [
          ExerciseVideo(
            id: 'gym_1',
            title: 'Пассивная гимнастика',
            description: 'Упражнения на сгибание и разгибание конечностей',
            videoUrl: 'https://example.com/passive_gym.mp4',
            duration: 180, // 3 минуты
            difficulty: 'Легкий',
            instructions: [
              'Аккуратно сгибайте ручки',
              'Разводите руки в стороны',
              'Сгибайте и разгибайте ножки',
              'Следите за реакцией ребенка',
            ],
          ),
          ExerciseVideo(
            id: 'gym_2',
            title: 'Укрепление пресса',
            description: 'Упражнения для развития мышц живота',
            videoUrl: 'https://example.com/baby_abs.mp4',
            duration: 120, // 2 минуты
            difficulty: 'Средний',
            instructions: [
              'Поднимайте ножки к животу',
              'Держите 2-3 секунды',
              'Медленно опускайте',
              'Повторите 10 раз',
            ],
          ),
        ];
      case 'reflexes':
        return [
          ExerciseVideo(
            id: 'reflex_1',
            title: 'Рефлекс ползания',
            description: 'Стимуляция рефлекса ползания',
            videoUrl: 'https://example.com/crawl_reflex.mp4',
            duration: 150, // 2.5 минуты
            difficulty: 'Легкий',
            instructions: [
              'Положите ребенка на живот',
              'Создайте опору для стоп',
              'Легко надавите на стопы',
              'Ребенок должен оттолкнуться',
            ],
          ),
          ExerciseVideo(
            id: 'reflex_2',
            title: 'Хватательный рефлекс',
            description: 'Развитие рефлекса хватания',
            videoUrl: 'https://example.com/grasp_reflex.mp4',
            duration: 120, // 2 минуты
            difficulty: 'Легкий',
            instructions: [
              'Поднесите палец к ладошке',
              'Ребенок должен сжать кулачки',
              'Следите за симметрией',
              'Чередуйте руки',
            ],
          ),
        ];
      case 'water':
        return [
          ExerciseVideo(
            id: 'water_1',
            title: 'Плавание с кругом',
            description: 'Первые упражнения в воде с поддерживающим кругом',
            videoUrl: 'https://example.com/baby_swimming.mp4',
            duration: 240, // 4 минуты
            difficulty: 'Легкий',
            instructions: [
              'Используйте специальный круг для младенцев',
              'Поддерживайте голову над водой',
              'Двигайте ножками в воде',
              'Следите за комфортом ребенка',
            ],
          ),
          ExerciseVideo(
            id: 'water_2',
            title: 'Ныряние',
            description: 'Безопасное ныряние под присмотром',
            videoUrl: 'https://example.com/baby_diving.mp4',
            duration: 180, // 3 минуты
            difficulty: 'Средний',
            instructions: [
              'Говорите "ныряем"',
              'Поддерживайте ребенка',
              'Кратко погрузите в воду',
              'Сразу поднимите',
            ],
          ),
        ];
      case 'chest':
        return [
          ExerciseVideo(
            id: 'chest_1',
            title: 'Отжимания с широкой постановкой',
            description: 'Классические отжимания для развития грудных мышц',
            videoUrl: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
            duration: 180,
            difficulty: 'medium',
            instructions: [
              'Примите упор лежа на прямых руках',
              'Расставьте руки шире плеч',
              'Опуститесь до параллели с полом',
              'Выжмите себя вверх, полностью выпрямляя руки',
              'Держите спину прямой и напрягайте пресс',
            ],
          ),
          ExerciseVideo(
            id: 'chest_2',
            title: 'Жим лежа',
            description: 'Базовое упражнение с гантелями',
            videoUrl: 'https://example.com/bench_press.mp4',
            duration: 240, // 4 минуты
            difficulty: 'Средний',
            instructions: [
              'Лягте на скамью',
              'Возьмите гантели',
              'Опускайте до груди',
              'Выжимайте вверх',
            ],
          ),
        ];
      case 'back':
        return [
          ExerciseVideo(
            id: 'back_1',
            title: 'Подтягивания',
            description: 'Развитие широчайших мышц спины',
            videoUrl: 'https://example.com/pullups.mp4',
            duration: 300, // 5 минут
            difficulty: 'Сложный',
            instructions: [
              'Хватитесь за перекладину',
              'Подтягивайтесь до подбородка',
              'Медленно опускайтесь',
              'Контролируйте движение',
            ],
          ),
          ExerciseVideo(
            id: 'back_2',
            title: 'Тяга штанги',
            description: 'Укрепление мышц спины и бицепса',
            videoUrl: 'https://example.com/barbell_row.mp4',
            duration: 240, // 4 минуты
            difficulty: 'Средний',
            instructions: [
              'Наклонитесь вперед',
              'Возьмите штангу',
              'Тяните к животу',
              'Сводите лопатки',
            ],
          ),
        ];
      default:
        return [];
    }
  }
}
