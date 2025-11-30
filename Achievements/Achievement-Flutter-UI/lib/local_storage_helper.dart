import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Need to import dart:math for the mock UUID generator
import 'dart:math';

// --- 1. Achievement Model ---

class Achievement {
  final String achievementId;
  final String achievementName;
  final String title;
  final String? description;
  final String type;
  final String levelId;
  final String createdBy;
  final DateTime createdAt;
  // Note: The original local storage model did not include `updatedAt`.
  // I'll keep the original structure here.

  Achievement({
    required this.achievementId,
    required this.achievementName,
    required this.title,
    this.description,
    required this.type,
    required this.levelId,
    required this.createdBy,
    required this.createdAt,
  });

  // Convert the Dart object into a Map (for JSON serialization)
  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'title': title,
      'description': description,
      'type': type,
      'level_id': levelId,
      'created_by': createdBy,
      'created_at': createdAt
          .toIso8601String(), // Use ISO string format for DateTime
    };
  }

  // Factory constructor to create Achievement from a JSON Map (for loading)
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievement_id'] as String,
      achievementName: json['achievement_name'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      levelId: json['level_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// --- 2. File Storage Helper ---

class FileHelper {
  static const String _fileName = 'achievements.json';
  static const String _folderName = 'app_data';

  // Get the path to the application's documents directory
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Get a reference to the actual file
  Future<File> get _localFile async {
    final rootPath = await _localPath;

    // 1. Construct the full path to the new directory
    final String dirPath = '$rootPath/$_folderName';

    // 2. Create the Directory object
    final Directory directory = Directory(dirPath);

    // 3. IMPORTANT: Check if the folder exists and create it if it doesn't
    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      ); // `recursive: true` ensures parent folders are also created
      if (kDebugMode) {
        print('Created new directory: $dirPath');
      }
    }

    // 4. Return the File reference within the new sub-directory
    return File('$dirPath/$_fileName');
  }

  // Reads the entire content of the JSON file as a string
  Future<String> readJson() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return '[]'; // Return empty JSON array if file is new/missing
      }
      return await file.readAsString();
    } catch (e) {
      // Handle potential file errors
      if (kDebugMode) {
        print('Error reading JSON file: $e');
      }
      return '[]';
    }
  }

  // Writes a list of Achievement objects to the JSON file
  Future<void> writeAchievements(List<Achievement> achievements) async {
    final file = await _localFile;
    // 1. Convert List<Achievement> to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> data = achievements
        .map((a) => a.toJson())
        .toList();

    // 2. Convert List<Map> to a pretty-printed JSON string
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String jsonString = encoder.convert(data);

    // 3. Write the JSON string to the file
    await file.writeAsString(jsonString);
    if (kDebugMode) {
      print(
        'Successfully wrote ${achievements.length} achievements to $_fileName',
      );
      print('File path: ${file.path}');
    }
  }
}

// --- 3. Placeholder Uuid class (Moved here for dependency management) ---

@protected
class Uuid {
  const Uuid();
  // Simple mock V4 generation for demo purposes
  String v4() =>
      '${DateTime.now().millisecondsSinceEpoch}-${_generateRandomHex(8)}-${_generateRandomHex(4)}';

  String _generateRandomHex(int length) {
    final random = Random();
    String hex = '';
    for (int i = 0; i < length; i++) {
      hex += random.nextInt(16).toRadixString(16);
    }
    return hex;
  }
}
