import 'package:flutter/material.dart';
import 'package:code_play/api/note_api.dart';

class DeleteNoteHandler {
  static Future<void> showDeleteDialog(
    BuildContext context,
    String noteId,
  ) async {
    // 1. Access the theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final NoteApi api = NoteApi();

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                bool success = await api.deleteNote(noteId);

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Note deleted successfully',
                          style: TextStyle(color: colorScheme.onPrimary),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green, // Success color
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete note',
                          style: TextStyle(color: colorScheme.onError),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colorScheme.error, // Error color
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.red),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
