import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/admin_teacher/widgets/class/class_customization.dart';
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
  List<Map<String, dynamic>> _filteredStudents = [];
  int _totalStudents = 0;
  int _completedStudents = 0;
  String _filter = 'all'; // 'all', 'completed', 'pending'
  Map<String, dynamic>? _classData;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_students);
      } else {
        final q = query.toLowerCase();
        _filteredStudents = _students.where((student) {
          final name = (student['name'] ?? '').toString().toLowerCase();
          final email = (student['email'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Fetch class data and quiz students in parallel
      final classDataFuture = ClassApi.fetchClassById(widget.classId);
      final quizDataFuture = ClassApi.getQuizStudents(
        widget.classId,
        widget.levelId,
      );

      final classData = await classDataFuture;
      final result = await quizDataFuture;

      if (!mounted) return;

      if (result['success'] == true) {
        final students = List<Map<String, dynamic>>.from(result['data'] ?? []);
        setState(() {
          _classData = classData;
          _quiz = result['quiz'];
          _students = students;
          _filteredStudents = List.from(students);
          _totalStudents = result['total_students'] ?? 0;
          _completedStudents = result['completed_students'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() {
          _classData = classData;
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load quiz student data'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching quiz students: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _displayedStudents {
    List<Map<String, dynamic>> students = _filteredStudents;
    switch (_filter) {
      case 'completed':
        return students.where((s) => s['is_completed'] == true).toList();
      case 'pending':
        return students.where((s) => s['is_completed'] != true).toList();
      default:
        return students;
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
    if (_loading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get class color for AppBar
    final classColor = ClassCustomization.getColorByName(_classData?['color']);
    final color = classColor?.color ?? cs.primary;

    final quizName = _quiz?['level_name'] ?? widget.quizName ?? 'Quiz';
    final levelType = _quiz?['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? 'Unknown'
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: 'Classes',
              onTap: () {
                // Navigate back to class list
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            BreadcrumbItem(
              label: 'Details',
              onTap: () {
                // Navigate back to class detail
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(
              label: 'All Quizzes',
              onTap: () => Navigator.of(context).pop(),
            ),
            BreadcrumbItem(
              label: widget.quizName ?? _quiz?['level_name'] ?? 'Quiz',
            ),
          ],
        ),
        backgroundColor: color.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _fetchData();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Info Section - Left aligned, no centered header
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: cs.outline.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.quiz,
                              color: cs.onPrimaryContainer,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quizName,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(levelTypeName),
                                  backgroundColor: cs.primaryContainer
                                      .withOpacity(0.3),
                                ),
                                if (_quiz?['created_at'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Created: ${_formatDate(_quiz!['created_at'])}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Section - General Info style
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Statistics',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              _buildInfoRow(
                cs,
                textTheme,
                Icons.people,
                'Total Students',
                '$_totalStudents',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.check_circle,
                  'Completed',
                  '$_completedStudents',
                  valueColor: Colors.green,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.pending,
                  'Pending',
                  '${_totalStudents - _completedStudents}',
                  valueColor: Colors.orange,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.trending_up,
                  'Completion Rate',
                  _totalStudents > 0
                      ? '${((_completedStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  valueColor: Colors.blue,
                ),
              ),
              const Divider(height: 30),

              const SizedBox(height: 32),

              // Filter Chips
              Wrap(
                spacing: 8,
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
                  FilterChip(
                    label: const Text('Completed'),
                    selected: _filter == 'completed',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'completed');
                      }
                    },
                  ),
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

              const SizedBox(height: 24),

              // Search Section
              SizedBox(
                width: 300,
                child: SearchBar(
                  controller: _searchController,
                  hintText: "Search students...",
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  onChanged: (value) {
                    _onSearchChanged();
                  },
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _filteredStudents = List.from(_students);
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Students List
              if (_displayedStudents.isEmpty)
                _buildEmptyState(cs, textTheme)
              else
                ..._displayedStudents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildStudentCard(cs, textTheme, student, index),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ColorScheme cs,
    TextTheme textTheme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: valueColor ?? cs.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    ColorScheme cs,
    TextTheme textTheme,
    Map<String, dynamic> student,
    int index,
  ) {
    final isCompleted = student['is_completed'] == true;
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final phone = student['phone_no'] ?? '';
    final initials = _getInitials(name);

    // Get avatar color based on index
    final avatarColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final avatarColor = avatarColors[index % avatarColors.length];

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          // Could navigate to student detail if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor.withOpacity(0.18),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: avatarColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                    isCompleted
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    size: 16,
                                    color: isCompleted
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isCompleted ? 'Completed' : 'Pending',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.orange,
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
                            ),
                          ),
                        ],
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (isCompleted &&
                            student['completion_date'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Completed: ${_formatDate(student['completion_date'])}',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

