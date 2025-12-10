import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/feedback_api.dart';
import 'package:flutter_codelab/models/models.dart';
import 'package:flutter_codelab/admin_teacher/widgets/create_feedback.dart' as create_fb;
import 'package:flutter_codelab/admin_teacher/widgets/edit_feedback.dart' as edit_fb;

class FeedbackPage extends StatefulWidget {
  final String? authToken; 
  final dynamic currentUser; 
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
        for (var fb in feedbacks) {
          _feedbackList.add(FeedbackData(
            feedbackId: fb['feedback_id']?.toString() ?? '',
            studentName: fb['student_name'] ?? 'Unknown',
            studentId: fb['student_id'] ?? '',
            teacherName: fb['teacher_name'] ?? 'Unknown',
            teacherId: fb['teacher_id'] ?? '',
            topic: fb['topic'] ?? '',
            feedback: fb['feedback'] ?? '',
          ));
        }
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

  void _showSnackBar(BuildContext context, String message, Color color) {
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

  void _openCreateFeedbackDialog() {
    create_fb.showCreateFeedbackDialog(
      context: context,
      showSnackBar: _showSnackBar,
      onFeedbackAdded: _addFeedback,
      authToken: widget.authToken ?? '', 
    );
  }

  void _confirmDelete(FeedbackData fb) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Feedback"),
      content: Text("Are you sure you want to delete this feedback?"),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Delete"),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await _apiService.deleteFeedback(fb.feedbackId);
              setState(() => _feedbackList.remove(fb));
              _showSnackBar(context, 'Feedback deleted', Colors.green);
            } catch (e) {
              _showSnackBar(context, 'Delete failed: $e', Colors.red);
            }
          },
        ),
      ],
    ),
  );
}
  void _updateFeedback(FeedbackData updated) {
  setState(() {
    final index =
        _feedbackList.indexWhere((f) => f.feedbackId == updated.feedbackId);
    if (index != -1) {
      _feedbackList[index] = updated;
    }
  });
}


void _openEditDialog(FeedbackData fb) {
  edit_fb.showEditFeedbackDialog(
    context: context,
    feedback: fb,
    onUpdated: _updateFeedback,
    showSnackBar: _showSnackBar,
    authToken: widget.authToken ?? '',
  );
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Feedback',
                onPressed: _openCreateFeedbackDialog,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : _errorMessage != null
              ? Center(
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
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadFeedback,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _feedbackList.isEmpty
                  ? Center(
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
                            onPressed: _openCreateFeedbackDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Feedback'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _feedbackList.length,
                      itemBuilder: (context, index) {
                        final feedback = _feedbackList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback.topic,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feedback.feedback,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _openEditDialog(feedback),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDelete(feedback),
                                    ),
                                  ],
                                ),
                               ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
