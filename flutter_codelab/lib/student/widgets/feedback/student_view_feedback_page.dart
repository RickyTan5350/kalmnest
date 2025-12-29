import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/feedback_api.dart';
import 'package:flutter_codelab/models/models.dart';
import 'package:flutter_codelab/constants/achievement_constants.dart';

class StudentViewFeedbackPage extends StatefulWidget {
  final String? authToken;
  final dynamic currentUser;

  const StudentViewFeedbackPage({
    super.key,
    this.authToken,
    this.currentUser,
  });

  @override
  State<StudentViewFeedbackPage> createState() => _StudentViewFeedbackPageState();
}

class _StudentViewFeedbackPageState extends State<StudentViewFeedbackPage> {
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
      List<Map<String, dynamic>> feedbacks;
      String? studentId;
      if (widget.currentUser != null) {
        if (widget.currentUser is Map && widget.currentUser['user_id'] != null) {
          studentId = widget.currentUser['user_id']?.toString();
        } else if (widget.currentUser is String) {
          studentId = widget.currentUser;
        } else {
          try {
            studentId = widget.currentUser.user_id?.toString();
          } catch (_) {}
        }
      }

      if (studentId != null && studentId.isNotEmpty) {
        feedbacks = await _apiService.getStudentFeedback(studentId);
      } else {
        feedbacks = await _apiService.getFeedback();
      }
      setState(() {
        _feedbackList.clear();
        for (var fb in feedbacks) {
          _feedbackList.add(FeedbackData(
            feedbackId: fb['feedback_id']?.toString() ?? '',
            studentName: fb['student_name'] ?? 'Unknown',
            studentId: fb['student_id'] ?? '',
            teacherName: fb['teacher_name'] ?? (fb['teacher'] is Map ? (fb['teacher']['name'] ?? fb['teacher']['full_name']) : null) ?? 'Unknown',
            teacherId: fb['teacher_id'] ?? '',
            topicId: fb['topic_id'] ?? '',
            topicName: fb['topic_name'] ?? fb['topic'] ?? 'Unknown',
            title: fb['title'] ?? 'No Title',
            feedback: fb['feedback'] ?? '',
            createdAt: fb['created_at'] ?? fb['createdAt'] ?? (fb['teacher'] is Map && fb['teacher']['created_at'] != null ? fb['teacher']['created_at'] : null),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feedback'),
        centerTitle: true,
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
                          const SizedBox(height: 8),
                          Text(
                            'Your teachers will provide feedback here',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
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
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Builder(builder: (context) {
                                            String iconValue = feedback.topicName.toLowerCase();
                                            if (iconValue == 'js') iconValue = 'javascript';
                                            
                                            final icon = getAchievementIcon(iconValue);
                                            final color = getAchievementColor(context, iconValue);

                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, color: color, size: 16),
                                                const SizedBox(width: 6),
                                                Text(
                                                  feedback.topicName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: color,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                          const SizedBox(height: 4),
                                          Text(
                                            feedback.title,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.message_outlined, color: colorScheme.primary),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  feedback.feedback,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From: ${feedback.teacherName}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(builder: (context) {
                                        final created = feedback.createdAt;
                                        if (created == null || created.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        DateTime? dt;
                                        try {
                                          dt = DateTime.parse(created).toLocal();
                                        } catch (_) {
                                          dt = null;
                                        }
                                        final ts = dt != null
                                            ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                                            : created;
                                        return Text(
                                          ts,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onPrimaryContainer.withOpacity(0.9),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
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
