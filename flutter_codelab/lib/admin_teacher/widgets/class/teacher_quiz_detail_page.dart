import 'package:flutter/material.dart';
import 'package:code_play/api/class_api.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';

import 'package:intl/intl.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToLoadQuizStudentData),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching quiz students: $e');
      if (mounted) {
        setState(() => _loading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.unknownErrorOccurred(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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

  String _formatDate(dynamic date, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (date == null) return l10n.never;
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return l10n.never;
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
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get class color for AppBar
    final color = cs.primary;

    final quizName = _quiz?['level_name'] ?? widget.quizName ?? l10n.quiz;
    final levelType = _quiz?['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? l10n.unknown
        : l10n.unknown;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: l10n.classes,
              onTap: () {
                // Navigate back to class list
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            BreadcrumbItem(
              label: l10n.details,
              onTap: () {
                // Navigate back to class detail
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(
              label: l10n.allQuizzes,
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
            tooltip: l10n.refresh,
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
                                    '${l10n.createdAt}: ${_formatDate(_quiz!['created_at'], context)}',
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
                  l10n.statistics,
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
                l10n.totalStudents,
                '$_totalStudents',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.check_circle,
                  l10n.completed,
                  '$_completedStudents',
                  valueColor: cs.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.pending,
                  l10n.pending,
                  '${_totalStudents - _completedStudents}',
                  valueColor: cs.tertiary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildInfoRow(
                  cs,
                  textTheme,
                  Icons.trending_up,
                  l10n.completionRate,
                  _totalStudents > 0
                      ? '${((_completedStudents / _totalStudents) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  valueColor: cs.primary,
                ),
              ),
              const Divider(height: 30),

              const SizedBox(height: 32),

              // Filter Chips
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.all),
                    selected: _filter == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'all');
                      }
                    },
                  ),
                  FilterChip(
                    label: Text(l10n.completed),
                    selected: _filter == 'completed',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = 'completed');
                      }
                    },
                  ),
                  FilterChip(
                    label: Text(l10n.pending),
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
                  hintText: l10n.searchStudents,
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
                _buildEmptyState(cs, textTheme, context)
              else
                ..._displayedStudents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final student = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildStudentCard(
                      context,
                      cs,
                      textTheme,
                      student,
                      index,
                    ),
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

  Widget _buildEmptyState(
    ColorScheme cs,
    TextTheme textTheme,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.noStudentsFound,
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
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
    Map<String, dynamic> student,
    int index,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = student['is_completed'] == true;
    final name = student['name'] ?? l10n.unknown;
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
                                    isCompleted ? l10n.completed : l10n.pending,
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
                            '${l10n.completed}: ${_formatDate(student['completion_date'], context)}',
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
