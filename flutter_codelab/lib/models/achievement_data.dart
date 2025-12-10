class AchievementData {
  final String? achievementId;
  final String? achievementName;
  final String? achievementTitle;
  final String? achievementDescription;
  final String? level;
  final String? icon;
  final String? creatorId;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AchievementData({
    this.achievementId,
    this.achievementName,
    this.achievementTitle,
    this.achievementDescription,
    this.icon,
    this.level,
    this.creatorId,
    this.creatorName,
    this.createdAt,
    this.updatedAt
  });

  factory AchievementData.fromJson(Map<String, dynamic> json) {
    return AchievementData(
      achievementId: json['achievement_id'] as String?, 
      achievementName: json['achievement_name'] as String?, 
      achievementDescription: json['description'] as String?, 
      achievementTitle: json['title'] as String?, 
      level: json['associated_level'] as String?,
      icon: json['icon'] as String?, 
      creatorId: json['created_by'] as String?,
      creatorName: json['creator_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> newAchievementToJson() {
    return {
      'achievement_name': achievementName,
      'title': achievementTitle,
      'description': achievementDescription,
      'associated_level': level,
      'icon': icon,
    };
  }


}