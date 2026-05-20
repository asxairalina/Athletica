
DO $$
DECLARE
  v_email TEXT := 'укажи email основного пользователя';
  v_user_id UUID;
  v_day DATE;
  v_start DATE := (CURRENT_DATE - INTERVAL '30 days')::DATE;
  v_workout_at TIMESTAMPTZ;
  v_duration INT;
  v_calories INT;
  v_experience INT;
  v_muscle TEXT;
  v_type TEXT;
  v_total_xp INT := 0;
  v_base_weight NUMERIC(5,2);
  v_groups TEXT[] := ARRAY[
    'Грудь', 'Спина', 'Тазовое дно', 'Осанка', 'Баланс', 'Гимнастика'
  ];
  v_types TEXT[] := ARRAY[
    'Силовая тренировка', 'Кардио', 'Растяжка', 'Видео-тренировка', 'Комплекс'
  ];
  v_dow INT;
  v_train BOOLEAN;
  v_slot INT;
BEGIN
  SELECT u.user_id, COALESCE(u.weight, 70.0)
  INTO v_user_id, v_base_weight
  FROM public.users u
  WHERE lower(u.email) = lower(v_email)
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Пользователь с email % не найден в public.users. Зарегистрируйтесь в приложении или проверьте email.', v_email;
  END IF;

  DELETE FROM public.workout_logs
  WHERE user_id = v_user_id
    AND created_at >= v_start::TIMESTAMPTZ;

  DELETE FROM public.weight_logs
  WHERE user_id = v_user_id
    AND date >= v_start;

  v_day := v_start;
  WHILE v_day <= CURRENT_DATE LOOP
    v_dow := EXTRACT(DOW FROM v_day)::INT;
    v_train := (
      v_dow IN (1, 2, 4, 5)
      OR (v_dow = 6 AND EXTRACT(DAY FROM v_day)::INT % 2 = 0)
      OR v_day >= CURRENT_DATE - 2
    );

    IF v_train THEN
      v_slot := (EXTRACT(DAY FROM v_day)::INT % array_length(v_groups, 1)) + 1;
      v_muscle := v_groups[v_slot];
      v_type := v_types[1 + (EXTRACT(DAY FROM v_day)::INT % array_length(v_types, 1))];
      v_duration := 1500 + (EXTRACT(DAY FROM v_day)::INT % 25) * 60;
      v_calories := (v_duration / 60) * (9 + (EXTRACT(DAY FROM v_day)::INT % 4));
      v_experience := 55 + (EXTRACT(DAY FROM v_day)::INT % 12) * 10;
      v_workout_at := (
        v_day::timestamp
        + make_interval(hours => 10 + (EXTRACT(DAY FROM v_day)::INT % 8))
      )::timestamptz;

      INSERT INTO public.workout_logs (
        user_id,
        workout_type,
        muscle_group,
        duration,
        experience,
        calories,
        created_at
      ) VALUES (
        v_user_id,
        v_type,
        v_muscle,
        v_duration,
        v_experience,
        v_calories,
        v_workout_at
      );

      v_total_xp := v_total_xp + v_experience;

      IF EXTRACT(DAY FROM v_day)::INT % 7 = 0 THEN
        INSERT INTO public.weight_logs (user_id, weight, date)
        VALUES (
          v_user_id,
          v_base_weight - ((CURRENT_DATE - v_day) * 0.15),
          v_day
        );
      END IF;
    END IF;

    v_day := v_day + 1;
  END LOOP;

  UPDATE public.users
  SET
    total_experience = GREATEST(total_experience, v_total_xp),
    current_level = GREATEST(
      current_level,
      CASE
        WHEN v_total_xp >= 5000 THEN 6
        WHEN v_total_xp >= 3000 THEN 5
        WHEN v_total_xp >= 1500 THEN 4
        WHEN v_total_xp >= 800 THEN 3
        WHEN v_total_xp >= 300 THEN 2
        ELSE 1
      END
    ),
    updated_at = NOW()
  WHERE user_id = v_user_id;

  RAISE NOTICE 'Готово: user_id=%, тренировок за период ~%, опыт +%',
    v_user_id,
    (SELECT COUNT(*) FROM public.workout_logs WHERE user_id = v_user_id AND created_at >= v_start::TIMESTAMPTZ),
    v_total_xp;
END $$;
