class Attachment {
  //single file attach to email
  const Attachment({required this.url});

  final String url; // holds the web address (URL)
}

class Email {  //single email
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

class User {      //single user
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
  final String topic;
  final String feedback;

  FeedbackData({
    required this.feedbackId,
    required this.studentName,
    required this.studentId,
    required this.topic,
    required this.feedback,
  });
}
