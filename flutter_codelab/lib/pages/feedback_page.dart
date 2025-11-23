import 'package:flutter/material.dart';
import 'package:flutter_codelab/widgets/create_feedback.dart';
import 'package:flutter_codelab/api/feedback_api.dart';

class FeedbackPage extends StatefulWidget {
  final String? authToken; // Pass auth token from your auth provider

  const FeedbackPage({super.key, this.authToken});

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
            studentName: fb['student_name'] ?? 'Unknown',
            studentId: fb['student_id'] ?? '',
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
    showCreateFeedbackDialog(
      context: context,
      showSnackBar: _showSnackBar,
      onFeedbackAdded: _addFeedback,
      authToken: widget.authToken ?? '', // Default to empty string if null
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
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
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      
      
    );
  }
}
