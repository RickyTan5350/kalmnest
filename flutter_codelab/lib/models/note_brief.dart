import 'package:flutter/material.dart';

/// Represents the brief data from the showAchievementsBrief() API endpoint.
class NoteBrief {
  final String noteId;
  final String title;

 

  NoteBrief({
    required this.noteId,
    required this.title,
   
  });

  /// Factory constructor to parse JSON from the API
  factory NoteBrief.fromJson(Map<String, dynamic> json) {
    return NoteBrief(
      noteId: json['note_id'] as String,
      title: json['title'] as String,
     // Assumes API returns a string like "php"
    );
  }

  toJson() {}
}
