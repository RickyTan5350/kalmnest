// Class customization utilities - colors and icons
import 'package:flutter/material.dart';

class ClassCustomization {
  // Available colors (7 colors)
  static const List<ClassColor> availableColors = [
    ClassColor(name: 'blue', color: Colors.blue, displayName: 'Blue'),
    ClassColor(name: 'red', color: Colors.red, displayName: 'Red'),
    ClassColor(name: 'green', color: Colors.green, displayName: 'Green'),
    ClassColor(name: 'orange', color: Colors.orange, displayName: 'Orange'),
    ClassColor(name: 'purple', color: Colors.purple, displayName: 'Purple'),
    ClassColor(name: 'teal', color: Colors.teal, displayName: 'Teal'),
    ClassColor(name: 'pink', color: Colors.pink, displayName: 'Pink'),
  ];

  // Available icons (7 icons)
  static const List<ClassIcon> availableIcons = [
    ClassIcon(name: 'school_rounded', icon: Icons.school_rounded, displayName: 'School'),
    ClassIcon(name: 'book_rounded', icon: Icons.book_rounded, displayName: 'Book'),
    ClassIcon(name: 'science_rounded', icon: Icons.science_rounded, displayName: 'Science'),
    ClassIcon(name: 'computer_rounded', icon: Icons.computer_rounded, displayName: 'Computer'),
    ClassIcon(name: 'music_note_rounded', icon: Icons.music_note_rounded, displayName: 'Music'),
    ClassIcon(name: 'palette_rounded', icon: Icons.palette_rounded, displayName: 'Art'),
    ClassIcon(name: 'calculate_rounded', icon: Icons.calculate_rounded, displayName: 'Math'),
  ];

  // Get color by name
  static ClassColor? getColorByName(String? name) {
    if (name == null) return availableColors[0];
    return availableColors.firstWhere(
      (c) => c.name == name,
      orElse: () => availableColors[0],
    );
  }

  // Get icon by name
  static ClassIcon? getIconByName(String? name) {
    if (name == null) return availableIcons[0];
    return availableIcons.firstWhere(
      (i) => i.name == name,
      orElse: () => availableIcons[0],
    );
  }
}

class ClassColor {
  final String name;
  final Color color;
  final String displayName;

  const ClassColor({
    required this.name,
    required this.color,
    required this.displayName,
  });
}

class ClassIcon {
  final String name;
  final IconData icon;
  final String displayName;

  const ClassIcon({
    required this.name,
    required this.icon,
    required this.displayName,
  });
}

