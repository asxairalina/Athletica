class SupabaseConfig {
  
  static const String supabaseUrl = 'https://qomalcidofhankteklbc.supabase.co';

  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFvbWFsY2lkb2ZoYW5rdGVrbGJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNDE0MTUsImV4cCI6MjA5NjkxNzQxNX0.YWnoAlpA-L6Xhdqn5-vNw_F0elFQf3YYoG7MbRPjKsM';

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
