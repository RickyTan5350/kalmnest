import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/class_api.dart';
import 'package:flutter_codelab/api/user_api.dart';
import 'package:flutter_codelab/models/user_data.dart';
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
      // Fetch student info and quiz data in parallel
      final studentInfoFuture = _userApi.getUserDetails(widget.studentId);
      final quizDataFuture = ClassApi.getStudentQuizzes(
        widget.classId,
        widget.studentId,
      );

      final studentInfo = await studentInfoFuture;
      final result = await quizDataFuture;

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _studentInfo = studentInfo;
          _quizzes = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _totalQuizzes = result['total_quizzes'] ?? 0;
          _completedQuizzes = result['completed_quizzes'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() {
          _studentInfo = studentInfo;
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load student quiz data'),
              backgroundColor: Colors.red,
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
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

                      // Student Info Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: cs.primaryContainer,
                                    child: Text(
                                      _getInitials(
                                        _studentInfo?.name ?? widget.studentName,
                                      ),
                                      style: textTheme.headlineSmall?.copyWith(
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
                                          style: textTheme.headlineSmall?.copyWith(
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
                                const SizedBox(height: 16),
                                Divider(color: cs.outlineVariant),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  cs,
                                  textTheme,
                                  Icons.phone_outlined,
                                  'Phone',
                                  _studentInfo!.phoneNo,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  cs,
                                  textTheme,
                                  Icons.location_on_outlined,
                                  'Address',
                                  _studentInfo!.address,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  cs,
                                  textTheme,
                                  Icons.transgender,
                                  'Gender',
                                  _studentInfo!.gender,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  cs,
                                  textTheme,
                                  Icons.calendar_today,
                                  'Joined Date',
                                  _studentInfo!.joinedDate.split('T')[0],
                                ),
                                const SizedBox(height: 8),
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
                                  'Total Quizzes',
                                  '$_totalQuizzes',
                                  Icons.quiz,
                                ),
                              ),
                              const SizedBox(width: 12),
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
                              const SizedBox(width: 12),
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
                              const SizedBox(width: 12),
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

                      // Quizzes List
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
                                'Quizzes',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
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
                                              color: cs.onSurfaceVariant
                                                  .withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No quizzes found',
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
                                      children: _filteredQuizzes
                                          .map((quiz) => _buildQuizItem(
                                                cs,
                                                textTheme,
                                                quiz,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.pending,
              color: isCompleted ? Colors.green : Colors.orange,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        levelTypeName,
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
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
                    fontSize: 12,
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned: ${_formatDate(quiz['created_at'])}',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
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

