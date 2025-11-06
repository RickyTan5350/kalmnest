import 'package:flutter/material.dart';

class AppTextStyles {
  // Prevent instantiation
  AppTextStyles._();

  /// fontSize: 28, fontWeight: w500, color: #161D1D
  static const TextStyle achievementsHeader = TextStyle(
    color: const Color(0xFF161D1D),
    fontSize: 28,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.29,
  );

  /// fontSize: 14, fontWeight: w500, color: #3F4949
  static const TextStyle filterChipLabel = TextStyle(
    color: const Color(0xFF3F4949),
    fontSize: 14,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.10,
  );

  /// fontSize: 14, fontWeight: w500, color: #324B4B
  static const TextStyle filterChipLabelSelected = TextStyle(
    color: const Color(0xFF324B4B),
    fontSize: 14,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.10,
  );

  /// fontSize: 14, fontWeight: w500, color: #161D1D
  static const TextStyle cardTitle = TextStyle(
    color: const Color(0xFF161D1D),
    fontSize: 14,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.10,
  );

  /// fontSize: 12, fontWeight: w400, color: #3F4949
  static const TextStyle cardSubtitle = TextStyle(
    color: const Color(0xFF3F4949),
    fontSize: 12,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.40,
  );

  /// fontSize: 16, fontWeight: w400, color: #3F4949
  static const TextStyle searchHint = TextStyle(
    color: const Color(0xFF3F4949),
    fontSize: 16,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.50,
  );

  /// fontSize: 16, fontWeight: w400, color: #161D1D
  static const TextStyle urlText = TextStyle(
    color: const Color(0xFF161D1D),
    fontSize: 16,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.50,
  );

  /// fontSize: 16, fontWeight: w400, color: Colors.white
  static const TextStyle avatarLetter = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.50,
  );

  /// fontSize: 12, fontWeight: w500, color: #4A6363
  static const TextStyle navLabelSelected = TextStyle(
    color: const Color(0xFF4A6363),
    fontSize: 12,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.50,
  );

  /// fontSize: 12, fontWeight: w500, color: #3F4949
  static const TextStyle navLabel = TextStyle(
    color: const Color(0xFF3F4949),
    fontSize: 12,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.50,
  );
}
