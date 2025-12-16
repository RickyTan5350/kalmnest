import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/feedback_api.dart';
import 'package:flutter_codelab/models/models.dart';
import 'package:flutter_codelab/models/user_data.dart';
import 'package:flutter_codelab/admin_teacher/widgets/feedback/create_feedback.dart' as create_fb;
import 'package:flutter_codelab/admin_teacher/widgets/feedback/edit_feedback.dart' as edit_fb;
import 'package:flutter_codelab/student/widgets/feedback/student_view_feedback_page.dart';
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

  @override
  void initState() {
    super.initState();
    _apiService = FeedbackApiService(token: widget.authToken);
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
        _showSnackBar(context, 'Failed to load feedback: $e', Colors.red);
      }
    }
  }

  List<FeedbackData> _parseFeedbackList(List<dynamic> feedbacks) {
    return feedbacks.map((fb) {
      return FeedbackData(
        feedbackId: fb['feedback_id']?.toString() ?? '',
        studentName: fb['student_name'] ?? 'Unknown',
        studentId: fb['student_id'] ?? '',
        teacherName: fb['teacher_name'] ??
            (fb['teacher'] is Map
                ? (fb['teacher']['name'] ?? fb['teacher']['full_name'])
                : null) ??
            'Unknown',
        teacherId: fb['teacher_id'] ?? '',
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
      final index = _feedbackList.indexWhere((f) => f.feedbackId == updated.feedbackId);
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
      builder: (context) => AlertDialog(
        title: const Text("Delete Feedback"),
        content: const Text("Are you sure you want to delete this feedback?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteFeedback(feedback.feedbackId);
        _deleteFeedback(feedback);
        _showSnackBar(context, 'Feedback deleted', Colors.green);
      } catch (e) {
        _showSnackBar(context, 'Delete failed: $e', Colors.red);
      }
    }
  }

  bool get _isTeacher => widget.currentUser?.isTeacher ?? false;
  bool get _isStudent => widget.currentUser?.isStudent ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _LoadingView();
    }

    if (_errorMessage != null) {
      return _ErrorView(
        errorMessage: _errorMessage!,
        onRetry: _loadFeedback,
      );
    }

    if (_feedbackList.isEmpty) {
      return _EmptyView(
        onAddFeedback: _openCreateFeedbackDialog,
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
}

// Loading State Widget
class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: CircularProgressIndicator(color: colorScheme.primary),
    );
  }
}

// Error State Widget
class _ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

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
            'Error loading feedback',
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
            label: const Text('Retry'),
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
            'No feedback yet',
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
            _buildTeacherInfo(colorScheme),

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
      style: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurfaceVariant,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTeacherInfo(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'From: ${feedback.teacherName}',
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
