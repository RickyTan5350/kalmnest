enum QuizStatus { draft, published }

class Quiz {
  final String title;
  final int questions;
  final DateTime assignedDate;
  final QuizStatus status;

  Quiz({
    required this.title,
    required this.questions,
    required this.assignedDate,
    required this.status,
  });
}
