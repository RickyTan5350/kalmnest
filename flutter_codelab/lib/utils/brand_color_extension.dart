import 'package:flutter/material.dart';
import '../theme.dart';

extension BrandColorExtension on BuildContext {
  Color getBrandColorForTopic(String topic) {
    final brandColors = Theme.of(this).extension<BrandColors>();
    if (brandColors == null) return Theme.of(this).colorScheme.primary;

    switch (topic.toUpperCase()) {
      case 'HTML':
        return brandColors.html;
      case 'CSS':
        return brandColors.css;
      case 'JS':
      case 'JAVASCRIPT':
        return brandColors.javascript;
      case 'PHP':
        return brandColors.php;
      default:
        // Use 'other' or fallback to primary if 'other' isn't what we want
        return brandColors.other; // or Theme.of(this).colorScheme.primary;
    }
  }
}
