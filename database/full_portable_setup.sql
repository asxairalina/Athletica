
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  avatar_path TEXT,
  age INTEGER NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  height DECIMAL(5,2) NOT NULL,
  weight DECIMAL(5,2) NOT NULL,
  fitness_goal TEXT NOT NULL CHECK (fitness_goal IN ('weight_loss', 'muscle_gain', 'endurance', 'flexibility', 'general_fitness')),
  total_experience INTEGER DEFAULT 0,
  current_level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS daily_tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  experience INTEGER NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  date DATE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS workout_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_type TEXT NOT NULL,
  muscle_group TEXT,
  duration INTEGER NOT NULL, -- в секундах
  experience INTEGER NOT NULL,
  calories INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS weight_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  weight DECIMAL(5,2) NOT NULL,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS water_intake (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL, -- в миллилитрах
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS step_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  steps INTEGER NOT NULL,
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS personal_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  record_type TEXT NOT NULL,
  value DECIMAL(10,2) NOT NULL,
  unit TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS muscle_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('infants', 'basic', 'standard', 'gentle')),
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  exercises JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS trainers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  avatar_path TEXT,
  specialization TEXT NOT NULL,
  bio TEXT,
  rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  experience INTEGER DEFAULT 0, -- в годах
  certifications JSONB DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS exercise_videos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  muscle_group_id UUID REFERENCES muscle_groups(id) ON DELETE CASCADE,
  trainer_id UUID REFERENCES trainers(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  video_url TEXT NOT NULL,
  duration INTEGER NOT NULL, -- в секундах
  difficulty TEXT NOT NULL CHECK (difficulty IN ('Легкий', 'Средний', 'Сложный')),
  instructions JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS workout_programs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  trainer_id UUID REFERENCES trainers(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  difficulty TEXT NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  duration INTEGER NOT NULL, -- в минутах
  exercises JSONB NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('strength', 'cardio', 'flexibility', 'hiit', 'yoga', 'pilates')),
  is_published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT FALSE;


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_user_id_unique') THEN
        ALTER TABLE users ADD CONSTRAINT users_user_id_unique UNIQUE (user_id);
    END IF;
END $$;


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_role') THEN
        ALTER TABLE users ADD CONSTRAINT check_role 
          CHECK (role IN ('user', 'trainer', 'admin'));
    END IF;
END $$;


UPDATE users SET role = 'user' WHERE role IS NULL;
UPDATE users SET profile_completed = FALSE WHERE profile_completed IS NULL;


CREATE TABLE IF NOT EXISTS trainer_workouts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    trainer_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) DEFAULT 'beginner' CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    duration INTEGER NOT NULL, -- в минутах
    muscle_groups TEXT[] DEFAULT '{}',
    equipment TEXT[] DEFAULT '{}',
    video_url VARCHAR(500),
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);


CREATE TABLE IF NOT EXISTS news (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    author_id UUID REFERENCES users(user_id) ON DELETE SET NULL
);


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_news_category') THEN
        ALTER TABLE news ADD CONSTRAINT check_news_category 
          CHECK (category IN ('general', 'fitness', 'nutrition', 'tips', 'events', 'announcements'));
    END IF;
END $$;


CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_id ON daily_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_date ON daily_tasks(date);
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id ON workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_created_at ON workout_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_id ON weight_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON weight_logs(date);
CREATE INDEX IF NOT EXISTS idx_water_intake_user_id ON water_intake(user_id);
CREATE INDEX IF NOT EXISTS idx_water_intake_date ON water_intake(date);
CREATE INDEX IF NOT EXISTS idx_step_logs_user_id ON step_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_step_logs_date ON step_logs(date);
CREATE INDEX IF NOT EXISTS idx_personal_records_user_id ON personal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_muscle_groups_category ON muscle_groups(category);
CREATE INDEX IF NOT EXISTS idx_exercise_videos_muscle_group_id ON exercise_videos(muscle_group_id);
CREATE INDEX IF NOT EXISTS idx_exercise_videos_trainer_id ON exercise_videos(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainers_rating ON trainers(rating);
CREATE INDEX IF NOT EXISTS idx_workout_programs_trainer_id ON workout_programs(trainer_id);
CREATE INDEX IF NOT EXISTS idx_workout_programs_category ON workout_programs(category);


CREATE INDEX IF NOT EXISTS idx_trainer_workouts_trainer_id ON trainer_workouts(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_workouts_published ON trainer_workouts(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_trainer_workouts_muscle_groups ON trainer_workouts USING GIN(muscle_groups);


CREATE INDEX IF NOT EXISTS idx_news_published ON news(is_published) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_news_published_at ON news(published_at DESC) WHERE is_published = true;
CREATE INDEX IF NOT EXISTS idx_news_category ON news(category);
CREATE INDEX IF NOT EXISTS idx_news_author ON news(author_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_user_stats(user_id_param UUID)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_workouts', COUNT(*),
    'total_duration', COALESCE(SUM(duration), 0),
    'total_experience', COALESCE(SUM(experience), 0),
    'total_calories', COALESCE(SUM(calories), 0),
    'current_streak', get_current_streak(user_id_param),
    'longest_streak', get_longest_streak(user_id_param),
    'tasks_completed_today', (SELECT COUNT(*) FROM daily_tasks WHERE user_id = user_id_param AND date = CURRENT_DATE AND completed = TRUE),
    'water_today', COALESCE((SELECT SUM(amount) FROM water_intake WHERE user_id = user_id_param AND date = CURRENT_DATE), 0),
    'steps_today', COALESCE((SELECT SUM(steps) FROM step_logs WHERE user_id = user_id_param AND date = CURRENT_DATE), 0)
  ) INTO stats
  FROM workout_logs 
  WHERE user_id = user_id_param;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_current_streak(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
  current_streak INTEGER;
BEGIN
  WITH consecutive_dates AS (
    SELECT DISTINCT date(created_at::date) as workout_date
    FROM workout_logs
    WHERE user_id = user_id_param
    ORDER BY workout_date DESC
  ),
  streak_calculation AS (
    SELECT 
      workout_date,
      workout_date - (ROW_NUMBER() OVER (ORDER BY workout_date DESC) - 1) * INTERVAL '1 day' as streak_start
    FROM consecutive_dates
  )
  SELECT COUNT(*) INTO current_streak
  FROM streak_calculation
  WHERE workout_date >= CURRENT_DATE - INTERVAL '1 day'
  GROUP BY streak_start
  ORDER BY COUNT(*) DESC
  LIMIT 1;
  
  RETURN COALESCE(current_streak, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_longest_streak(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
  longest_streak INTEGER;
BEGIN
  WITH consecutive_dates AS (
    SELECT DISTINCT date(created_at::date) as workout_date
    FROM workout_logs
    WHERE user_id = user_id_param
    ORDER BY workout_date DESC
  ),
  streak_calculation AS (
    SELECT 
      workout_date,
      workout_date - (ROW_NUMBER() OVER (ORDER BY workout_date DESC) - 1) * INTERVAL '1 day' as streak_start,
      ROW_NUMBER() OVER (PARTITION BY workout_date - (ROW_NUMBER() OVER (ORDER BY workout_date DESC) - 1) * INTERVAL '1 day' ORDER BY workout_date DESC) as streak_length
    FROM consecutive_dates
  )
  SELECT MAX(streak_length) INTO longest_streak
  FROM streak_calculation;
  
  RETURN COALESCE(longest_streak, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_today_progress(user_id_param UUID, date_param DATE)
RETURNS JSONB AS $$
DECLARE
  progress JSONB;
BEGIN
  SELECT jsonb_build_object(
    'workouts_completed', COUNT(*),
    'total_workout_time', COALESCE(SUM(duration), 0),
    'total_experience', COALESCE(SUM(experience), 0),
    'tasks_completed', (SELECT COUNT(*) FROM daily_tasks WHERE user_id = user_id_param AND date = date_param AND completed = TRUE),
    'total_tasks', (SELECT COUNT(*) FROM daily_tasks WHERE user_id = user_id_param AND date = date_param),
    'water_intake', COALESCE((SELECT SUM(amount) FROM water_intake WHERE user_id = user_id_param AND date = date_param), 0),
    'steps_taken', COALESCE((SELECT SUM(steps) FROM step_logs WHERE user_id = user_id_param AND date = date_param), 0)
  ) INTO progress
  FROM workout_logs 
  WHERE user_id = user_id_param AND date(created_at::date) = date_param;
  
  RETURN progress;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_trainer_workouts_updated_at') THEN
        CREATE TRIGGER update_trainer_workouts_updated_at 
            BEFORE UPDATE ON trainer_workouts 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_news_updated_at') THEN
        CREATE TRIGGER update_news_updated_at 
            BEFORE UPDATE ON news 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;


ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE water_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE news ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE user_id = auth.uid() AND role = 'admin'
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;

DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Users can view own tasks" ON daily_tasks;
CREATE POLICY "Users can view own tasks" ON daily_tasks FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own tasks" ON daily_tasks;
CREATE POLICY "Users can update own tasks" ON daily_tasks FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own tasks" ON daily_tasks;
CREATE POLICY "Users can insert own tasks" ON daily_tasks FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Users can view own workouts" ON workout_logs;
CREATE POLICY "Users can view own workouts" ON workout_logs FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own workouts" ON workout_logs;
CREATE POLICY "Users can insert own workouts" ON workout_logs FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Users can view own weight logs" ON weight_logs;
CREATE POLICY "Users can view own weight logs" ON weight_logs FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own weight logs" ON weight_logs;
CREATE POLICY "Users can insert own weight logs" ON weight_logs FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Users can view own water intake" ON water_intake;
CREATE POLICY "Users can view own water intake" ON water_intake FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own water intake" ON water_intake;
CREATE POLICY "Users can insert own water intake" ON water_intake FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Users can view own step logs" ON step_logs;
CREATE POLICY "Users can view own step logs" ON step_logs FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own step logs" ON step_logs;
CREATE POLICY "Users can insert own step logs" ON step_logs FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Users can view own records" ON personal_records;
CREATE POLICY "Users can view own records" ON personal_records FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own records" ON personal_records;
CREATE POLICY "Users can insert own records" ON personal_records FOR INSERT WITH CHECK (auth.uid() = user_id);


DROP POLICY IF EXISTS "Anyone can view published news" ON news;
CREATE POLICY "Anyone can view published news" ON news
    FOR SELECT USING (is_published = true);

DROP POLICY IF EXISTS "Admins can manage news" ON news;
CREATE POLICY "Admins can manage news" ON news
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.user_id = auth.uid() 
            AND users.role = 'admin'
        )
    );


DROP POLICY IF EXISTS "Everyone can view muscle groups" ON muscle_groups;
CREATE POLICY "Everyone can view muscle groups" ON muscle_groups FOR SELECT USING (true);
ALTER TABLE muscle_groups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage muscle groups" ON muscle_groups;
CREATE POLICY "Admins can manage muscle groups" ON muscle_groups
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());



DROP POLICY IF EXISTS "Everyone can view exercise videos" ON exercise_videos;
CREATE POLICY "Everyone can view exercise videos" ON exercise_videos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Everyone can view trainers" ON trainers;
CREATE POLICY "Everyone can view trainers" ON trainers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Everyone can view published workout programs" ON workout_programs;
CREATE POLICY "Everyone can view published workout programs" ON workout_programs FOR SELECT USING (is_published = true);

DROP POLICY IF EXISTS "Trainers can manage own exercise videos" ON exercise_videos;
CREATE POLICY "Trainers can manage own exercise videos" ON exercise_videos
    FOR ALL USING (
        auth.uid() = trainer_id OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.user_id = auth.uid() 
            AND users.role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can update all users" ON users;
CREATE POLICY "Admins can update all users" ON users
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin() AND role IN ('user', 'trainer'));


INSERT INTO muscle_groups (name, description, category, icon, color, exercises) VALUES

('Массаж', 'Общий массаж для развития мышц и кровообращения', 'infants', 'spa', '#FF69B4', '["Поглаживание", "Растирание", "Разминание", "Вибрация"]'),
('Гимнастика', 'Базовая гимнастика для развития моторики', 'infants', 'child_care', '#9370DB', '["Пассивные упражнения", "Активные движения", "Координация"]'),
('Рефлексы', 'Упражнения для развития врожденных рефлексов', 'infants', 'psychology', '#4B0082', '["Ползание", "Хватание", "Перевороты", "Сидение"]'),
('Водные процедуры', 'Плавание и водные занятия для развития', 'infants', 'pool', '#0000FF', '["Плавание с кругом", "Ныряние", "Игра в воде", "Движение в воде"]'),

('Спина', 'Укрепление мышц спины для поддержки позвоночника', 'basic', 'accessibility', '#0000FF', '["Кошка-корова", "Планка на предплечьях", "Мостик"]'),
('Тазовое дно', 'Упражнения Кегеля для укрепления мышц тазового дна', 'basic', 'favorite', '#FF69B4', '["Сжатие и расслабление", "Удержание", "Быстрые сокращения"]'),

('Грудь', 'Развитие грудных мышц', 'standard', 'fitness_center', '#FF0000', '["Отжимания", "Жим лежа", "Разводка гантелей"]'),
('Спина', 'Мощные мышцы спины', 'standard', 'accessibility', '#0000FF', '["Подтягивания", "Тяга штанги", "Горизонтальная тяга"]'),

('Осанка', 'Улучшение осанки и гибкости', 'gentle', 'accessibility_new', '#00FFFF', '["Наклоны", "Растяжка", "Планка у стены"]'),
('Баланс', 'Улучшение баланса и координации', 'gentle', 'balance', '#008000', '["Стояние на одной ноге", "Ходьба по линии", "Тайчи"]')
ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "Trainers can manage own workouts" ON trainer_workouts;
CREATE POLICY "Trainers can manage own workouts" ON trainer_workouts
    FOR ALL USING (
        auth.uid() = trainer_id OR
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.user_id = auth.uid() 
            AND users.role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Everyone can view published workouts" ON trainer_workouts;
CREATE POLICY "Everyone can view published workouts" ON trainer_workouts
    FOR SELECT USING (is_published = true);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    user_id,
    email,
    name,
    age,
    gender,
    height,
    weight,
    fitness_goal,
    total_experience,
    current_level,
    profile_completed,
    role,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data ->> 'name',
      split_part(COALESCE(NEW.email, ''), '@', 1),
      'Пользователь'
    ),
    18,
    'male',
    170.0,
    70.0,
    'general_fitness',
    0,
    1,
    FALSE,
    'user',
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

INSERT INTO public.users (
  user_id,
  email,
  name,
  age,
  gender,
  height,
  weight,
  fitness_goal,
  total_experience,
  current_level,
  profile_completed,
  role,
  created_at
)
SELECT
  au.id,
  au.email,
  COALESCE(
    au.raw_user_meta_data ->> 'name',
    split_part(COALESCE(au.email, ''), '@', 1),
    'Пользователь'
  ),
  18,
  'male',
  170.0,
  70.0,
  'general_fitness',
  0,
  1,
  FALSE,
  'user',
  COALESCE(au.created_at, NOW())
FROM auth.users AS au
LEFT JOIN public.users AS u ON u.user_id = au.id
WHERE u.user_id IS NULL;

UPDATE news
SET published_at = created_at
WHERE is_published = true
  AND published_at IS NULL;

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
