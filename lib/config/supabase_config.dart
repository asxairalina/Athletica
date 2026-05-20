class SupabaseConfig {
  
  static const String supabaseUrl = 'url проекта супабейз';

  static const String supabaseAnonKey = 'settings- API keys - Legacy... - anon public';

  static const String usersTable = 'users';
  static const String dailyTasksTable = 'daily_tasks';
  static const String workoutLogsTable = 'workout_logs';
  static const String weightLogsTable = 'weight_logs';
  static const String waterIntakeTable = 'water_intake';
  static const String stepLogsTable = 'step_logs';
  static const String personalRecordsTable = 'personal_records';
  static const String muscleGroupsTable = 'muscle_groups';
  static const String exerciseVideosTable = 'exercise_videos';

  static const String getUserStatsFunction = 'get_user_stats';
  static const String getCurrentStreakFunction = 'get_current_streak';
  static const String getLongestStreakFunction = 'get_longest_streak';
  static const String getTodayProgressFunction = 'get_today_progress';

  static const String localStorageKey = 'supabase.auth.token';

  static const String redirectUrl = 'io.supabase.athletica://login-callback';
}
