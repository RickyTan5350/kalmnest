import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/widgets/class/teacher_student_detail_page.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/admin_teacher/widgets/class/class_customization.dart';

/// Teacher view: All students in a class with search and scrollable list.
class TeacherAllStudentsPage extends StatefulWidget {
  final String classId;
  final String className;

  const TeacherAllStudentsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TeacherAllStudentsPage> createState() => _TeacherAllStudentsPageState();
}

class _TeacherAllStudentsPageState extends State<TeacherAllStudentsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _classData;

  // Statistics
  int _totalStudents = 0;
  double _averageCompletionPercentage = 0.0;
  int _totalQuizzesAssigned = 0;

  // Student completion data
  Map<String, Map<String, dynamic>> _studentCompletionMap = {};

  @override
  void initState() {
    super.initState();
    _fetchClassData();
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
          return name.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _fetchClassData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final classDataFuture = ClassApi.fetchClassById(widget.classId);
      final completionDataFuture = ClassApi.getStudentCompletion(
        widget.classId,
      );
      final quizCountFuture = ClassApi.getClassQuizCount(widget.classId);

      final classData = await classDataFuture;
      final completionResult = await completionDataFuture;
      int quizCount = 0;
      try {
        quizCount = await quizCountFuture;
      } catch (e) {
        debugPrint('Error fetching quiz count: $e');
      }

      if (!mounted || classData == null) return;

      setState(() {
        _classData = classData;
        _students = List<Map<String, dynamic>>.from(
          classData['students'] ?? [],
        );
        _totalStudents = _students.length;

        if (quizCount > 0) {
          _totalQuizzesAssigned = quizCount;
        } else if (completionResult['success'] == true) {
          _totalQuizzesAssigned =
              completionResult['total_quizzes_assigned'] ?? 0;
        } else {
          _totalQuizzesAssigned = 0;
        }

        if (completionResult['success'] == true) {
          final completionList = List<Map<String, dynamic>>.from(
            completionResult['data'] ?? [],
          );

          _studentCompletionMap = {};
          for (var completion in completionList) {
            final userId = completion['user_id']?.toString();
            if (userId != null) {
              _studentCompletionMap[userId] = completion;
            }
          }
        } else {
          _studentCompletionMap = {};
        }

        _calculateStatistics();

        final query = _searchController.text.trim().toLowerCase();
        if (query.isEmpty) {
          _filteredStudents = List.from(_students);
        } else {
          _filteredStudents = _students.where((student) {
            final name = (student['name'] ?? '').toString().toLowerCase();
            return name.contains(query);
          }).toList();
        }

        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching class data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _totalQuizzesAssigned = 0;
        });
      }
    }
  }

  void _calculateStatistics() {
    if (_students.isEmpty) {
      _averageCompletionPercentage = 0.0;
      return;
    }

    double totalCompletion = 0.0;
    int studentsWithData = 0;

    for (var student in _students) {
      final userId =
          student['id']?.toString() ??
          student['user_id']?.toString() ??
          student['student_id']?.toString();

      if (userId != null && _studentCompletionMap.containsKey(userId)) {
        final completionData = _studentCompletionMap[userId];
        if (completionData != null) {
          final completionPercentage =
              completionData['completion_percentage'] ?? 0.0;
          totalCompletion += completionPercentage;
          studentsWithData++;
        }
      }
    }

    _averageCompletionPercentage = studentsWithData > 0
        ? totalCompletion / studentsWithData
        : 0.0;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFF4CAF50),
      Color(0xFF9C27B0),
      Color(0xFF795548),
      Color(0xFF009688),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Get class color for AppBar
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: 'Classes',
              onTap: () {
                // Navigate back twice to go to class list
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(
              label: 'Details',
              onTap: () => Navigator.of(context).pop(),
            ),
            const BreadcrumbItem(label: 'All Students'),
          ],
        ),
        backgroundColor: color.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _fetchClassData();
            },
            tooltip: 'Refresh',
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
              // Header - Centered with icon, title, and class name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        Icons.school_rounded,
                        color: color,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Students',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(widget.className),
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Statistics Section
              _buildStatisticsSection(),
              const SizedBox(height: 32),

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
              if (_filteredStudents.isEmpty)
                _buildEmptyState()
              else
                ..._filteredStudents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildStudentCard(student, index),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Students',
            '$_totalStudents',
            Icons.people,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completion Rate',
            '${_averageCompletionPercentage.toStringAsFixed(1)}%',
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Quizzes Assigned',
            '$_totalQuizzesAssigned',
            Icons.quiz,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: cs.outline.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  icon,
                  color: cs.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    Map<String, dynamic> student,
    int index,
  ) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = student['name'] ?? 'Unknown';
    final email = student['email'] ?? '';
    final phone = student['phone_no'] ?? '+1 234 567 8901';
    final initials = _getInitials(name);

    final userId =
        student['id']?.toString() ??
        student['user_id']?.toString() ??
        student['student_id']?.toString();
    final completionData = userId != null
        ? _studentCompletionMap[userId]
        : null;
    final completedQuizzes = completionData?['completed_quizzes'] ?? 0;
    final totalQuizzes =
        completionData?['total_quizzes'] ?? _totalQuizzesAssigned;
    final completionPercentage =
        completionData?['completion_percentage'] ?? 0.0;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: cs.outline.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          final dynamic rawId =
              student['id'] ?? student['user_id'] ?? student['student_id'];
          if (rawId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open student profile: missing student id.'),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TeacherStudentDetailPage(
                classId: widget.classId,
                studentId: rawId.toString(),
                studentName: name.toString(),
                studentEmail: email.isNotEmpty ? email : null,
              ),
            ),
          );
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
                    backgroundColor: _getAvatarColor(index).withOpacity(0.18),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getAvatarColor(index),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
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
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                    tooltip: 'More options',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onSelected: (value) {
                      if (value == 'view') {
                        final dynamic rawId =
                            student['id'] ?? student['user_id'] ?? student['student_id'];
                        if (rawId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TeacherStudentDetailPage(
                                classId: widget.classId,
                                studentId: rawId.toString(),
                                studentName: name.toString(),
                                studentEmail: email.isNotEmpty ? email : null,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'View Details',
                              style: textTheme.labelLarge?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: cs.outlineVariant, thickness: 0.6, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${completionPercentage.toStringAsFixed(0)}%',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            completionPercentage >= 100
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: completionPercentage >= 100
                                ? Colors.green.shade400
                                : cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quizzes',
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedQuizzes/$totalQuizzes',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Course Progress',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: totalQuizzes > 0 ? completionPercentage / 100 : 0.0,
                minHeight: 4,
                backgroundColor: cs.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
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
              style: textTheme.titleLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumberButtons(ColorScheme cs) {
    final buttons = <Widget>[];
    int start = (_currentPage - 1).clamp(1, _totalPages);
    int end = (_currentPage + 1).clamp(1, _totalPages);
    if (start == 1 && end < 3 && _totalPages >= 3) end = 3;
    if (end == _totalPages && start > 1 && _totalPages >= 3)
      start = _totalPages - 2;

    for (int i = start; i <= end; i++) {
      buttons.add(
        _pageButton(
          cs,
          label: '$i',
          enabled: true,
          active: i == _currentPage,
          onPressed: () => setState(() => _currentPage = i),
        ),
      );
      if (i != end) buttons.add(const SizedBox(width: 6));
    }
    return buttons;
  }

  Widget _pageButton(
    ColorScheme cs, {
    required String label,
    required bool enabled,
    bool active = false,
    VoidCallback? onPressed,
  }) {
    final bg = active ? cs.primary : cs.surfaceContainerHighest;
    final fg = active ? cs.onPrimary : cs.onSurface;
    final textTheme = Theme.of(context).textTheme;
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: enabled
            ? bg
            : cs.surfaceContainerHighest.withOpacity(0.6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: active ? cs.primary : cs.outlineVariant),
        ),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: enabled ? fg : cs.onSurfaceVariant.withOpacity(0.7),
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

