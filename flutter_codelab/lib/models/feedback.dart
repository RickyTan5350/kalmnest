class FeedbackData {
  final String feedbackId;
  final String studentName;
  final String studentId;
  final String teacherName;
  final String teacherId;
  final String topicId;
  final String topicName;
  final String title;
  final String feedback;
  final String? createdAt;

  FeedbackData({
    required this.feedbackId,
    required this.studentName,
    required this.studentId,
    required this.teacherName,
    required this.teacherId,
    required this.topicId,
    required this.topicName,
    required this.title,
    required this.feedback,
    this.createdAt,
  });
}
