DELETE FROM trainer_workouts
WHERE trainer_id IN (
  SELECT user_id FROM users
  WHERE email IN (
    'trainer1@athletica.local',
    'trainer2@athletica.local',
    'trainer3@athletica.local',
    'trainer4@athletica.local',
    'trainer5@athletica.local'
  )
);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Массаж ребёнку 1,5–3 месяца', 'Классический массаж и тактильный контакт с малышом', 'beginner', 12, ARRAY['Массаж'], '{}', 'https://rutube.ru/video/332eb0a21701f118b075e04b9c9a548a/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Игровой массаж 3–12 месяцев', 'Пальчиковые игры и мягкий массаж с мамой', 'beginner', 10, ARRAY['Массаж'], '{}', 'https://rutube.ru/video/cae35f179bb45d3dd1fb86c3309fc1ad/', true),
((SELECT user_id FROM users WHERE email = 'trainer5@athletica.local'), 'Гимнастика и массаж грудничка', 'Щадящие приёмы от педиатрического специалиста', 'beginner', 11, ARRAY['Массаж'], '{}', 'https://rutube.ru/video/531dd07caf53486a725b0e35abf58b39/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Игровая гимнастика с мамой', 'Простые игры для моторики 3–12 месяцев', 'beginner', 14, ARRAY['Гимнастика'], ARRAY['Мягкая игрушка'], 'https://rutube.ru/video/cae35f179bb45d3dd1fb86c3309fc1ad/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Массаж и гимнастика курс', 'Пассивная гимнастика и суставные движения', 'beginner', 13, ARRAY['Гимнастика'], '{}', 'https://rutube.ru/video/332eb0a21701f118b075e04b9c9a548a/', true),
((SELECT user_id FROM users WHERE email = 'trainer5@athletica.local'), 'Учимся сидеть и ползать', 'Упражнения с 3 месяцев для крупной моторики', 'beginner', 12, ARRAY['Гимнастика'], '{}', 'https://rutube.ru/video/e9de96ed819550634bb4a0060e3c75ec/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Развитие в 2 месяца', 'Что умеет малыш и как его поддержать', 'beginner', 11, ARRAY['Гимнастика'], '{}', 'https://rutube.ru/video/9ea71abdeeefbdf79900440bc58d8a7c/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Стимуляция ползания', 'Как мягко научить малыша ползать', 'beginner', 10, ARRAY['Рефлексы'], '{}', 'https://rutube.ru/video/eb3b4e73c9efb62b6ecb822662a14a6c/', true),
((SELECT user_id FROM users WHERE email = 'trainer5@athletica.local'), 'Перевороты и ползание', 'Не сложные упражнения с 3 месяцев', 'beginner', 11, ARRAY['Рефлексы'], '{}', 'https://rutube.ru/video/e9de96ed819550634bb4a0060e3c75ec/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Развитие моторики в 9 месяцев', 'Поддержка при ползании и хвате', 'beginner', 12, ARRAY['Рефлексы'], '{}', 'https://rutube.ru/video/ce175e53813a2c27690fc5293e4e29fe/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Грудничковое плавание', 'Занятие в детском бассейне с инструктором', 'beginner', 15, ARRAY['Водные процедуры'], ARRAY['Детский бассейн'], 'https://rutube.ru/video/bd76a9cfae4187cd6b7667967ecc4bd8/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Аквазанятие «Мама и малыш»', 'Спокойные водные упражнения 0–1 год', 'beginner', 12, ARRAY['Водные процедуры'], ARRAY['Бассейн'], 'https://rutube.ru/video/ee68d8f0ac96719db970679f0e8b3dc1/', true),
((SELECT user_id FROM users WHERE email = 'trainer5@athletica.local'), 'Плавание в аквацентре', 'Привыкание к воде и базовые движения', 'beginner', 10, ARRAY['Водные процедуры'], ARRAY['Детский бассейн'], 'https://rutube.ru/video/d19726f40ce6f80b9732567c0fbd8dc9/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Растяжка на фитболе', 'Спина и таз для беременных', 'beginner', 18, ARRAY['Спина'], ARRAY['Фитбол'], 'https://rutube.ru/video/59ce69d63ca3e9db85ff5b8e1490ec8b/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Упражнения для спины 2 триместр', 'Мягкое дыхание и работа с поясницей', 'beginner', 20, ARRAY['Спина'], '{}', 'https://rutube.ru/video/7e5bd8ad18d1cf47a9ae61429c535797/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Йога от отёков', 'Поясница и таз, мягкая практика', 'beginner', 15, ARRAY['Спина'], ARRAY['Коврик'], 'https://rutube.ru/video/9c6f33462f99d2b18c15af3aca96a163/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Йога 1 триместр', 'Безопасный комплекс для спины и тела', 'beginner', 16, ARRAY['Спина'], ARRAY['Коврик'], 'https://rutube.ru/video/ece06fd21efc54f05acfad0508e8e2e6/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Три упражнения Кегеля', 'Техника от врача для тазового дна', 'beginner', 14, ARRAY['Тазовое дно'], '{}', 'https://rutube.ru/video/56e473b78d67cfc9a6480429a59c2015/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Кегель для новичков', 'Подробный разбор базовых движений', 'beginner', 12, ARRAY['Тазовое дно'], '{}', 'https://rutube.ru/video/ad46371ab90e20cd6a0b4b7c791355c0/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Укрепление тазового дна', 'Короткий комплекс на каждый день', 'beginner', 13, ARRAY['Тазовое дно'], '{}', 'https://rutube.ru/video/e443ed4d81fa8b05dac434ac76e2c956/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer1@athletica.local'), 'Лучшие упражнения на грудь', 'Домашняя тренировка с собственным весом', 'intermediate', 25, ARRAY['Грудь'], '{}', 'https://rutube.ru/video/7aa64cd92a0d5b8af5fee1c919586f63/', true),
((SELECT user_id FROM users WHERE email = 'trainer1@athletica.local'), 'Грудь без железа', 'Отжимания и базовые движения дома', 'beginner', 20, ARRAY['Грудь'], '{}', 'https://rutube.ru/video/3c0dae144b65f9ed5192931150343192/', true),
((SELECT user_id FROM users WHERE email = 'trainer3@athletica.local'), 'Топ-6 на грудные', 'Силовые и базовые упражнения', 'intermediate', 28, ARRAY['Грудь'], ARRAY['Гантели'], 'https://rutube.ru/video/3781020f91ef89b4d0d848ccfbd7a419/', true),
((SELECT user_id FROM users WHERE email = 'trainer1@athletica.local'), 'Качаем грудные мышцы', 'Комплекс для женщин и мужчин', 'intermediate', 22, ARRAY['Грудь'], ARRAY['Гантели'], 'https://rutube.ru/video/e3aa69aabb89617a8795fe180b85e3ae/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer3@athletica.local'), 'Подтягивания широким хватом', 'Техника для широчайших мышц', 'intermediate', 26, ARRAY['Спина'], ARRAY['Турник'], 'https://rutube.ru/video/fe161cc3a8ce23328cc353221a21d969/', true),
((SELECT user_id FROM users WHERE email = 'trainer1@athletica.local'), 'Тяга гантели в наклоне', 'Базовое упражнение для спины', 'intermediate', 24, ARRAY['Спина'], ARRAY['Гантель'], 'https://rutube.ru/video/aaa1760b07001db1a687c822b9aca596/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Спина дома без инвентаря', '15 минут на осанку и мышцы спины', 'beginner', 18, ARRAY['Спина'], '{}', 'https://rutube.ru/video/1ddd2cd9d537087b67bbcffd80478b11/', true),
((SELECT user_id FROM users WHERE email = 'trainer3@athletica.local'), 'Тяга гантелей к поясу', 'Стоя, проработка средней части спины', 'intermediate', 30, ARRAY['Спина'], ARRAY['Гантели'], 'https://rutube.ru/video/83364ce450fcf2996653fee81b03f193/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Осанка за 10 минут', 'Простые упражнения стоя', 'beginner', 16, ARRAY['Осанка'], '{}', 'https://rutube.ru/video/6c6035af5010b8900b497ce909c09477/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Исправить сутулость дома', '10 упражнений за один урок', 'beginner', 18, ARRAY['Осанка'], '{}', 'https://rutube.ru/video/ea2a6547d94ada6ceeba2dbf5f2097a2/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Функциональная осанка', 'Укрепление мышц-стабилизаторов', 'beginner', 12, ARRAY['Осанка'], '{}', 'https://rutube.ru/video/41589ca060886dae7f180a09cfbe7f0a/', true),
((SELECT user_id FROM users WHERE email = 'trainer4@athletica.local'), 'Гибкая спина и осанка', 'Полный комплекс на 15 минут', 'beginner', 14, ARRAY['Осанка'], ARRAY['Коврик'], 'https://rutube.ru/video/233cd73b6573aa6260f29e04a36e76b5/', true);

INSERT INTO trainer_workouts (trainer_id, title, description, difficulty, duration, muscle_groups, equipment, video_url, is_published) VALUES
((SELECT user_id FROM users WHERE email = 'trainer3@athletica.local'), 'Упражнения на равновесие', 'Базовый комплекс для координации', 'beginner', 15, ARRAY['Баланс'], '{}', 'https://rutube.ru/video/93ec26a92609f9293bebe8e6d46b2f69/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Развитие равновесия', 'Синхронизация тела и координация', 'beginner', 18, ARRAY['Баланс'], '{}', 'https://rutube.ru/video/ca154ca3cb59b318469d9ef1a973b364/', true),
((SELECT user_id FROM users WHERE email = 'trainer1@athletica.local'), 'Балансы на одной ноге', 'Йога: стойки и устойчивость', 'beginner', 14, ARRAY['Баланс'], ARRAY['Коврик'], 'https://rutube.ru/video/6b7eacf5bdaa588787aef837f82639d4/', true),
((SELECT user_id FROM users WHERE email = 'trainer2@athletica.local'), 'Осанка и дыхание стоя', 'Поддержка равновесия через осанку', 'beginner', 16, ARRAY['Баланс'], '{}', 'https://rutube.ru/video/6c6035af5010b8900b497ce909c09477/', true);

SELECT
  unnest(muscle_groups) AS muscle_group,
  COUNT(*) AS workouts_count
FROM trainer_workouts
WHERE is_published = true
  AND trainer_id IN (
    SELECT user_id FROM users WHERE email LIKE 'trainer%@athletica.local'
  )
GROUP BY 1
ORDER BY 1;
