
/// Represents the brief data from the showAchievementsBrief() API endpoint.
class NoteBrief {
  final String noteId;
  final String title;
  final String topic;
  final DateTime updatedAt;
  final bool visibility;

  NoteBrief({
    required this.noteId,
    required this.title,
    required this.topic,
    required this.updatedAt,
    required this.visibility,
  });

  /// Factory constructor to parse JSON from the API
  factory NoteBrief.fromJson(Map<String, dynamic> json) {
    // Handle visibility: default to true if null, or parse int/bool
    bool parseVisibility(dynamic v) {
      if (v == null) return true;
      if (v is bool) return v;
      if (v is int) return v == 1;
      return true;
    }

    return NoteBrief(
      noteId: json['note_id'] as String,
      title: json['title'] as String,
      topic: json['topic_name'] ?? 'General',
      updatedAt: DateTime.parse(json['updated_at'] as String),
      visibility: parseVisibility(json['visibility']),
    );
  }

  void toJson() {}
}
