import 'package:flutter/material.dart';
import 'package:flutter_codelab/models/student.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_class_statistics_section.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_preview_student_row.dart';
import 'package:flutter_codelab/student/widgets/class/student_preview_teacher_row.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_quiz_list_section.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/teacher_all_students_page.dart';
import 'package:flutter_codelab/api/class_api.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;
  final String roleName;

  const ClassDetailPage({
    super.key,
    required this.classId,
    required this.roleName,
  });

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  bool loading = true;
  Map<String, dynamic>? classData;
  int _quizCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  Future<void> _fetchClassData() async {
    if (!mounted) return;
    setState(() => loading = true);
    final data = await ClassApi.fetchClassById(widget.classId);
    final quizCount = await ClassApi.getClassQuizCount(widget.classId);
    if (mounted) {
      setState(() {
        classData = data;
        _quizCount = quizCount;
        loading = false;
      });
    }
  }

  // Get students from backend data
  List<Student> get _students {
    if (classData == null || classData!['students'] == null) {
      return [];
    }
    final studentsList = classData!['students'] as List;
    return studentsList.map((s) {
      final name = s['name'] ?? 'Unknown';
      final nameParts = name.split(' ');
      final initials = nameParts.length > 1
          ? '${nameParts[0][0]}${nameParts[1][0]}'
          : name[0];
      return Student(name: initials.toUpperCase(), fullName: name);
    }).toList();
  }

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
                              totalStudents: _students.length,
                              totalQuizzes: _quizCount,
                            ),
                            const SizedBox(height: 20),

                            // Conditional content based on role
                            if (widget.roleName.toLowerCase() == 'teacher' ||
                                widget.roleName.toLowerCase() == 'admin')
                              StudentPreviewRow(
                                students: _students,
                                onViewAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TeacherAllStudentsPage(
                                            classId: widget.classId,
                                            className:
                                                classData?['class_name'] ??
                                                'Class',
                                          ),
                                    ),
                                  );
                                },
                              )
                            else
                              TeacherPreviewRow(
                                teacherName:
                                    classData?['teacher']?['name'] ??
                                    'No teacher assigned',
                                teacherDescription:
                                    classData?['teacher']?['email'] ?? '',
                              ),

                            const SizedBox(height: 20),
                            QuizListSection(
                              roleName: widget.roleName,
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      createdBy,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'at ${formatDate(createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Updated by ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      updatedBy,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'at ${formatDate(lastUpdatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
