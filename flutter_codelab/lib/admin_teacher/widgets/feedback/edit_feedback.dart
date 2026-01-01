import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/feedback_api.dart';
import 'package:flutter_codelab/models/models.dart';
import 'package:flutter_codelab/l10n/generated/app_localizations.dart';

void showEditFeedbackDialog({
  required BuildContext context,
  required FeedbackData feedback,
  required Function(FeedbackData) onUpdated,
  required Function(BuildContext, String, Color) showSnackBar,
  required String authToken,
}) {
  showDialog(
    context: context,
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
  late final TextEditingController _topicController;
  late final TextEditingController _feedbackController;
  late final TextEditingController _titleController;
  late FeedbackApiService _api;

  bool _isSaving = false;
  
  bool _isLoadingTopics = false;
  List<Map<String, dynamic>> _topics = [];
  String? _selectedTopicId;
  String? _selectedTopicName;

  @override
  void initState() {
    super.initState();
    _api = FeedbackApiService(token: widget.authToken);

    _topicController = TextEditingController(text: widget.feedback.topic);
    _titleController = TextEditingController(text: widget.feedback.title);
    _feedbackController = TextEditingController(text: widget.feedback.feedback);
    
    // Set initial topic selection
    _selectedTopicId = widget.feedback.topicId.isNotEmpty ? widget.feedback.topicId : null;
    _selectedTopicName = widget.feedback.topic;

    _loadTopics();
  }
  
  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final topics = await _api.getTopics();
      setState(() => _topics = topics);
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, 'Failed to load topics: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoadingTopics = false);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _api.editFeedback(
        feedbackId: widget.feedback.feedbackId,
        topic: _titleController.text, // Assuming API expects title in 'topic' field, or adjust if API changed
        comment: _feedbackController.text,
      );

      widget.onUpdated(
        FeedbackData(
          feedbackId: widget.feedback.feedbackId,
          studentName: widget.feedback.studentName,
          studentId: widget.feedback.studentId,
          teacherName: widget.feedback.teacherName, // Will be updated from API
          teacherId: widget.feedback.teacherId, // Will be updated from API
          topicId: _selectedTopicId ?? '',
          title: _titleController.text,
          topic: _selectedTopicName ?? widget.feedback.topic,
          feedback: _feedbackController.text,
        ),
      );

      if (mounted) {
        widget.showSnackBar(context, AppLocalizations.of(context)!.changesSavedSuccess, Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        widget.showSnackBar(context, AppLocalizations.of(context)!.updateFailed(e.toString()), Colors.red);
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;


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
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.discardChangesTitle),
              content: Text(l10n.discardChangesConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.discard),
                ),
              ],
            );
          },
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
                    l10n.editFeedback,
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
                            labelText: l10n.selectTopic,
                            icon: Icons.subject,
                            colorScheme: colorScheme,
                          ),
                          hint: Text(l10n.selectATopic, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          items: [
                            if (_topics.isEmpty)
                              DropdownMenuItem<String?>(
                                value: _selectedTopicId,
                                child: Text(_selectedTopicName ?? l10n.currentTopic),
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
                              return l10n.pleaseSelectTopic;
                            }
                            return null;
                          },
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: l10n.title,
                      icon: Icons.title,
                      colorScheme: colorScheme,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? l10n.pleaseEnterTitle : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _feedbackController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: l10n.feedback,
                      icon: Icons.message,
                      colorScheme: colorScheme,
                    ),
                    maxLines: 5,
                    validator: (val) =>
                        val == null || val.isEmpty ? l10n.pleaseWriteFeedback : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: Text(
                          l10n.cancel,
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
                            : Text(l10n.saveChanges),
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

