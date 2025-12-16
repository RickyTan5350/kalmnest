import 'package:flutter/material.dart';

/// Represents the brief data from the showAchievementsBrief() API endpoint.
class NoteBrief {
  final String noteId;
  final String title;
  final String topic;
  final DateTime updatedAt;

  NoteBrief({
    required this.noteId,
    required this.title,
    required this.topic,
    required this.updatedAt,
  });

  /// Factory constructor to parse JSON from the API
  factory NoteBrief.fromJson(Map<String, dynamic> json) {
    return NoteBrief(
      noteId: json['note_id'] as String,
      title: json['title'] as String,
      topic: json['topic_name'] ?? 'General',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  toJson() {}
}
