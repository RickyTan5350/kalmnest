import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:intl/intl.dart';

/// Teacher view: Quiz detail page showing quiz info and student completion status
class TeacherQuizDetailPage extends StatefulWidget {
  final String classId;
  final String levelId;
  final String? quizName;

  const TeacherQuizDetailPage({
    super.key,
    required this.classId,
    required this.levelId,
    this.quizName,
  });

  @override
  State<TeacherQuizDetailPage> createState() => _TeacherQuizDetailPageState();
}

class _TeacherQuizDetailPageState extends State<TeacherQuizDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _quiz;
  List<Map<String, dynamic>> _students = [];
  int _totalStudents = 0;
  int _completedStudents = 0;
  String _filter = 'all'; // 'all', 'completed', 'pending'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await ClassApi.getQuizStudents(
        widget.classId,
        widget.levelId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _quiz = result['quiz'];
          _students = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _totalStudents = result['total_students'] ?? 0;
          _completedStudents = result['completed_students'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load quiz student data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching quiz students: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    switch (_filter) {
      case 'completed':
        return _students.where((s) => s['is_completed'] == true).toList();
      case 'pending':
        return _students.where((s) => s['is_completed'] != true).toList();
      default:
        return _students;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final quizName = _quiz?['level_name'] ?? widget.quizName ?? 'Quiz';
    final levelType = _quiz?['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? 'Unknown'
        : 'Unknown';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back, color: cs.primary),
                            label: Text(
                              'Back',
                              style: textTheme.bodyMedium?.copyWith(
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quiz Info Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.quiz,
                                  color: cs.onPrimaryContainer,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quizName,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer
                                                .withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            levelTypeName,
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (_quiz?['created_at'] != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Created: ${_formatDate(_quiz!['created_at'])}',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Statistics Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: cs.outlineVariant, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  cs,
                                  textTheme,
                                  'Total Students',
                                  '$_totalStudents',
                                  Icons.people,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  cs,
                                  textTheme,
                                  'Completed',
                                  '$_completedStudents',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  cs,
                                  textTheme,
                                  'Pending',
                                  '${_totalStudents - _completedStudents}',
                                  Icons.pending,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  cs,
                                  textTheme,
                                  'Completion Rate',
                                  _totalStudents > 0
                                      ? '${((_completedStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                                      : '0%',
                                  Icons.trending_up,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Filter Chips
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _filter == 'all',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _filter = 'all');
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Completed'),
                            selected: _filter == 'completed',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _filter = 'completed');
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Pending'),
                            selected: _filter == 'pending',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _filter = 'pending');
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Students List
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: cs.outlineVariant, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Students',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _filteredStudents.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 64,
                                              color: cs.onSurfaceVariant
                                                  .withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No students found',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: _filteredStudents
                                          .map((student) => _buildStudentItem(
                                                cs,
                                                textTheme,
                                                student,
                                              ))
                                          .toList(),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(
    ColorScheme cs,
    TextTheme textTheme,
    String label,
    String value,
    IconData icon, [
    Color? iconColor,
  ]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? cs.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(
    ColorScheme cs,
    TextTheme textTheme,
    Map<String, dynamic> student,
  ) {
    final isCompleted = student['is_completed'] == true;
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : cs.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isCompleted
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            child: Text(
              _getInitials(name),
              style: TextStyle(
                color: isCompleted ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.pending,
                            size: 16,
                            color: isCompleted ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted ? 'Completed' : 'Pending',
                            style: textTheme.labelSmall?.copyWith(
                              color: isCompleted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (isCompleted && student['completion_date'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Completed: ${_formatDate(student['completion_date'])}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

