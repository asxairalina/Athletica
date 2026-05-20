import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/navigation_service.dart';
import 'services/task_service.dart';
import 'services/workout_streak_service.dart';
import 'services/progress_service.dart';
import 'services/analytics_service.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'widgets/avatar_dropdown.dart';
import 'config/supabase_config.dart';

// Глобальная переменная для отслеживания инициализации
bool _isSupabaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Простая инициализация Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    await SupabaseService().initialize();
    print('Supabase initialized');
    _isSupabaseReady = true;
  } catch (e) {
    print('Supabase init error: $e');
    _isSupabaseReady = true; // Все равно запускаем
  }
  
  runApp(const AthleticaApp());
}

class AthleticaApp extends StatelessWidget {
  const AthleticaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Athletica',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// AuthWrapper для проверки аутентификации
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {

  Future<void> _createBasicUserIfNeeded(String userId, String email) async {
    try {
      await SupabaseService().createBasicUser(userId, email);
    } catch (e) {
      print('Error creating basic user in AuthWrapper: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Показываем экран входа по умолчанию
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthScreen();
        }

        final session = snapshot.data?.session;
        
        if (session != null) {
          // Пользователь авторизован, проверяем профиль
          print('User authenticated: ${session.user.id}, email: ${session.user.email}');
          
          return FutureBuilder(
            future: Supabase.instance.client
                .from('users')
                .select()
                .eq('user_id', session.user.id)
                .maybeSingle(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (profileSnapshot.hasError) {
                print('Error checking user profile: ${profileSnapshot.error}');
                return Scaffold(
                  body: Center(
                    child: Text('Ошибка проверки профиля: ${profileSnapshot.error}'),
                  ),
                );
              }

              final user = profileSnapshot.data;
              print('User profile found: $user');
              
              if (user == null) {
                // Пользователь не найден в таблице, создаем базового и показываем экран профиля
                return FutureBuilder(
                  future: _createBasicUserIfNeeded(session.user.id, session.user.email ?? ''),
                  builder: (context, createSnapshot) {
                    if (createSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (createSnapshot.hasError) {
                      return Scaffold(
                        body: Center(
                          child: Text('Ошибка: ${createSnapshot.error}'),
                        ),
                      );
                    }
                    return const ProfileSetupScreen();
                  },
                );
              } else if (user['profile_completed'] == false) {
                // Профиль не завершен, показываем экран создания профиля
                return const ProfileSetupScreen();
              } else {
                // Профиль завершен, показываем главное приложение
                return const MainScreen();
              }
            },
          );
        } else {
          // Пользователь не авторизован, показываем экран входа
          return const AuthScreen();
        }
      },
    );
  }
}

// Глобальный ключ для доступа к MainScreen
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TasksScreen(),
    const AnalyticsScreen(),
    const WorkoutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Слушаем изменения из NavigationService
    NavigationService.addListener(() {
      if (mounted) {
        setState(() {
          _currentIndex = NavigationService.currentIndexNotifier.value;
        });
      }
    });

    _initUserSession();
  }

  Future<void> _initUserSession() async {
    final userChanged = await TaskService.initializeDailyTasks();
    if (userChanged) {
      ProgressService.resetDailyProgress();
    }
  }

  @override
  void dispose() {
    NavigationService.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Athletica',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Athletica'),
              actions: const [
                AvatarDropdown(),
              ],
            ),
            body: ValueListenableBuilder<int>(
              valueListenable: NavigationService.currentIndexNotifier,
              builder: (context, currentIndex, child) {
                return _screens[currentIndex];
              },
            ),
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: NavigationService.currentIndexNotifier,
              builder: (context, currentIndex, child) {
                return BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) {
                    NavigationService.switchToTab(index);
                  },
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.check_circle),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.insights),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.fitness_center),
                      label: '',
                    ),
                  ],
                );
              },
            ),
          ),
          routes: {
            '/workout': (context) => const WorkoutScreen(),
            '/main': (context) => const MainScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
