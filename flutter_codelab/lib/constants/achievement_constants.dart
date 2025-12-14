import 'package:flutter/material.dart';
import 'package:flutter_codelab/theme.dart'; // Import for BrandColors

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
      case 'html': return Colors.orange;
      case 'css': return Colors.green;
      case 'javascript': return Colors.yellow;
      case 'php': return Colors.blue; 
      case 'backend': return Colors.deepPurple;
      default: return Colors.grey;
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
