import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/feedback_api.dart';
import 'package:flutter_codelab/models/models.dart';

void showEditFeedbackDialog({
  required BuildContext context,
  required FeedbackData feedback,
  required Function(FeedbackData) onUpdated,
  required Function(BuildContext, String, Color) showSnackBar,
  required String authToken,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => EditFeedbackDialog(
      feedback: feedback,
      onUpdated: onUpdated,
      showSnackBar: showSnackBar,
      authToken: authToken,
    ),
  );
}

class EditFeedbackDialog extends StatefulWidget {
  final FeedbackData feedback;
  final Function(FeedbackData) onUpdated;
  final Function(BuildContext, String, Color) showSnackBar;
  final String authToken;

  const EditFeedbackDialog({
    super.key,
    required this.feedback,
    required this.onUpdated,
    required this.showSnackBar,
    required this.authToken,
  });

  @override
  _EditFeedbackDialogState createState() => _EditFeedbackDialogState();
}

class _EditFeedbackDialogState extends State<EditFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _feedbackController;
  late FeedbackApiService _api;
  String? _selectedTopicId;
  String? _selectedTopicName;
  List<Map<String, dynamic>> _topics = [];
  bool _isLoadingTopics = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _api = FeedbackApiService(token: widget.authToken);
    _selectedTopicId = widget.feedback.topicId;
    _selectedTopicName = widget.feedback.topicName;
    _titleController = TextEditingController(text: widget.feedback.title);
    _feedbackController = TextEditingController(text: widget.feedback.feedback);
    _loadTopics();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final topics = await _api.getTopics();
      setState(() => _topics = topics);
    } catch (e) {
      print('EditFeedback: Error loading topics: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTopics = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _api.editFeedback(
        feedbackId: widget.feedback.feedbackId,
        topicId: _selectedTopicId!,
        title: _titleController.text,
        comment: _feedbackController.text,
      );

      widget.onUpdated(
        FeedbackData(
          feedbackId: widget.feedback.feedbackId,
          studentName: widget.feedback.studentName,
          studentId: widget.feedback.studentId,
          teacherName: widget.feedback.teacherName,
          teacherId: widget.feedback.teacherId,
          topicId: _selectedTopicId!,
          topicName: _selectedTopicName!,
          title: _titleController.text,
          feedback: _feedbackController.text,
          createdAt: widget.feedback.createdAt,
        ),
      );

      if (mounted) {
        widget.showSnackBar(context, "Changes saved successfully!", Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, "Update failed: $e", Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final hasChanges = _selectedTopicId != widget.feedback.topicId ||
            _titleController.text != widget.feedback.title ||
            _feedbackController.text != widget.feedback.feedback;

        if (!hasChanges) {
          Navigator.pop(context);
          return;
        }

        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (shouldDiscard == true && mounted) {
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
        backgroundColor: const Color.fromARGB(255, 242, 244, 251),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24.0),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Feedback',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoadingTopics
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String?>(
                          value: _selectedTopicId,
                          dropdownColor: const Color.fromARGB(255, 239, 243, 255),
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: _inputDecoration(
                            labelText: 'Select Topic',
                            icon: Icons.subject,
                            colorScheme: colorScheme,
                          ),
                          hint: Text('Select a topic', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          items: [
                            if (_topics.isEmpty)
                              DropdownMenuItem<String?>(
                                value: _selectedTopicId,
                                child: Text(_selectedTopicName ?? 'Current Topic'),
                              )
                            else
                              ..._topics.map<DropdownMenuItem<String?>>((topic) {
                                final id = topic['topic_id']?.toString() ?? '';
                                final name = topic['topic_name'] as String? ?? 'Unknown';
                                return DropdownMenuItem<String?>(
                                  value: id,
                                  child: Text(name),
                                );
                              }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTopicId = value;
                              if (value != null) {
                                  _selectedTopicName = _topics.firstWhere((t) => t['topic_id'].toString() == value, orElse: () => {'topic_name': _selectedTopicName})['topic_name'];
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a topic';
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Title',
                      icon: Icons.title,
                      colorScheme: colorScheme,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _feedbackController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Feedback',
                      icon: Icons.message,
                      colorScheme: colorScheme,
                    ),
                    maxLines: 5,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please write feedback' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
