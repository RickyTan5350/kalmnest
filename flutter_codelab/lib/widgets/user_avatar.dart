import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String role;
  final double size;
  final double fontSize;
  final ImageProvider? backgroundImage;

  const UserAvatar({
    super.key,
    required this.name,
    required this.role,
    this.size = 40.0,
    this.fontSize = 16.0,
    this.backgroundImage,
  });

  Color _getRoleColor(String role, ColorScheme scheme) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.pink;
      case 'teacher':
        return Colors.orange;
      case 'student':
        return Colors.blue;
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final roleColor = _getRoleColor(role, colorScheme);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roleColor.withOpacity(0.25), roleColor.withOpacity(0.05)],
        ),
        border: Border.all(color: roleColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: roleColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        image: backgroundImage != null
            ? DecorationImage(image: backgroundImage!, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: backgroundImage == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: fontSize,
                color: roleColor,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
