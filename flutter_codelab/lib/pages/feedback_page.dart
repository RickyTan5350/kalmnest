import 'package:flutter/material.dart';
import 'package:code_play/api/feedback_api.dart';
import 'package:code_play/models/models.dart';
import 'package:code_play/models/user_data.dart';
import 'package:code_play/admin_teacher/widgets/feedback/create_feedback.dart'
    as create_fb;
import 'package:code_play/admin_teacher/widgets/feedback/edit_feedback.dart'
    as edit_fb;
import 'package:code_play/enums/sort_enums.dart';
import 'package:code_play/constants/achievement_constants.dart';
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

  // Filter State
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];

  bool _isLoadingTopics = false;
  bool _isLoadingStudents = false;
  bool _isLoadingTeachers = false;

  String _selectedTopicId = 'All';
  String _selectedStudentId = 'All';
  String _selectedTeacherId = 'All';

  SortOrder _sortOrder = SortOrder.descending;

  // Selection State (for bulk delete)
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _apiService = FeedbackApiService(token: widget.authToken);
    _loadFeedback();
    _loadTopics();
    if (_isTeacher || widget.currentUser?.isAdmin == true) {
      _loadStudents();
    }
    if (_isStudent) {
      _loadTeachers();
    }
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

  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final topics = await _apiService.getTopics();
      setState(() => _topics = topics);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingTopics = false);
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final students = await _apiService.getStudents();
      setState(() => _students = students);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final teachers = await _apiService.getTeachers();
      setState(() => _teachers = teachers);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFeedback();
    await _loadTopics();
    if (_isTeacher || widget.currentUser?.isAdmin == true)
      await _loadStudents();
    if (_isStudent) await _loadTeachers();
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
        title: fb['title'] ?? fb['topic_name'] ?? '',
        topic: fb['topic_name'] ?? fb['topic'] ?? '',
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

  // Selection methods
  void _toggleSelection(String feedbackId) {
    setState(() {
      if (_selectedIds.contains(feedbackId)) {
        _selectedIds.remove(feedbackId);
      } else {
        _selectedIds.add(feedbackId);
      }
    });
  }

  // Bulk delete function
  Future<void> _deleteSelectedFeedbacks() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.deleteFeedbackTitle),
          content: Text(l10n.deleteFeedbacksConfirmation(_selectedIds.length)),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });

    int successCount = 0;
    int failCount = 0;
    List<String> successfullyDeletedIds = [];

    for (final id in _selectedIds) {
      try {
        await _apiService.deleteFeedback(id);
        successCount++;
        successfullyDeletedIds.add(id);
      } catch (e) {
        print("Failed to delete feedback $id: $e");
        failCount++;
      }
    }

    if (mounted) {
      setState(() {
        _isDeleting = false;
        _selectedIds.removeWhere((id) => successfullyDeletedIds.contains(id));
        // Remove deleted feedbacks from list
        _feedbackList.removeWhere(
          (f) => successfullyDeletedIds.contains(f.feedbackId),
        );
      });

      String message;
      Color snackColor;
      final l10n = AppLocalizations.of(context)!;
      if (failCount == 0) {
        message = l10n.feedbacksDeletedSuccessfully(successCount);
        snackColor = Colors.green;
      } else {
        message = 'Deleted: $successCount, Failed: $failCount';
        snackColor = failCount > 0 ? Colors.red : Colors.orange;
      }

      _showSnackBar(context, message, snackColor);
    }
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
      padding: const EdgeInsets.fromLTRB(2.0, 2.0, 16.0, 16.0),
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
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            16.0,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: (_isTeacher && _selectedIds.isNotEmpty)
                                ? _buildSelectionHeader(context)
                                : _buildSortHeader(context),
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

  Widget _buildSortHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey("SortHeader"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
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
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey("SelectionHeader"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
              Text(
                "${_selectedIds.length} ${AppLocalizations.of(context)!.selected}",
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          if (_isDeleting)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: _deleteSelectedFeedbacks,
            ),
        ],
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
      feedbackList: filtered, // Use filtered list instead of full list
      isTeacher: _isTeacher,
      isStudent: _isStudent,
      isAdmin: widget.currentUser?.isAdmin ?? false,
      selectedIds: _selectedIds,
      onToggleSelection: _toggleSelection,
      hasAnySelection: _selectedIds.isNotEmpty,
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
              icon: const Icon(Icons.filter_list),
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
                      DropdownMenuItem(
                        value: 'All',
                        child: Text(l10n.allStudents),
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
                      DropdownMenuItem(
                        value: 'All',
                        child: Text(l10n.allTeachers),
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
  final bool isAdmin;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelection;
  final bool hasAnySelection;
  final Function(FeedbackData) onEdit;
  final Function(FeedbackData) onDelete;

  const _FeedbackListView({
    required this.feedbackList,
    required this.isTeacher,
    required this.isStudent,
    required this.isAdmin,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.hasAnySelection,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: feedbackList.length,
      itemBuilder: (context, index) {
        final feedback = feedbackList[index];
        final isSelected = selectedIds.contains(feedback.feedbackId);
        return _FeedbackListTile(
          feedback: feedback,
          isTeacher: isTeacher,
          isStudent: isStudent,
          isAdmin: isAdmin,
          isSelected: isSelected,
          hasAnySelection: hasAnySelection,
          onToggleSelection: () => onToggleSelection(feedback.feedbackId),
          onEdit: () => onEdit(feedback),
          onDelete: () => onDelete(feedback),
        );
      },
    );
  }
}

// Feedback List Tile Widget (similar to achievement list)
class _FeedbackListTile extends StatelessWidget {
  final FeedbackData feedback;
  final bool isTeacher;
  final bool isStudent;
  final bool isAdmin;
  final bool isSelected;
  final bool hasAnySelection;
  final VoidCallback onToggleSelection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeedbackListTile({
    required this.feedback,
    required this.isTeacher,
    required this.isStudent,
    required this.isAdmin,
    required this.isSelected,
    required this.hasAnySelection,
    required this.onToggleSelection,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Get icon based on topic name, with fallback logic
    final topicNameLower = feedback.topic.toLowerCase();
    // Try to match common topic name patterns
    String iconKey = topicNameLower;
    if (topicNameLower.contains('html')) {
      iconKey = 'html';
    } else if (topicNameLower.contains('css')) {
      iconKey = 'css';
    } else if (topicNameLower.contains('javascript') ||
        topicNameLower.contains('js')) {
      iconKey = 'javascript';
    } else if (topicNameLower.contains('php')) {
      iconKey = 'php';
    } else if (topicNameLower.contains('quiz') ||
        topicNameLower.contains('test')) {
      iconKey = 'quiz';
    }

    final topicColor = getAchievementColor(context, iconKey);
    final topicIcon = getAchievementIcon(iconKey);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: topicColor.withOpacity(0.1),
          child: Icon(topicIcon, color: topicColor, size: 20),
        ),
        title: Text(
          feedback.title.isNotEmpty ? feedback.title : feedback.topic,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          AppLocalizations.of(context)!.from(feedback.teacherName),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () {
          // If any items are selected, toggle selection; otherwise show dialog
          if (isTeacher && hasAnySelection) {
            onToggleSelection();
          } else {
            _showFeedbackDetailDialog(
              context,
              feedback,
              isTeacher,
              isAdmin,
              onEdit,
              onDelete,
            );
          }
        },
        onLongPress: () {
          if (isTeacher) {
            onToggleSelection();
          }
        },
      ),
    );
  }

  void _showFeedbackDetailDialog(
    BuildContext context,
    FeedbackData feedback,
    bool isTeacher,
    bool isAdmin,
    VoidCallback onEdit,
    VoidCallback onDelete,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    // Get icon based on topic name, with fallback logic
    final topicNameLower = feedback.topic.toLowerCase();
    // Try to match common topic name patterns
    String iconKey = topicNameLower;
    if (topicNameLower.contains('html')) {
      iconKey = 'html';
    } else if (topicNameLower.contains('css')) {
      iconKey = 'css';
    } else if (topicNameLower.contains('javascript') ||
        topicNameLower.contains('js')) {
      iconKey = 'javascript';
    } else if (topicNameLower.contains('php')) {
      iconKey = 'php';
    } else if (topicNameLower.contains('quiz') ||
        topicNameLower.contains('test')) {
      iconKey = 'quiz';
    }

    final topicColor = getAchievementColor(context, iconKey);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and teacher name
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: topicColor.withOpacity(0.1),
                    child: Icon(
                      getAchievementIcon(feedback.topic.toLowerCase()),
                      color: topicColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.title.isNotEmpty
                              ? feedback.title
                              : feedback.topic,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.from(feedback.teacherName),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Student name (for teacher and admin view)
              if (isTeacher || isAdmin) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.student}: ${feedback.studentName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Feedback content
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    feedback.feedback,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              // Time sent (below feedback content)
              if (feedback.createdAt != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(feedback.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              // Edit and Delete buttons for teachers (at the bottom)
              if (isTeacher) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onEdit();
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(AppLocalizations.of(context)!.edit),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onDelete();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
}
