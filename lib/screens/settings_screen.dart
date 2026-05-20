import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSection(context),
          const SizedBox(height: 24),
          _buildNotificationsSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Внешний вид',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Темная тема'),
                  subtitle: const Text('Использовать темную цветовую схему'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Тема изменена на ${value ? "темную" : "светлую"}')),
                    );
                  },
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Уведомления',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Напоминания о тренировках'),
              subtitle: const Text('Получать уведомления о тренировках'),
              value: true,
              onChanged: (value) {
                // TODO: Реализовать настройки уведомлений
              },
              secondary: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SwitchListTile(
              title: const Text('Напоминания о питании'),
              subtitle: const Text('Получать уведомления о приеме пищи'),
              value: false,
              onChanged: (value) {
                // TODO: Реализовать настройки уведомлений
              },
              secondary: Icon(
                Icons.restaurant,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'О приложении',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Версия'),
              subtitle: const Text('1.0.0'),
            ),
            ListTile(
              leading: Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Условия использования'),
              onTap: () {
                // TODO: Открыть условия использования
              },
            ),
            ListTile(
              leading: Icon(
                Icons.privacy_tip,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Политика конфиденциальности'),
              onTap: () {
                // TODO: Открыть политику конфиденциальности
              },
            ),
          ],
        ),
      ),
    );
  }
}
