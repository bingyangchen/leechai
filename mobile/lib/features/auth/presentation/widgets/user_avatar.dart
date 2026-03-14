import 'package:flutter/material.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, required this.size});

  final AuthState user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = user.avatarUrl;

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(url),
        backgroundColor: colorScheme.surfaceContainerHighest,
      );
    }

    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : user.email.isNotEmpty
        ? user.email[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
