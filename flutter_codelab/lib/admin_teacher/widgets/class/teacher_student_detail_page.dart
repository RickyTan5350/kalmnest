import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';

import 'package:intl/intl.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

/// Teacher view: Student detail page showing student info and quiz completion status
class TeacherStudentDetailPage extends StatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String? studentEmail;

  const TeacherStudentDetailPage({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
  });

  @override
  State<TeacherStudentDetailPage> createState() =>
      _TeacherStudentDetailPageState();
}

class _TeacherStudentDetailPageState extends State<TeacherStudentDetailPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _quizzes = [];
  int _totalQuizzes = 0;
  int _completedQuizzes = 0;
  String _filter = 'all'; // 'all', 'completed', 'pending'
  UserDetails? _studentInfo;
  Map<String, dynamic>? _classData;
  final UserApi _userApi = UserApi();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Fetch class data, student info and quiz data in parallel
      final classDataFuture = ClassApi.fetchClassById(widget.classId);
      final studentInfoFuture = _userApi.getUserDetails(widget.studentId);
      final quizDataFuture = ClassApi.getStudentQuizzes(
        widget.classId,
        widget.studentId,
      );

      final classData = await classDataFuture;
      final studentInfo = await studentInfoFuture;
      final result = await quizDataFuture;

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _classData = classData;
          _studentInfo = studentInfo;
          _quizzes = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _totalQuizzes = result['total_quizzes'] ?? 0;
          _completedQuizzes = result['completed_quizzes'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() {
          _classData = classData;
          _studentInfo = studentInfo;
          _loading = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToLoadStudentQuizData),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching student data: $e');
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

  List<Map<String, dynamic>> get _filteredQuizzes {
    switch (_filter) {
      case 'completed':
        return _quizzes.where((q) => q['is_completed'] == true).toList();
      case 'pending':
        return _quizzes.where((q) => q['is_completed'] != true).toList();
      default:
        return _quizzes;
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
              label: l10n.allStudents,
              onTap: () => Navigator.of(context).pop(),
            ),
            BreadcrumbItem(label: _studentInfo?.name ?? widget.studentName),
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
              // Student Info Section - Left aligned, no centered header
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
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              _getInitials(
                                _studentInfo?.name ?? widget.studentName,
                              ),
                              style: textTheme.headlineMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _studentInfo?.name ?? widget.studentName,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                if (_studentInfo?.email != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _studentInfo!.email,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_studentInfo != null) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle(cs, textTheme, l10n.generalInfo),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.phone_outlined,
                          l10n.phone,
                          _studentInfo!.phoneNo,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.location_on_outlined,
                          l10n.address,
                          _studentInfo!.address,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.transgender,
                          l10n.gender,
                          _studentInfo!.gender,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.calendar_today,
                          l10n.joinedDate,
                          _studentInfo!.joinedDate.split('T')[0],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.info_outline,
                          l10n.accountStatus,
                          _studentInfo!.accountStatus.toUpperCase(),
                          valueColor: _studentInfo!.accountStatus == 'active'
                              ? cs.primary
                              : cs.error,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Statistics Section
              _buildStatisticsSection(cs, textTheme),

              const SizedBox(height: 24),

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

              // Quizzes List
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
                      _buildSectionTitle(cs, textTheme, l10n.quizzes),
                      const SizedBox(height: 16),
                      _filteredQuizzes.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.quiz_outlined,
                                      size: 64,
                                      color: cs.onSurfaceVariant.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.noQuizzesFound,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: _filteredQuizzes
                                  .map(
                                    (quiz) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: _buildQuizItem(
                                        context,
                                        cs,
                                        textTheme,
                                        quiz,
                                      ),
                                    ),
                                  )
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
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, TextTheme textTheme, String title) {
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      ),
    );
  }

  Widget _buildStatisticsSection(ColorScheme cs, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            cs,
            textTheme,
            l10n.totalQuizzes.replaceAll(':', ''),
            '$_totalQuizzes',
            Icons.quiz,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            cs,
            textTheme,
            l10n.completed,
            '$_completedQuizzes',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            cs,
            textTheme,
            l10n.pending,
            '${_totalQuizzes - _completedQuizzes}',
            Icons.pending,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            cs,
            textTheme,
            l10n.completionRate,
            _totalQuizzes > 0
                ? '${((_completedQuizzes / _totalQuizzes) * 100).toStringAsFixed(0)}%'
                : '0%',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
      ],
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: cs.outline.withOpacity(0.3), width: 1.0),
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
                  color: (iconColor ?? cs.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: iconColor ?? cs.primary, size: 28),
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

  Widget _buildQuizItem(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
    Map<String, dynamic> quiz,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = quiz['is_completed'] == true;
    final levelType = quiz['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? l10n.unknown
        : l10n.unknown;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : cs.outline.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.pending,
                  color: isCompleted ? Colors.green : Colors.orange,
                  size: 24,
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
                            quiz['level_name'] ?? 'No Name',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            levelTypeName,
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: cs.primaryContainer.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? '${l10n.completed}: ${_formatDate(quiz['completion_date'], context)}'
                          : '${l10n.status}: ${l10n.pending}',
                      style: textTheme.bodySmall?.copyWith(
                        color: isCompleted ? cs.primary : cs.tertiary,
                      ),
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.assigned}: ${_formatDate(quiz['created_at'], context)}',
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
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
