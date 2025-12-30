import 'package:flutter/material.dart';
import 'package:code_play/theme.dart'; // Import for BrandColors
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/enums/sort_enums.dart';

final List<Map<String, dynamic>> achievementIconOptions = [
  // Web Development Languages
  {'display': 'HTML', 'value': 'html', 'icon': Icons.html},
  {'display': 'CSS', 'value': 'css', 'icon': Icons.css},
  {'display': 'JavaScript', 'value': 'javascript', 'icon': Icons.javascript},

  // Server-side Language
  {'display': 'PHP', 'value': 'php', 'icon': Icons.php},

  {'display': 'Quiz/Test', 'value': 'quiz', 'icon': Icons.quiz},

  // Add more icons here
];

Color getAchievementColor(BuildContext context, String? iconValue) {
  final brandColors = Theme.of(context).extension<BrandColors>();
  final colorScheme = Theme.of(context).colorScheme;

  // Fallback if extension not found (safety)
  if (brandColors == null) {
    switch (iconValue) {
      case 'html':
        return Colors.orange;
      case 'css':
        return Colors.green;
      case 'javascript':
        return Colors.yellow;
      case 'php':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  switch (iconValue) {
    case 'html':
      return brandColors.html;
    case 'css':
      return brandColors.css;
    case 'javascript':
      return brandColors.javascript;
    case 'php':
      return brandColors.php;

    default:
      return brandColors.other;
  }
}

IconData getAchievementIcon(String? iconValue) {
  try {
    final entry = achievementIconOptions.firstWhere(
      (opt) => opt['value'] == iconValue,
      orElse: () => {'icon': Icons.help_outline},
    );
    return entry['icon'] as IconData;
  } catch (e) {
    return Icons.help_outline;
  }
}

List<AchievementData> filterAchievements({
  required List<AchievementData> achievements,
  required String searchText,
  required String? selectedTopic,
  String? currentUserId,
}) {
  return achievements.where((item) {
    final String title = item.achievementTitle?.toLowerCase() ?? '';
    final String description = item.achievementDescription?.toLowerCase() ?? '';
    final String icon = item.icon?.toLowerCase() ?? '';

    final isMatchingSearch =
        searchText.isEmpty ||
        title.contains(searchText) ||
        description.contains(searchText);

    bool isMatchingTopic = true;
    if (selectedTopic == 'Created by Me') {
      // Filter by creator ID
      if (currentUserId != null) {
        isMatchingTopic = item.creatorId.toString() == currentUserId.toString();
      }
    } else if (selectedTopic == 'Unlocked') {
      isMatchingTopic = item.isUnlocked;
    } else if (selectedTopic == 'Locked') {
      isMatchingTopic = !item.isUnlocked;
    } else {
      isMatchingTopic =
          selectedTopic == null ||
          icon.contains(selectedTopic.toLowerCase()) ||
          (selectedTopic.toLowerCase() == 'quiz');
    }

    return isMatchingSearch && isMatchingTopic;
  }).toList();
}

List<AchievementData> sortAchievements({
  required List<AchievementData> achievements,
  required SortType sortType,
  required SortOrder sortOrder,
}) {
  final sortedList = List<AchievementData>.from(achievements);
  sortedList.sort((a, b) {
    int result = 0;
    switch (sortType) {
      case SortType.alphabetical:
        result = (a.achievementTitle ?? '').compareTo(b.achievementTitle ?? '');
        break;
      case SortType.updated:
        // Sort by creation date (used as "Obtained Date" for students)
        final dateA = a.createdAt ?? DateTime(0);
        final dateB = b.createdAt ?? DateTime(0);
        result = dateA.compareTo(dateB);
        break;
      case SortType.unlocked:
        // Sort by unlocked status (unlocked first)
        final unlockedA = a.isUnlocked ? 1 : 0;
        final unlockedB = b.isUnlocked ? 1 : 0;
        result = unlockedB.compareTo(unlockedA); // Descending (1 before 0)
        break;
    }
    if (sortOrder == SortOrder.descending) {
      result = -result;
    }
    return result;
  });
  return sortedList;
}

