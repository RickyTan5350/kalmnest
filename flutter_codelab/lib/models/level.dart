import 'dart:convert';

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
  final int? timer; // Add timer field

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
    this.timer,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      levelId: json['level_id']?.toString(), // Ensure string
      levelName: json['level_name'] as String?,
      levelTypeId: json['level_type'] != null
          ? json['level_type']['level_type_id']?.toString()
          : null,
      levelTypeName: json['level_type'] != null
          ? json['level_type']['level_type_name'] as String?
          : null,
      levelData: json['level_data'] is String
          ? json['level_data'] as String?
          : json['level_data'] != null
          ? jsonEncode(json['level_data'])
          : null,
      winCondition: json['win_condition'] is String
          ? json['win_condition'] as String?
          : json['win_condition'] != null
          ? jsonEncode(json['win_condition'])
          : null,
      isPrivate: json['is_private'] is int
          ? (json['is_private'] == 1)
          : json['is_private'] as bool?,
      isCreatedByMe: json['is_created_by_me'] as bool?,
      status: json['status'] as String?,
      timer: json['timer'] is int
          ? json['timer'] as int?
          : int.tryParse(json['timer']?.toString() ?? ''),
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
