import 'package:flutter/material.dart';
import 'package:code_play/student/widgets/class/student_preview_teacher_row.dart';
import 'package:code_play/student/widgets/class/student_quiz_list_section.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/widgets/user/user_detail_page.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

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

  String _formatDate(DateTime? date) {
    final l10n = AppLocalizations.of(context)!;
    if (date == null) return l10n.nA;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final color = Theme.of(context).colorScheme.primary;
    final icon = Icons.school_rounded;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: l10n.classes,
              onTap: () => Navigator.of(context).pop(),
            ),
            BreadcrumbItem(label: l10n.details),
          ],
        ),
        backgroundColor: color.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => loading = true);
              _fetchClassData();
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchClassData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Centered with icon, title, and chip
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      classData?['class_name'] ?? l10n.noName,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        classData?['teacher']?['name'] ??
                            l10n.noTeacherAssigned,
                      ),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // General Info Section
              _buildSectionTitle(context, l10n.generalInfo),
              _buildInfoRow(
                context,
                l10n.name,
                classData?['class_name'] ?? l10n.nA,
              ),
              _buildInfoRow(
                context,
                l10n.teacher,
                classData?['teacher']?['name'] ?? l10n.noTeacherAssigned,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        l10n.totalStudents,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        classData?['students'] != null
                            ? '${(classData!['students'] as List).length}'
                            : '0',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        l10n.totalQuizzes,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$_quizCount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 30),

              // Description Section
              _buildSectionTitle(context, l10n.description),
              Text(
                classData?['description'] ?? l10n.noDescriptionAvailable,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Divider(height: 30),

              // Timestamps Section
              _buildSectionTitle(context, l10n.timestamps),
              _buildInfoRow(
                context,
                l10n.createdAt,
                _formatDate(DateTime.tryParse(classData?['created_at'] ?? '')),
              ),
              _buildInfoRow(
                context,
                l10n.lastUpdated,
                _formatDate(DateTime.tryParse(classData?['updated_at'] ?? '')),
              ),

              const Divider(height: 30),

              // Teacher Section
              TeacherPreviewRow(
                teacherName:
                    classData?['teacher']?['name'] ?? l10n.noTeacherAssigned,
                teacherDescription: classData?['teacher']?['email'] ?? '',
                onTap: () {
                  final teacher = classData?['teacher'];
                  final l10n = AppLocalizations.of(context)!;
                  if (teacher == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.noTeacherAssignedToClass),
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
                      SnackBar(
                        content: Text(l10n.cannotOpenTeacherProfile),
                      ),
                    );
                    return;
                  }

                  final teacherId = rawId.toString();
                  final teacherName = (teacher['name'] ?? l10n.teacher)
                      .toString();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserDetailPage(
                        userId: teacherId,
                        userName: teacherName,
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 30),

              // Quizzes Section
              _buildSectionTitle(context, l10n.quizzes),
              const SizedBox(height: 8),
              QuizListSection(
                roleName: widget.roleName,
                classId: widget.classId,
                className: classData?['class_name'] ?? l10n.noName,
                classDescription:
                    classData?['description'] ?? l10n.noDescriptionAvailable,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? l10n.nA,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
