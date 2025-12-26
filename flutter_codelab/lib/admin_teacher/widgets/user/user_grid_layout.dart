import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/grid_layout_view.dart';
import 'package:flutter_codelab/theme.dart';

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
        return Colors.purple;
      case 'teacher':
        return scheme.tertiary;
      case 'student':
        return scheme.primary;
      default:
        return scheme.secondary;
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: roleColor.withOpacity(0.2),
                    foregroundColor: roleColor,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
                      status.toUpperCase(),
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
                  role,
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
      childAspectRatio: 0.85, // Adjust for User card height
    );
  }
}
