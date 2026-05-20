CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.seed_trainer_auth_user(
  p_user_id uuid,
  p_email text,
  p_password text,
  p_name text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    RAISE NOTICE 'Уже есть: %', p_email;
    RETURN;
  END IF;

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    p_user_id,
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('name', p_name),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  );

  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    p_user_id,
    jsonb_build_object('sub', p_user_id::text, 'email', p_email),
    'email',
    p_user_id::text,
    NOW(),
    NOW(),
    NOW()
  );
END;
$$;

SELECT public.seed_trainer_auth_user(
  'a1000001-0001-4001-8001-000000000001'::uuid,
  'trainer1@athletica.local',
  'Trainer123!',
  'Александр Иванов'
);

SELECT public.seed_trainer_auth_user(
  'a1000002-0002-4002-8002-000000000002'::uuid,
  'trainer2@athletica.local',
  'Trainer123!',
  'Мария Петрова'
);

SELECT public.seed_trainer_auth_user(
  'a1000003-0003-4003-8003-000000000003'::uuid,
  'trainer3@athletica.local',
  'Trainer123!',
  'Дмитрий Сидоров'
);

SELECT public.seed_trainer_auth_user(
  'a1000004-0004-4004-8004-000000000004'::uuid,
  'trainer4@athletica.local',
  'Trainer123!',
  'Елена Козлова'
);

SELECT public.seed_trainer_auth_user(
  'a1000005-0005-4005-8005-000000000005'::uuid,
  'trainer5@athletica.local',
  'Trainer123!',
  'Иван Смирнов'
);

UPDATE public.users
SET
  role = 'trainer',
  profile_completed = TRUE,
  fitness_goal = 'general_fitness',
  total_experience = 500,
  current_level = 3
WHERE email IN (
  'trainer1@athletica.local',
  'trainer2@athletica.local',
  'trainer3@athletica.local',
  'trainer4@athletica.local',
  'trainer5@athletica.local'
);

UPDATE public.users
SET gender = 'female'
WHERE email IN ('trainer2@athletica.local', 'trainer4@athletica.local');

INSERT INTO public.users (
  user_id, email, name, age, gender, height, weight,
  fitness_goal, total_experience, current_level,
  profile_completed, role, created_at
)
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data ->> 'name', split_part(au.email, '@', 1)),
  28,
  'male',
  175.0,
  75.0,
  'general_fitness',
  500,
  3,
  TRUE,
  'trainer',
  NOW()
FROM auth.users AS au
WHERE au.email IN (
  'trainer1@athletica.local',
  'trainer2@athletica.local',
  'trainer3@athletica.local',
  'trainer4@athletica.local',
  'trainer5@athletica.local'
)
ON CONFLICT (user_id) DO UPDATE SET
  role = EXCLUDED.role,
  profile_completed = EXCLUDED.profile_completed,
  name = EXCLUDED.name,
  total_experience = EXCLUDED.total_experience,
  current_level = EXCLUDED.current_level;

DROP FUNCTION IF EXISTS public.seed_trainer_auth_user(uuid, text, text, text);

SELECT user_id, email, name, role, profile_completed
FROM public.users
WHERE role = 'trainer'
ORDER BY email;
