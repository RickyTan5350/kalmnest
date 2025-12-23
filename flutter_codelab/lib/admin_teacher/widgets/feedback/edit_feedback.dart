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
  late FeedbackApiService _api;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _api = FeedbackApiService(token: widget.authToken);

    _topicController = TextEditingController(text: widget.feedback.topic);
    _feedbackController = TextEditingController(text: widget.feedback.feedback);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _api.editFeedback(
        feedbackId: widget.feedback.feedbackId,
        topic: _topicController.text,
        comment: _feedbackController.text,
      );

      widget.onUpdated(
        FeedbackData(
          feedbackId: widget.feedback.feedbackId,
          studentName: widget.feedback.studentName,
          studentId: widget.feedback.studentId,
          teacherName: widget.feedback.teacherName, 
          teacherId: widget.feedback.teacherId, 
          topic: _topicController.text,
          feedback: _feedbackController.text,
        ),
      );

      widget.showSnackBar(context, "Updated successfully!", Colors.green);
      Navigator.pop(context);
    } catch (e) {
      widget.showSnackBar(context, "Update failed: $e", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 236, 236, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Edit Feedback",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            TextFormField(
              controller: _topicController,
              decoration: InputDecoration(labelText: "Topic"),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: InputDecoration(labelText: "Feedback"),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
