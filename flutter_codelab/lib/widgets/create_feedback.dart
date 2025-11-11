import 'package:flutter/material.dart';

// Model to hold feedback data
class FeedbackData {
  final String studentName;
  final String topic;
  final String feedback;

  FeedbackData({
    required this.studentName,
    required this.topic,
    required this.feedback,
  });
}

void showCreateFeedbackDialog({
  required BuildContext context,
  required void Function(BuildContext context, String message, Color color) showSnackBar,
  required void Function(FeedbackData) onFeedbackAdded,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return CreateFeedbackDialog(
        showSnackBar: showSnackBar,
        onFeedbackAdded: onFeedbackAdded,
      );
    },
  );
}

class CreateFeedbackDialog extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color) showSnackBar;
  final void Function(FeedbackData) onFeedbackAdded;

  const CreateFeedbackDialog({
    super.key,
    required this.showSnackBar,
    required this.onFeedbackAdded,
  });

  @override
  State<CreateFeedbackDialog> createState() => _CreateFeedbackDialogState();
}

class _CreateFeedbackDialogState extends State<CreateFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  String? _selectedStudent;
  bool _isLoading = false;

  // Example students list - replace with real data
  final List<String> _students = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'];

  @override
  void dispose() {
    _topicController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudent == null || _selectedStudent!.isEmpty) {
      widget.showSnackBar(context, 'Please select a student', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Create feedback data
      final feedbackData = FeedbackData(
        studentName: _selectedStudent!,
        topic: _topicController.text,
        feedback: _feedbackController.text,
      );

      // Pass the feedback to the parent
      widget.onFeedbackAdded(feedbackData);

      if (mounted) {
        widget.showSnackBar(context, 'Feedback sent to $_selectedStudent', Colors.green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, 'An error occurred: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

    return AlertDialog(
      backgroundColor: const Color(0xFF2E313D),
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
                  'New Feedback',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Student Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStudent,
                  dropdownColor: const Color(0xFF2E313D),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Select Student',
                    icon: Icons.person,
                    colorScheme: colorScheme,
                  ),
                  items: _students
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStudent = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a student';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Topic
                TextFormField(
                  controller: _topicController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Topic',
                    hintText: 'e.g., Code Quality',
                    icon: Icons.subject,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a topic';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Feedback
                TextFormField(
                  controller: _feedbackController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: 'Feedback',
                    hintText: 'Write your feedback here...',
                    icon: Icons.message,
                    colorScheme: colorScheme,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please write feedback';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
