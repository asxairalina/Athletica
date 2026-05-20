# База данных Athletica Fitness

## 1. Установка схемы и Storage

**`full_portable_setup.sql`** — один скрипт: таблицы, RLS, триггеры, сиды, bucket `avatars`.

SQL Editor → вставить весь файл → Run.

```sql
UPDATE users SET role = 'admin' WHERE email = 'ваш@email.com';
```

Ключи Supabase — в **`lib/config/supabase_config.dart`** (`supabaseUrl`, `supabaseAnonKey`).

## 2. Тренеры (опционально)

**`seed_trainers.sql`** — 5 аккаунтов `trainer` (после шага 1).

## 3. Тестовые тренировки тренеров (опционально)

**`seed_trainer_workouts.sql`** — публикации в `trainer_workouts` (после шагов 1–2).

## 4. История тренировок пользователя (статистика)

**`seed_user_workout_history.sql`** — ~30 дней тренировок до сегодня для календаря и экрана «Аналитика».

1. Зарегистрируйтесь в приложении под своим email.
2. В скрипте замените `YOUR_EMAIL@example.com` на ваш email.
3. SQL Editor → Run.

Повторный запуск пересоздаёт данные за тот же период.

## 5. Свои данные

Экспорт: **`EXPORT_DATA.md`**.

## Файлы

| Файл | Назначение |
|------|------------|
| `full_portable_setup.sql` | Полная установка БД + Storage |
| `seed_trainers.sql` | 5 тестовых тренеров |
| `seed_trainer_workouts.sql` | Тренировки тренеров |
| `seed_user_workout_history.sql` | История тренировок для аналитики |
| `EXPORT_DATA.md` | Перенос контента |
