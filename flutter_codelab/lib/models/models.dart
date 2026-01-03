class Attachment {
  //single file attach to email
  const Attachment({required this.url});

  final String url; // holds the web address (URL)
}

class Email {
  //single email
  const Email({
    required this.sender,
    required this.recipients,
    required this.subject,
    required this.content,
    this.replies = 0,
    this.attachments = const [],
  });

  final User sender;
  final List<User> recipients;
  final String subject;
  final String content;
  final List<Attachment> attachments;
  final double replies;
}

class Name {
  //store person name
  const Name({required this.first, required this.last});

  final String first; //first name
  final String last; //last name
  String get fullName => '$first $last'; // getter combine first and lastname
}

class User {
  //single user
  const User({
    required this.name,
    required this.avatarUrl,
    required this.lastActive,
  });

  final Name name;
  final String avatarUrl; //web address for the user's profile picture
  final DateTime lastActive;
}

class FeedbackData {
  final String feedbackId;
  final String studentName;
  final String studentId;
  final String teacherName;
  final String teacherId;
  final String topicId; // Added
  final String title;   // Added
  final String topic;   // Assuming this is used for category name or display
  final String feedback;

  final String? createdAt;

  FeedbackData({
    required this.feedbackId,
    required this.studentName,
    required this.studentId,
    required this.teacherName,
    required this.teacherId,
    required this.topicId,
    required this.title,
    required this.topic,
    required this.feedback,
    this.createdAt,
  });
}
