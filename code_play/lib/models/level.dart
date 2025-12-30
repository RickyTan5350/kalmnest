class LevelModel {
  final String? levelId;
  final String? levelName;
  final String? levelTypeId;
  final String? levelTypeName;
  final String? levelData;
  final String? winCondition;
  final bool? isPrivate;
  final bool? isCreatedByMe;
  final String? status;

  LevelModel({
    this.levelId,
    this.levelName,
    this.levelTypeId,
    this.levelTypeName,
    this.levelData,
    this.winCondition,
    this.isPrivate,
    this.isCreatedByMe,
    this.status,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      levelId: json['level_id'] as String?,
      levelName: json['level_name'] as String?,
      levelTypeId: json['level_type'] != null
          ? json['level_type']['level_type_id'] as String?
          : null,
      levelTypeName: json['level_type'] != null
          ? json['level_type']['level_type_name'] as String?
          : null,
      levelData: json['level_data'] as String?,
      winCondition: json['win_condition'] as String?,
      isPrivate: json['is_private'] as bool?,
      isCreatedByMe: json['is_created_by_me'] as bool?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level_id': levelId,
      'level_name': levelName,
      'level_type': {
        'level_type_id': levelTypeId,
        'level_type_name': levelTypeName,
      },
      'level_data': levelData,
      'win_condition': winCondition,
    };
  }
}
