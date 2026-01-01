import 'package:flutter/material.dart';
import 'package:code_play/models/student.dart';
import 'package:code_play/student/widgets/class/student_preview_teacher_row.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_quiz_list_section.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_all_students_page.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/admin_teacher/widgets/class/admin_edit_class_page.dart';

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

  Future<void> _deleteClass() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text(
          'Are you sure you want to delete "${classData?['class_name'] ?? 'this class'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ClassApi.deleteClass(widget.classId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Class deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate change
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting class: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = Theme.of(context).colorScheme.primary;
    final icon = Icons.school_rounded;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: 'Classes',
              onTap: () => Navigator.of(context).pop(),
            ),
            const BreadcrumbItem(label: 'Details'),
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
            tooltip: 'Refresh',
          ),
          if (widget.roleName.toLowerCase() == 'admin')
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
              tooltip: 'Edit Class',
            ),
          if (widget.roleName.toLowerCase() == 'admin')
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteClass,
              tooltip: 'Delete Class',
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
                      classData?['class_name'] ?? 'No Name',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        classData?['teacher']?['name'] ?? 'No teacher assigned',
                      ),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // General Info Section
              _buildSectionTitle(context, 'General Info'),
              _buildInfoRow(
                context,
                'Name',
                classData?['class_name'] ?? 'N/A',
              ),
              _buildInfoRow(
                context,
                'Teacher',
                classData?['teacher']?['name'] ?? 'No teacher assigned',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Total Students:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_students.length}',
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
                        'Total Quizzes:',
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
              if (widget.roleName.toLowerCase() == 'admin')
                _buildInfoRow(
                  context,
                  'Creator',
                  classData?['admin']?['name'] ?? 'Unknown',
                ),

              const Divider(height: 30),

              // Description Section
              _buildSectionTitle(context, 'Description'),
              Text(
                classData?['description'] ?? 'No description available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Divider(height: 30),

              // Timestamps Section
              _buildSectionTitle(context, 'Timestamps'),
              _buildInfoRow(
                context,
                'Created At',
                _formatDate(
                  DateTime.tryParse(classData?['created_at'] ?? ''),
                ),
              ),
              _buildInfoRow(
                context,
                'Last Updated',
                _formatDate(
                  DateTime.tryParse(classData?['updated_at'] ?? ''),
                ),
              ),

              const Divider(height: 30),

              // Students Section
              if (widget.roleName.toLowerCase() == 'teacher' ||
                  widget.roleName.toLowerCase() == 'admin')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Students'),
                    const SizedBox(height: 8),
                    _BorderedStudentPreviewRow(
                      students: _students,
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
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Teacher'),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TeacherPreviewRow(
                          teacherName:
                              classData?['teacher']?['name'] ?? 'No teacher assigned',
                          teacherDescription: classData?['teacher']?['email'] ?? '',
                        ),
                      ),
                    ),
                  ],
                ),

              const Divider(height: 30),

              // Quizzes Section
              _buildSectionTitle(context, 'Quizzes'),
              const SizedBox(height: 8),
              QuizListSection(
                roleName: widget.roleName,
                classId: widget.classId,
                className: classData?['class_name'] ?? 'No Name',
                classDescription: classData?['description'] ?? 'No description',
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
              value ?? 'N/A',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
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
                "$extra more",
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
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (students.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: cs.outline.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No students have been enrolled in this class yet.',
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
        side: BorderSide(
          color: cs.outline.withOpacity(0.3),
          width: 1.0,
        ),
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
                    Text(
                      'Students',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'List of enrolled students',
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
                  child: const Text("View All"),
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

