class AchievementData {
  final String? achievementId;
  final String? achievementName;
  final String? achievementTitle;
  final String? achievementDescription;
  final String? icon;
  final String? creatorId;
  final String? creatorName;
  final String? levelId;
  final String? levelName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? unlockedCount;
  final int? totalStudents;
  final DateTime? unlockedAt; // NEW
  final int? timer;

  AchievementData({
    this.achievementId,
    this.achievementName,
    this.achievementTitle,
    this.achievementDescription,
    this.icon,
    this.levelId,
    this.levelName,
    this.creatorId,
    this.creatorName,
    this.createdAt,
    this.updatedAt,
    this.unlockedCount,
    this.totalStudents,
    this.unlockedAt,
    this.timer,
  });

  factory AchievementData.fromJson(Map<String, dynamic> json) {
    return AchievementData(
      achievementId: json['achievement_id'] as String?,
      achievementName: json['achievement_name'] as String?,
      achievementDescription: json['description'] as String?,
      achievementTitle: json['title'] as String?,
      levelId:
          json['associated_level'] as String? ?? json['level_id'] as String?,
      levelName: json['level_name'] as String?,
      icon: json['icon'] as String?,
      creatorId: json['created_by'] as String?,
      creatorName: json['creator_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
      unlockedCount: json['unlocked_count'] as int?,
      totalStudents: json['total_students'] as int?,
      unlockedAt: json['unlocked_at'] == null
          ? null
          : DateTime.tryParse(json['unlocked_at'] as String),
      timer: json['timer'] as int?,
    );
  }

  bool get isUnlocked => unlockedAt != null;

  // Used for API uploads (creation)
  Map<String, dynamic> newAchievementToJson() {
    return {
      'achievement_name': achievementName,
      'title': achievementTitle,
      'description': achievementDescription,
      'associated_level': levelId,
      'icon': icon,
    };
  }

  // NEW: Used for Local Caching (includes ID & timestamps)
  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'title': achievementTitle,
      'description': achievementDescription,
      'associated_level': levelId,
      'level_name': levelName,
      'icon': icon,
      'created_by': creatorId,
      'creator_name': creatorName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }
}
