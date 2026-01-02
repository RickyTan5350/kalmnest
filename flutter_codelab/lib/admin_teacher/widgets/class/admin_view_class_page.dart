import 'package:flutter/material.dart';
import 'package:code_play/models/student.dart';
import 'package:code_play/student/widgets/class/student_preview_teacher_row.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_quiz_list_section.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_all_students_page.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/admin_teacher/widgets/class/admin_edit_class_page.dart';
import 'package:code_play/admin_teacher/widgets/user/user_detail_page.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class AdminViewClassPage extends StatefulWidget {
  final String classId;

  const AdminViewClassPage({Key? key, required this.classId}) : super(key: key);

  @override
  State<AdminViewClassPage> createState() => _AdminViewClassPageState();
}

class _AdminViewClassPageState extends State<AdminViewClassPage> {
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

  Future<void> _deleteClass() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.delete} ${l10n.classes}?'),
        content: Text(
          l10n.deleteClassConfirmation(
            classData?['class_name'] ?? l10n.thisClass,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.error,
              ),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ClassApi.deleteClass(widget.classId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.classDeletedSuccessfully),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate change
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorDeletingClass(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  // Get students from backend data
  List<Student> _getStudents(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (classData == null || classData!['students'] == null) {
      return [];
    }
    final studentsList = classData!['students'] as List;
    return studentsList.map((s) {
      final name = s['name'] ?? l10n.unknown;
      final nameParts = name.split(' ');
      final initials = nameParts.length > 1
          ? '${nameParts[0][0]}${nameParts[1][0]}'
          : name[0];
      return Student(name: initials.toUpperCase(), fullName: name);
    }).toList();
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditClassPage(classData: classData!),
                ),
              );
              if (result == true && mounted) {
                _fetchClassData();
              }
            },
            tooltip: l10n.editClass,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteClass,
            tooltip: l10n.deleteClass,
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
              // Header - Centered with icon, title, and teacher chip
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
                    if (classData?['teacher'] != null)
                      Chip(
                        label: Text(
                          classData?['teacher']?['name'] ??
                              l10n.noTeacherAssigned,
                        ),
                        backgroundColor: color.withOpacity(0.1),
                      )
                    else
                      Chip(
                        label: Text(l10n.noTeacherAssigned),
                        backgroundColor: Colors.grey.withOpacity(0.1),
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
                l10n.creator,
                classData?['admin']?['name'] ?? l10n.unknown,
              ),
              _buildInfoRow(
                context,
                l10n.focus,
                classData?['focus'] ?? l10n.notSet,
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
                        '${_getStudents(context).length}',
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

              // Teacher Section (for admin to view assigned teacher)
              _buildSectionTitle(context, l10n.assignedTeacher),
              const SizedBox(height: 8),
              if (classData?['teacher'] != null)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      final teacher = classData?['teacher'];
                      if (teacher == null) return;

                      // Try common key names for the teacher's user id
                      final dynamic rawId =
                          teacher['id'] ??
                          teacher['user_id'] ??
                          teacher['teacher_id'];
                      if (rawId == null) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.cannotOpenTeacherProfile),
                          ),
                        );
                        return;
                      }

                      final teacherId = rawId.toString();
                      final teacherName = (teacher['name'] ?? 'Teacher')
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
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TeacherPreviewRow(
                        teacherName:
                            classData?['teacher']?['name'] ??
                            l10n.noTeacherAssigned,
                        teacherDescription:
                            classData?['teacher']?['email'] ?? '',
                      ),
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.noTeacherAssignedToClass,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ],
                    ),
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

              // Students Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, l10n.students),
                  const SizedBox(height: 8),
                  _BorderedStudentPreviewRow(
                    students: _getStudents(context),
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherAllStudentsPage(
                            classId: widget.classId,
                            className: classData?['class_name'] ?? 'Class',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const Divider(height: 30),

              // Quizzes Section
              _buildSectionTitle(context, l10n.quizzes),
              const SizedBox(height: 8),
              QuizListSection(
                roleName: 'admin',
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

// Wrapper widget to add border to StudentPreviewRow
class _BorderedStudentPreviewRow extends StatelessWidget {
  final List<Student> students;
  final VoidCallback onViewAll;

  const _BorderedStudentPreviewRow({
    required this.students,
    required this.onViewAll,
  });

  Widget _studentCard(BuildContext context, Student student) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              student.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.fullName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _othersCard(BuildContext context, int extra) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onViewAll,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.group,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.moreStudents(extra),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (students.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.noStudentsEnrolled,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shown = students.take(6).toList();
    final extra = students.length - shown.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.students, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      l10n.listOfEnrolledStudents,
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: onViewAll,
                  child: Text(l10n.viewAll),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Horizontal scroll of student cards + others card
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...shown.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: _studentCard(context, s),
                    ),
                  ),

                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: _othersCard(context, extra),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
