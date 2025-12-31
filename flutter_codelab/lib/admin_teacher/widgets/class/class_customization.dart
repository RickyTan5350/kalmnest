import 'package:flutter/material.dart';

/// Class customization utilities for colors and themes
class ClassCustomization {
  /// Get color by name from BrandColors extension
  /// Returns a ColorSwatch-like object with the color property
  static _ColorSwatchWrapper? getColorByName(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return null;
    }

    // Map color names to BrandColors values
    final colorMap = {
      'html': const Color(0xFFFF9800), // Orange
      'css': const Color(0xFF4CAF50), // Green
      'javascript': const Color(0xFFFFEB3B), // Yellow
      'js': const Color(0xFFFFEB3B), // Yellow (alias)
      'php': const Color(0xFF2196F3), // Blue
    };

    final normalizedName = colorName.toLowerCase();
    final color = colorMap[normalizedName];

    if (color == null) {
      return null;
    }

    // Return a wrapper object with the color property
    return _ColorSwatchWrapper(color);
  }
}

/// Wrapper class to provide color property
class _ColorSwatchWrapper {
  final Color color;
  _ColorSwatchWrapper(this.color);
}

