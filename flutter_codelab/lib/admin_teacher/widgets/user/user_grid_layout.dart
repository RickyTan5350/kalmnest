import 'package:flutter/material.dart';
import 'package:code_play/admin_teacher/widgets/grid_layout_view.dart';
import 'package:code_play/widgets/user_avatar.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class UserGridLayout extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Set<dynamic> selectedIds;
  final void Function(dynamic) onToggleSelection;
  final Map<dynamic, GlobalKey> itemKeys;
  final void Function(dynamic)? onTap;

  const UserGridLayout({
    super.key,
    required this.users,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.itemKeys,
    this.onTap,
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

  String _getLocalizedRole(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role.toLowerCase()) {
      case 'student':
        return l10n.student;
      case 'teacher':
        return l10n.teacher;
      case 'admin':
        return l10n.admin;
      default:
        return role;
    }
  }

  String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.active;
      case 'inactive':
        return l10n.inactive;
      default:
        return status;
    }
  }

  Widget _buildUserCardContent(
    BuildContext context,
    Map<String, dynamic> item,
    dynamic id,
    GlobalKey key,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String name = item['name'] ?? 'Unknown';
    final String role = item['role'] ?? 'Student';
    final String email = item['email'] ?? '';
    final String status = item['status'] ?? 'inactive';

    final roleColor = _getRoleColor(role, colorScheme);

    return Stack(
      children: [
        // 1. Background Effect (Role Icon Faded)
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(Icons.person, color: roleColor.withOpacity(0.05)),
            ),
          ),
        ),

        // 2. Foreground Content
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Status
              Row(
                children: [
                  UserAvatar(name: name, role: role, size: 32, fontSize: 14),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? Colors.green.withOpacity(0.1)
                          : colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: status == 'active'
                            ? Colors.green
                            : colorScheme.error,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _getLocalizedStatus(context, status).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: status == 'active'
                            ? Colors.green
                            : colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name & Role
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getLocalizedRole(context, role),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: roleColor,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              // Email at bottom
              if (email.isNotEmpty)
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridViewLayout(
      items: users,
      selectedIds: selectedIds,
      onToggleSelection: onToggleSelection,
      itemKeys: itemKeys,
      module: GridModule.user, // Ensure this key exists in your GridModule enum
      itemBuilder: _buildUserCardContent,
      onTap: onTap,
    );
  }
}
