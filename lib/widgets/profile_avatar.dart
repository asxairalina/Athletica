import 'package:flutter/material.dart';

/// Аватар пользователя с буквой-заглушкой при отсутствии фото.
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    this.radius = 40,
  });

  String? get _imageUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    final uri = Uri.tryParse(avatarUrl!);
    if (uri == null) return avatarUrl;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final imageUrl = _imageUrl;
    final size = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(initial),
              ),
            )
          : _initials(initial),
    );
  }

  Widget _initials(String initial) {
    return Text(
      initial,
      style: TextStyle(
        fontSize: radius * 0.6,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
