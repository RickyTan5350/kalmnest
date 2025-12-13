import 'package:flutter/material.dart';
import 'package:flutter_codelab/api/note_api.dart';

class DeleteNoteHandler {
  static Future<void> showDeleteDialog(BuildContext context, String noteId) async {
    // 1. Access the theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final NoteApi api = NoteApi();

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // 2. Use theme surface color (Standard M3 dialog color)
          backgroundColor: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          
          title: Text(
            'Delete Note?', 
            style: TextStyle(color: colorScheme.onSurface)
          ),
          content: Text(
            'Are you sure you want to delete this note? This action cannot be undone.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            // 3. Cancel Button - Neutral Theme Color
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel', 
                style: TextStyle(color: colorScheme.onSurfaceVariant)
              ),
            ),
            
            // 4. Delete Button - Error Theme Color
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleting note...', 
                      style: TextStyle(color: colorScheme.onInverseSurface)
                    ),
                    backgroundColor: colorScheme.inverseSurface,
                  ),
                );

                bool success = await api.deleteNote(noteId);

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Note deleted',
                          style: TextStyle(color: colorScheme.onPrimaryContainer)
                        ), 
                        backgroundColor: colorScheme.primaryContainer, // Success/Info color
                      ),
                    );
                    Navigator.of(context).pop(); 
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete note',
                          style: TextStyle(color: colorScheme.onError)
                        ), 
                        backgroundColor: colorScheme.error, // Error color
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Delete', 
                style: TextStyle(
                  color: colorScheme.error, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ],
        );
      },
    );
  }
}