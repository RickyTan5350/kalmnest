import 'package:flutter/material.dart';
import 'package:flutter_codelab/theme.dart'; // Import for BrandColors
import 'package:flutter_codelab/models/achievement_data.dart';
import 'package:flutter_codelab/enums/sort_enums.dart';

final List<Map<String, dynamic>> achievementIconOptions = [
  // Web Development Languages
  {'display': 'HTML', 'value': 'html', 'icon': Icons.html},
  {'display': 'CSS', 'value': 'css', 'icon': Icons.css},
  {'display': 'JavaScript', 'value': 'javascript', 'icon': Icons.javascript},

  // Server-side Language
  {'display': 'PHP', 'value': 'php', 'icon': Icons.php},

  // Development Areas
  {'display': 'Backend', 'value': 'backend', 'icon': Icons.storage},
  {'display': 'Frontend', 'value': 'frontend', 'icon': Icons.monitor},

  // Custom Concepts
  {'display': 'Level/Progress', 'value': 'level', 'icon': Icons.assessment},
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
      case 'backend':
        return Colors.deepPurple;
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
    case 'backend':
      return brandColors.backend;
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
}) {
  return achievements.where((item) {
    final String title = item.achievementTitle?.toLowerCase() ?? '';
    final String description = item.achievementDescription?.toLowerCase() ?? '';
    final String icon = item.icon?.toLowerCase() ?? '';
    final String level = item.levelName?.toLowerCase() ?? '';

    final isMatchingSearch =
        searchText.isEmpty ||
        title.contains(searchText) ||
        description.contains(searchText);

    final isMatchingTopic =
        selectedTopic == null ||
        icon.contains(selectedTopic) ||
        (selectedTopic == 'level' && level.isNotEmpty) ||
        (selectedTopic == 'quiz');

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
    }
    if (sortOrder == SortOrder.descending) {
      result = -result;
    }
    return result;
  });
  return sortedList;
}
