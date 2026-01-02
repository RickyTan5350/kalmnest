import 'package:flutter/material.dart';
import 'package:code_play/api/feedback_api.dart';
import 'package:code_play/models/models.dart';
import 'package:code_play/models/user_data.dart';
import 'package:code_play/admin_teacher/widgets/feedback/create_feedback.dart'
    as create_fb;
import 'package:code_play/admin_teacher/widgets/feedback/edit_feedback.dart'
    as edit_fb;
import 'package:code_play/student/widgets/feedback/student_view_feedback_page.dart';
import 'package:code_play/enums/sort_enums.dart';
import 'package:code_play/constants/achievement_constants.dart';
import 'package:code_play/theme.dart';
import 'package:code_play/l10n/generated/app_localizations.dart';

class FeedbackPage extends StatefulWidget {
  final String? authToken;
  final UserDetails? currentUser;
  final List<String>? availableStudents;

  const FeedbackPage({
    super.key,
    this.authToken,
    this.currentUser,
    this.availableStudents,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final List<FeedbackData> _feedbackList = [];
  late FeedbackApiService _apiService;
  bool _isLoading = true;
  String? _errorMessage;

  // Filter/Sort State
  String _selectedTopicId = 'All';
  String _selectedStudentId = 'All';
  String _selectedTeacherId = 'All';
  SortOrder _sortOrder = SortOrder.descending;

  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];

  bool _isLoadingTopics = false;
  bool _isLoadingStudents = false;
  bool _isLoadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _apiService = FeedbackApiService(token: widget.authToken);
    _loadFeedback();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    // TODO: Implement loading of filters (topics, students, teachers)
    // For now we initialize with empty to prevent UI crashes,
    // but ideally we fetch these from API.
    // _topics = await _apiService.getTopics();
    // _students = await _apiService.getStudents();
    // _teachers = await _apiService.getTeachers();
  }

  void _handleRefresh() {
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feedbacks = await _apiService.getFeedback();
      setState(() {
        _feedbackList.clear();
        _feedbackList.addAll(_parseFeedbackList(feedbacks));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToLoadFeedback(e.toString()),
          Colors.red,
        );
      }
    }
  }

  List<FeedbackData> _parseFeedbackList(List<dynamic> feedbacks) {
    return feedbacks.map((fb) {
      return FeedbackData(
        feedbackId: fb['feedback_id']?.toString() ?? '',
        studentName: fb['student_name'] ?? 'Unknown',
        studentId: fb['student_id'] ?? '',
        teacherName:
            fb['teacher_name'] ??
            (fb['teacher'] is Map
                ? (fb['teacher']['name'] ?? fb['teacher']['full_name'])
                : null) ??
            'Unknown',
        teacherId: fb['teacher_id'] ?? '',
        topicId: fb['topic_id']?.toString() ?? '',
        topic: fb['topic'] ?? '',
        feedback: fb['feedback'] ?? '',
        createdAt: fb['created_at'] ?? fb['createdAt'],
      );
    }).toList();
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addFeedback(FeedbackData feedback) {
    setState(() {
      _feedbackList.insert(0, feedback);
    });
  }

  void _updateFeedback(FeedbackData updated) {
    setState(() {
      final index = _feedbackList.indexWhere(
        (f) => f.feedbackId == updated.feedbackId,
      );
      if (index != -1) {
        _feedbackList[index] = updated;
      }
    });
  }

  void _deleteFeedback(FeedbackData feedback) {
    setState(() {
      _feedbackList.remove(feedback);
    });
  }

  void _openCreateFeedbackDialog() {
    create_fb.showCreateFeedbackDialog(
      context: context,
      showSnackBar: _showSnackBar,
      onFeedbackAdded: _addFeedback,
      authToken: widget.authToken ?? '',
    );
  }

  void _openEditDialog(FeedbackData feedback) {
    edit_fb.showEditFeedbackDialog(
      context: context,
      feedback: feedback,
      onUpdated: _updateFeedback,
      showSnackBar: _showSnackBar,
      authToken: widget.authToken ?? '',
    );
  }

  Future<void> _confirmDelete(FeedbackData feedback) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteFeedbackTitle),
          content: Text(l10n.deleteFeedbackConfirmation),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteFeedback(feedback.feedbackId);
        _deleteFeedback(feedback);
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.feedbackDeleted,
          Colors.green,
        );
      } catch (e) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.deleteFailed(e.toString()),
          Colors.red,
        );
      }
    }
  }

  List<FeedbackData> get _filteredFeedback {
    List<FeedbackData> filtered = List.from(_feedbackList);

    // Filter by Topic
    if (_selectedTopicId != 'All') {
      filtered = filtered.where((f) => f.topicId == _selectedTopicId).toList();
    }

    // Filter by Student (for Teacher/Admin)
    if ((_isTeacher || widget.currentUser?.isAdmin == true) &&
        _selectedStudentId != 'All') {
      filtered = filtered
          .where((f) => f.studentId == _selectedStudentId)
          .toList();
    }

    // Filter by Teacher (for Student)
    if (_isStudent && _selectedTeacherId != 'All') {
      filtered = filtered
          .where((f) => f.teacherId == _selectedTeacherId)
          .toList();
    }

    // Sort by Timestamp
    filtered.sort((a, b) {
      final dateA = a.createdAt != null
          ? DateTime.tryParse(a.createdAt!) ?? DateTime(0)
          : DateTime(0);
      final dateB = b.createdAt != null
          ? DateTime.tryParse(b.createdAt!) ?? DateTime(0)
          : DateTime(0);

      if (_sortOrder == SortOrder.ascending) {
        return dateA.compareTo(dateB);
      } else {
        return dateB.compareTo(dateA);
      }
    });

    return filtered;
  }

  bool get _isTeacher => widget.currentUser?.isTeacher ?? false;
  bool get _isStudent => widget.currentUser?.isStudent ?? false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2.0,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.feedbacks,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- FILTERS & SORT ---
                _buildFilters(colors),
                const SizedBox(height: 16),

                // --- CONTENT ---
                Expanded(
                  child: Column(
                    children: [
                      if (!_isLoading &&
                          _errorMessage == null &&
                          _feedbackList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "${_filteredFeedback.length} ${l10n.results}",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _LoadingView();
    }

    if (_errorMessage != null) {
      return _ErrorView(errorMessage: _errorMessage!, onRetry: _loadFeedback);
    }

    if (_feedbackList.isEmpty) {
      return _EmptyView(onAddFeedback: _openCreateFeedbackDialog);
    }

    final filtered = _filteredFeedback;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noFeedbackFound),
          ],
        ),
      );
    }

    return _FeedbackListView(
      feedbackList: _feedbackList,
      isTeacher: _isTeacher,
      isStudent: _isStudent,
      onEdit: _openEditDialog,
      onDelete: _confirmDelete,
    );
  }

  Widget _buildFilters(ColorScheme colors) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(
                          'All',
                          style: TextStyle(
                            color: _selectedTopicId == 'All'
                                ? colors.primary
                                : colors.onSurface,
                          ),
                        ),
                        selected: _selectedTopicId == 'All',
                        onSelected: (selected) {
                          setState(() {
                            _selectedTopicId = 'All';
                          });
                        },
                      ),
                    ),
                    ..._topics.map((topic) {
                      final topicId = topic['topic_id']?.toString() ?? '';
                      final topicName = topic['topic_name'] ?? 'Unknown';
                      final isSelected = _selectedTopicId == topicId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            topicName,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTopicId = selected ? topicId : 'All';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sort Button
            PopupMenuButton<SortOrder>(
              icon: const Icon(Icons.sort),
              tooltip: l10n.sortByTime,
              onSelected: (order) {
                setState(() {
                  _sortOrder = order;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    l10n.sortByTime,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                CheckedPopupMenuItem(
                  value: SortOrder.descending,
                  checked: _sortOrder == SortOrder.descending,
                  child: Text(l10n.newestFirst),
                ),
                CheckedPopupMenuItem(
                  value: SortOrder.ascending,
                  checked: _sortOrder == SortOrder.ascending,
                  child: Text(l10n.oldestFirst),
                ),
              ],
            ),
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _handleRefresh,
              tooltip: l10n.refreshFeedbacks,
            ),
          ],
        ),
        if (_isTeacher || widget.currentUser?.isAdmin == true) ...[
          const SizedBox(height: 8),
          _isLoadingStudents
              ? const LinearProgressIndicator()
              : SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    decoration: InputDecoration(
                      labelText: l10n.filterByStudent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'All',
                        child: Text('All Students'),
                      ),
                      ..._students.map(
                        (s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedStudentId = val ?? 'All';
                      });
                    },
                  ),
                ),
        ],
        if (_isStudent) ...[
          const SizedBox(height: 8),
          _isLoadingTeachers
              ? const LinearProgressIndicator()
              : SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: InputDecoration(
                      labelText: l10n.filterByTeacher,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'All',
                        child: Text('All Teachers'),
                      ),
                      ..._teachers.map(
                        (t) => DropdownMenuItem(
                          value: t['id'] as String,
                          child: Text(t['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedTeacherId = val ?? 'All';
                      });
                    },
                  ),
                ),
        ],
      ],
    );
  }
}

// Loading State Widget
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(child: CircularProgressIndicator(color: colorScheme.primary));
  }
}

// Error State Widget
class _ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.errorLoadingFeedback,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }
}

// Empty State Widget
class _EmptyView extends StatelessWidget {
  final VoidCallback onAddFeedback;

  const _EmptyView({required this.onAddFeedback});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feedback_outlined, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noFeedbackYet,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddFeedback,
            icon: const Icon(Icons.add),
            label: const Text('Add Feedback'),
          ),
        ],
      ),
    );
  }
}

// Feedback List View Widget
class _FeedbackListView extends StatelessWidget {
  final List<FeedbackData> feedbackList;
  final bool isTeacher;
  final bool isStudent;
  final Function(FeedbackData) onEdit;
  final Function(FeedbackData) onDelete;

  const _FeedbackListView({
    required this.feedbackList,
    required this.isTeacher,
    required this.isStudent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: feedbackList.length,
      itemBuilder: (context, index) {
        final feedback = feedbackList[index];
        return _FeedbackCard(
          feedback: feedback,
          isTeacher: isTeacher,
          isStudent: isStudent,
          onEdit: () => onEdit(feedback),
          onDelete: () => onDelete(feedback),
        );
      },
    );
  }
}

// Feedback Card Widget
class _FeedbackCard extends StatelessWidget {
  final FeedbackData feedback;
  final bool isTeacher;
  final bool isStudent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeedbackCard({
    required this.feedback,
    required this.isTeacher,
    required this.isStudent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name (only for teachers/admins)
            if (!isStudent) _buildStudentHeader(colorScheme),
            if (!isStudent) const SizedBox(height: 8),

            // Topic
            _buildTopic(colorScheme),
            const SizedBox(height: 8),

            // Feedback content
            _buildFeedbackContent(colorScheme),
            const SizedBox(height: 12),

            // Teacher info and timestamp
            _buildTeacherInfo(context, colorScheme),

            // Action buttons (only for teachers)
            if (isTeacher) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          feedback.studentName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Icon(Icons.person_outline, color: colorScheme.primary),
      ],
    );
  }

  Widget _buildTopic(ColorScheme colorScheme) {
    return Text(
      feedback.topic,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildFeedbackContent(ColorScheme colorScheme) {
    return Text(
      feedback.feedback,
      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTeacherInfo(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.from(feedback.teacherName),
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _buildTimestamp(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTimestamp(ColorScheme colorScheme) {
    final created = feedback.createdAt;
    if (created == null || created.isEmpty) {
      return const SizedBox.shrink();
    }

    final formattedDate = _formatDateTime(created);
    return Text(
      formattedDate,
      style: TextStyle(
        fontSize: 11,
        color: colorScheme.onSurfaceVariant.withOpacity(0.9),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dt = DateTime.parse(dateTimeString).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeString;
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
          tooltip: 'Edit feedback',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Delete feedback',
        ),
      ],
    );
  }
}
