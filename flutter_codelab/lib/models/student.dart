class Student {
  final String name; // short initials shown in original
  final String fullName;
  Student({required this.name, required this.fullName});
}

class StudentModel {
  final String name;
  final String email;
  final String phone;
  final int avgScore;
  final int quizzesDone;
  final int quizzesTotal;
  final double progress;

  StudentModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.avgScore,
    required this.quizzesDone,
    required this.quizzesTotal,
    required this.progress,
  });
}
