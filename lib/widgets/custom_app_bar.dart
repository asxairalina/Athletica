import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.avatarUrl,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      centerTitle: false,
      actions: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(context);
                      },
                    ),
                  )
                : _buildDefaultAvatar(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Icon(
      Icons.person,
      size: 24,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
