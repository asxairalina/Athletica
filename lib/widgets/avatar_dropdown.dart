import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../services/supabase_service.dart';
import '../models/supabase_models.dart';
import 'profile_avatar.dart';

class AvatarDropdown extends StatefulWidget {
  const AvatarDropdown({super.key});

  @override
  State<AvatarDropdown> createState() => _AvatarDropdownState();
}

class _AvatarDropdownState extends State<AvatarDropdown> {
  UserProfile? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await SupabaseService().getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onOpened: _loadUserProfile,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: ProfileAvatar(
          avatarUrl: _currentUser?.avatarPath,
          displayName: _currentUser?.name ?? '',
          radius: 18,
        ),
      ),
      onSelected: (String value) {
        switch (value) {
          case 'profile':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) => _loadUserProfile());
            break;
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Профиль'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Настройки'),
            ],
          ),
        ),
      ],
    );
  }
}
