import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:flutter_codelab/admin_teacher/widgets/class/class_customization.dart';
import 'package:intl/intl.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load student quiz data'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching student data: $e');
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
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get class color for AppBar
    final classColor = ClassCustomization.getColorByName(_classData?['color']);
    final color = classColor?.color ?? cs.primary;

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
              label: 'All Students',
              onTap: () => Navigator.of(context).pop(),
            ),
            BreadcrumbItem(
              label: _studentInfo?.name ?? widget.studentName,
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
                        _buildSectionTitle(cs, textTheme, 'General Info'),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.phone_outlined,
                          'Phone',
                          _studentInfo!.phoneNo,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.location_on_outlined,
                          'Address',
                          _studentInfo!.address,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.transgender,
                          'Gender',
                          _studentInfo!.gender,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.calendar_today,
                          'Joined Date',
                          _studentInfo!.joinedDate.split('T')[0],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          cs,
                          textTheme,
                          Icons.info_outline,
                          'Account Status',
                          _studentInfo!.accountStatus.toUpperCase(),
                          valueColor: _studentInfo!.accountStatus == 'active'
                              ? Colors.green
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
                      _buildSectionTitle(cs, textTheme, 'Quizzes'),
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
                                      color: cs.onSurfaceVariant.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No quizzes found',
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
                                  .map((quiz) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: _buildQuizItem(cs, textTheme, quiz),
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
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            cs,
            textTheme,
            'Total Quizzes',
            '$_totalQuizzes',
            Icons.quiz,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            cs,
            textTheme,
            'Completed',
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
            'Pending',
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
            'Completion Rate',
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
                  color: (iconColor ?? cs.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? cs.primary,
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

  Widget _buildQuizItem(
    ColorScheme cs,
    TextTheme textTheme,
    Map<String, dynamic> quiz,
  ) {
    final isCompleted = quiz['is_completed'] == true;
    final levelType = quiz['level_type'];
    final levelTypeName = levelType != null
        ? levelType['level_type_name'] ?? 'Unknown'
        : 'Unknown';

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
                          ? 'Completed: ${_formatDate(quiz['completion_date'])}'
                          : 'Status: Pending',
                      style: textTheme.bodySmall?.copyWith(
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Assigned: ${_formatDate(quiz['created_at'])}',
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

