import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import '../main.dart';

class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() => _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _isConfirmed = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkEmailConfirmation();
  }

  Future<void> _checkEmailConfirmation() async {
    try {
      // Проверяем статус подтверждения email
      await Future.delayed(const Duration(seconds: 2)); // Даем время на обработку deep link
      
      final user = SupabaseService().client.auth.currentUser;
      if (user != null && user.emailConfirmedAt != null) {
        setState(() {
          _isConfirmed = true;
          _isLoading = false;
        });
        
        // Через 2 секунды переходим на главный экран
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Email не подтвержден. Пожалуйста, проверьте вашу почту.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка проверки подтверждения: $e';
      });
    }
  }

  Future<void> _resendConfirmationEmail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SupabaseService().client.auth.resend(
        type: OtpType.signup,
        email: SupabaseService().client.auth.currentUser?.email ?? '',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Письмо подтверждения отправлено повторно'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка отправки письма: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение email'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Проверка подтверждения email...'),
              ] else if (_isConfirmed) ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Email подтвержден!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Перенаправление в приложение...'),
              ] else ...[
                const Icon(
                  Icons.email,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Подтвердите ваш email',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Мы отправили вам письмо со ссылкой для подтверждения. '
                  'Пожалуйста, откройте его и перейдите по ссылке.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : _resendConfirmationEmail,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Отправить письмо повторно'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const AuthScreen()),
                    );
                  },
                  child: const Text('Вернуться к входу'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
