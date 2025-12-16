import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/quiz.dart';
import 'package:flutter_codelab/student/widgets/class/student_class_statistics_section.dart';
import 'package:flutter_codelab/student/widgets/class/student_preview_teacher_row.dart';
import 'package:flutter_codelab/student/widgets/class/student_quiz_list_section.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/admin_teacher/widgets/user/user_detail_page.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String roleName;

  const ClassDetailPage({
    Key? key,
    required this.classId,
    required this.roleName,
  }) : super(key: key);

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  bool loading = true;
  Map<String, dynamic>? classData;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  Future<void> _fetchClassData() async {
    if (!mounted) return;
    setState(() => loading = true);
    final data = await ClassApi.fetchClassById(widget.classId);
    if (mounted) {
      setState(() {
        classData = data;
        loading = false;
      });
    }
  }

  // Sample data for demo
  List<Quiz> get _quizzes => [
    Quiz(
      title: 'Derivatives and Integrals',
      questions: 15,
      assignedDate: DateTime(2025, 11, 20),
      status: QuizStatus.published,
    ),
    Quiz(
      title: 'Probability Theory Basics',
      questions: 20,
      assignedDate: DateTime(2025, 11, 18),
      status: QuizStatus.published,
    ),
    Quiz(
      title: 'Linear Algebra Review',
      questions: 12,
      assignedDate: DateTime(2025, 11, 25),
      status: QuizStatus.draft,
    ),
  ];

  String formatDate(DateTime? date, {DateTime? fallback}) {
    final d = date ?? fallback ?? DateTime.now();
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _ClassHeader(
                              title: classData?['class_name'] ?? 'No Name',
                              subtitle:
                                  classData?['description'] ?? 'No description',
                              lastUpdatedAt:
                                  DateTime.tryParse(
                                    classData?['updated_at'] ?? '',
                                  ) ??
                                  DateTime.now(),
                              createdAt:
                                  DateTime.tryParse(
                                    classData?['created_at'] ?? '',
                                  ) ??
                                  DateTime.now(),
                              createdBy:
                                  classData?['admin']?['name'] ?? 'Unknown',
                              updatedBy:
                                  classData?['admin']?['name'] ?? 'Unknown',
                              formatDate: formatDate,
                            ),

                            const SizedBox(height: 20),
                            // Statistics
                            ClassStatisticsSection(
                              totalStudents: classData?['students'] != null
                                  ? (classData!['students'] as List).length
                                  : 0,
                              totalQuizzes: 0,
                            ),
                            const SizedBox(height: 20),

                            // For students, show teacher preview and allow tap to open teacher profile
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                final teacher = classData?['teacher'];
                                if (teacher == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No teacher assigned to this class.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Try common key names for the teacher's user id
                                final dynamic rawId =
                                    teacher['id'] ??
                                    teacher['user_id'] ??
                                    teacher['teacher_id'];
                                if (rawId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cannot open teacher profile: missing teacher id.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final teacherId = rawId.toString();
                                final teacherName =
                                    (teacher['name'] ?? 'Teacher').toString();

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailPage(
                                      userId: teacherId,
                                      userName: teacherName,
                                    ),
                                  ),
                                );
                              },
                              child: TeacherPreviewRow(
                                teacherName:
                                    classData?['teacher']?['name'] ??
                                    'No teacher assigned',
                                teacherDescription:
                                    classData?['teacher']?['email'] ?? '',
                              ),
                            ),

                            const SizedBox(height: 20),
                            QuizListSection(
                              quizzes: _quizzes,
                              roleName: widget.roleName, // pass role here
                              classId: widget.classId,
                              className: classData?['class_name'] ?? 'No Name',
                              classDescription:
                                  classData?['description'] ?? 'No description',
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// Header widget
class _ClassHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime lastUpdatedAt;
  final DateTime createdAt;
  final String createdBy;
  final String updatedBy;
  final String Function(DateTime? date, {DateTime? fallback}) formatDate;

  const _ClassHeader({
    required this.title,
    required this.subtitle,
    required this.lastUpdatedAt,
    required this.createdAt,
    required this.createdBy,
    required this.updatedBy,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Created by ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      createdBy,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'at ${formatDate(createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Updated by ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      updatedBy,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'at ${formatDate(lastUpdatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
