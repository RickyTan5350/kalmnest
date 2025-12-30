// lib/widgets/achievement_grid_layout.dart
import 'package:flutter/material.dart';
import 'package:code_play/admin_teacher/widgets/achievements/admin_achievement_detail.dart';
import 'package:code_play/admin_teacher/widgets/grid_layout_view.dart';
import 'package:code_play/models/achievement_data.dart';
// FIX 1: Import the correctly named unified grid file

class AchievementGridLayout extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final List<AchievementData> originalData;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelection;
  final Map<String, GlobalKey> itemKeys;
  final String? currentUserId; // NEW
  final bool isAdmin; // NEW

  // This is the callback from the Student View
  final void Function(String)? onTap;

  const AchievementGridLayout({
    super.key,
    required this.achievements,
    required this.originalData,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.itemKeys,
    this.currentUserId,
    this.isAdmin = false,
    this.onTap,
  });

  // Helper to find the original AchievementData by its ID (String)
  AchievementData? _findOriginalDataById(String id) {
    try {
      return originalData.firstWhere((data) => data.achievementId == id);
    } catch (e) {
      return null;
    }
  }

  // Custom builder for Achievement card content
  Widget _buildAchievementCardContent(
    BuildContext context,
    Map<String, dynamic> item,
    dynamic id,
    GlobalKey key,
  ) {
    final String title = item['title'];
    final IconData icon = item['icon'];
    final Color color = item['color'];
    final String? preview = item['preview'];

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(icon, color: color.withOpacity(0.1)),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 4.0, 8.0),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Only show "more" icon if we are in Admin mode (no custom tap handler)
                  if (onTap == null)
                    const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  preview ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['unlockedCount'] != null &&
                            item['totalStudents'] != null)
                          Text(
                            '${item['unlockedCount']} / ${item['totalStudents']} Students',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (item['unlockedCount'] != null &&
                      item['totalStudents'] != null &&
                      item['totalStudents'] > 0)
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0.0,
                          end:
                              (item['unlockedCount'] as int) /
                              (item['totalStudents'] as int),
                        ),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 3,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridViewLayout(
      items: achievements,
      selectedIds: selectedIds.cast<dynamic>(),
      onToggleSelection: (dynamic id) => onToggleSelection(id as String),
      itemKeys: itemKeys.cast<dynamic, GlobalKey>(),
      module: GridModule.achievement,
      itemBuilder: _buildAchievementCardContent,

      // FIX 2: Check if onTap is provided (Student View) before using default Admin logic
      onTap: (dynamic id) {
        if (onTap != null) {
          // Case A: Student View (Use the passed callback)
          onTap!(id as String);
        } else {
          // Case B: Admin View (Use default navigation)
          final AchievementData? fullData = _findOriginalDataById(id as String);

          if (fullData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminAchievementDetailPage(
                  initialData: fullData,
                  currentUserId: currentUserId, // NEW
                  isAdmin: isAdmin, // NEW
                ),
              ),
            );
          }
        }
      },
    );
  }
}

