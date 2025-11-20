class ClassItem {
  final String classId;
  final String className;
  final String description;
  final int teacherId;

  ClassItem({
    required this.classId,
    required this.className,
    required this.description,
    required this.teacherId,
  });

  factory ClassItem.fromJson(Map<String, dynamic> json) {
    return ClassItem(
      classId: json['class_id'],
      className: json['class_name'],
      description: json['description'] ?? '',
      teacherId: json['teacher_id'],
    );
  }
}
