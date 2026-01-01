class FeedbackData {
  final String feedbackId;
  final String studentName;
  final String studentId;
  final String teacherName;
  final String teacherId;
  final String topic;
  final String feedback;
  final String? createdAt;

  FeedbackData({
    required this.feedbackId,
    required this.studentName,
    required this.studentId,
    required this.teacherName,
    required this.teacherId,
    required this.topic,
    required this.feedback,
    this.createdAt,
  });
}
