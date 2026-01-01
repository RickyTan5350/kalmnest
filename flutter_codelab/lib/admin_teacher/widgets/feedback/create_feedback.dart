import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/feedback_api.dart';
import 'package:flutter_codelab/models/models.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

void showCreateFeedbackDialog({
  required BuildContext context,
  required void Function(BuildContext context, String message, Color color) showSnackBar,
  required void Function(FeedbackData) onFeedbackAdded,
  required String authToken,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return CreateFeedbackDialog(
        showSnackBar: showSnackBar,
        onFeedbackAdded: onFeedbackAdded,
        authToken: authToken,
      );
    },
  );
}

class CreateFeedbackDialog extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color) showSnackBar;
  final void Function(FeedbackData) onFeedbackAdded;
  final String authToken;

  const CreateFeedbackDialog({
    super.key,
    required this.showSnackBar,
    required this.onFeedbackAdded,
    required this.authToken,
  });

  @override
  State<CreateFeedbackDialog> createState() => _CreateFeedbackDialogState();
}

class _CreateFeedbackDialogState extends State<CreateFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  late final FeedbackApiService _apiService;

  String? _selectedStudent;
  String? _selectedStudentId;
  bool _isLoading = false;
  bool _isLoadingStudents = false;

  List<Map<String, dynamic>> _students = [];
  
  bool _isLoadingTopics = false;
  List<Map<String, dynamic>> _topics = [];
  String? _selectedTopicId;
  String? _selectedTopicName;

  @override
  void initState() {
    super.initState();
    // Initialize FeedbackApiService WITH the auth token
    _apiService = FeedbackApiService(token: widget.authToken);
    _loadStudents();
    _loadTopics();
  }

  Future<void> _loadStudents() async {
  setState(() => _isLoadingStudents = true);

  try {
    final students = await _apiService.getStudents(); // Call Laravel API
    setState(() => _students = students);
  } catch (e) {
    if (mounted) {
      widget.showSnackBar(context, AppLocalizations.of(context)!.failedToLoadStudents(e.toString()), Colors.red);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoadingStudents = false);
    }
  }
}

  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final topics = await _apiService.getTopics();
      // Only keep topics that act as categories if needed, or all.
      setState(() => _topics = topics);
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, 'Failed to load topics: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoadingTopics = false);
    }
  }

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

    if (_selectedStudentId == null || _selectedStudent == null) {
      widget.showSnackBar(context, AppLocalizations.of(context)!.pleaseSelectStudent, Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the backend API to create feedback
      await _apiService.createFeedback(
        studentId: _selectedStudentId!,
        topic: _topicController.text,
        comment: _feedbackController.text,
      );

      // Create local FeedbackData object
      final feedbackData = FeedbackData(
        feedbackId: '',
        studentName: _selectedStudent!,
        studentId: _selectedStudentId!,
        teacherName: 'Unknown', // Will be updated from API
        teacherId: '', // Will be updated from API
        topicId: _selectedTopicId ?? '',
        title: _topicController.text,
        topic: _selectedTopicName ?? 'General',
        feedback: _feedbackController.text,
      );

      // Pass the feedback to the parent
      widget.onFeedbackAdded(feedbackData);

      if (mounted) {
        widget.showSnackBar(context, AppLocalizations.of(context)!.feedbackSentTo(_selectedStudent!), Colors.green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, AppLocalizations.of(context)!.unknownErrorOccurred(e.toString()), Colors.red);
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
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 244, 246, 255),
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
                  l10n.newFeedback,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Student Dropdown
                _isLoadingStudents
                    ? SizedBox(
                        height: 50,
                        child: Center(
                          child: CircularProgressIndicator(color: colorScheme.primary),
                        ),
                      )
                    : DropdownButtonFormField<String?>(
                        initialValue: _selectedStudentId,
                        dropdownColor: const Color.fromARGB(255, 239, 243, 255),
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          labelText: l10n.selectStudent,
                          icon: Icons.person,
                          colorScheme: colorScheme,
                        ),
                        hint: Text(l10n.selectAStudent, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        items: [
                          if (_students.isEmpty)
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.noStudentsAvailable, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            )
                          else
                            ..._students
                                .map<DropdownMenuItem<String?>>((student) {
                                  final id = student['id'] as String? ?? '';
                                  final name = student['name'] as String? ?? 'Unknown';
                                  if (id.isEmpty) return const DropdownMenuItem(value: null, child: SizedBox.shrink());
                                  return DropdownMenuItem<String?>(
                                    value: id,
                                    child: Text(name),
                                  );
                                })
                                ,
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStudentId = value;
                            if (value != null && value.isNotEmpty) {
                              _selectedStudent = _students
                                  .firstWhere((s) => s['id'] == value, orElse: () => {'name': 'Unknown'})['name'] as String?;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseSelectStudent;
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Topic Dropdown
                _isLoadingTopics
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String?>(
                        value: _selectedTopicId,
                        dropdownColor: const Color.fromARGB(255, 239, 243, 255),
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          labelText: l10n.selectTopic,
                          icon: Icons.subject,
                          colorScheme: colorScheme,
                        ),
                        hint: Text(l10n.selectATopic, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        items: _topics.map<DropdownMenuItem<String?>>((topic) {
                          final id = topic['topic_id']?.toString() ?? '';
                          final name = topic['topic_name'] as String? ?? 'Unknown';
                          return DropdownMenuItem<String?>(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTopicId = value;
                            if (value != null) {
                              _selectedTopicName = _topics.firstWhere((t) => t['topic_id'].toString() == value)['topic_name'];
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseSelectTopic;
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _topicController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    labelText: l10n.title,
                    hintText: l10n.titleHint,
                    icon: Icons.title,
                    colorScheme: colorScheme,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterTitle;
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
                    labelText: l10n.feedback,
                    hintText: l10n.feedbackHint,
                    icon: Icons.message,
                    colorScheme: colorScheme,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseWriteFeedback;
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
                        l10n.cancel,
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
                          : Text(l10n.send),
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
