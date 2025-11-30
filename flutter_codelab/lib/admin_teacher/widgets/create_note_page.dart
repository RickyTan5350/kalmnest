import 'package:flutter/material.dart';
import 'package:flutter_codelab/admin_teacher/widgets/file_helper.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/markdown_preview.dart';
import 'package:flutter_codelab/admin_teacher/widgets/upload_single_file.dart';
import 'package:flutter_codelab/api/note_api.dart';
import 'package:flutter_codelab/models/note_data.dart';
import 'dart:io';
// Import path package


void showCreateNotesDialog({
  required BuildContext context,
  // Pass the SnackBar helper from the main page to ensure it works with the Scaffold
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return CreateNotePage(showSnackBar: showSnackBar);
    },
  );
}


class CreateNotePage extends StatefulWidget {
    final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  
  // We no longer need to pass showSnackBar
  const CreateNotePage({super.key, required this.showSnackBar});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();

}

class _CreateNotePageState extends State<CreateNotePage> {
  final _formKey = GlobalKey<FormState>();
  // Assuming NoteApi and NoteData are correctly implemented elsewhere
  final NoteApi _noteApi = NoteApi();

  // Text Controllers (unchanged)
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteMarkdownController = TextEditingController();

  // State Variables (unchanged)
  String path = '';
  String? _selectedTopic;
  List<String> _selectedFileNames = [];
  bool _noteVisibility = true;
  bool _isLoading = false;

  final List<String> _topic = ['HTML', 'CSS', 'JS', 'PHP'];

  @override
  void initState() {
    super.initState();
    _noteMarkdownController.addListener(_onMarkdownChanged);
  }

  @override
  void dispose() {
    _noteMarkdownController.removeListener(_onMarkdownChanged);
    _noteTitleController.dispose();
    _noteMarkdownController.dispose();
    super.dispose();
  }

  void _onMarkdownChanged() {
    setState(() {});
  }

  void _updateSelectedFiles(List<String> fileNames) {
    setState(() {
      _selectedFileNames = fileNames;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fileContent = _noteMarkdownController.text;

    setState(() {
      _isLoading = true;
    });

    final String fileName =
        '${_noteTitleController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.md';

    FileHelper output = FileHelper(fileName: fileName, folderName: 'notes');
    final String relativePath = 'notes/$fileName';

    final data = NoteData(
      title: _noteTitleController.text,
      path: relativePath,
      visibility: _noteVisibility,
      topic: _selectedTopic ?? '',
    );

    try {
      final File file = await output.writeStringToFile(
        content: fileContent,
        fileName: fileName,
      );

      setState(() {
        _isLoading = true;
      });

      debugPrint('File Successfully Written to: ${file.path}');

      await _noteApi.createNote(data);
      if (mounted) {
        // Use the passed-in showSnackBar helper
        widget.showSnackBar(
          context,
          'Notes successfully created!',
          Colors.green,
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      String errorMessage;

      // Check for specific FileSystemException errors for clearer reporting
      if (e is FileSystemException) {
        // e.message usually contains details like "Permission denied" or "No space left on device"
        errorMessage = 'File System Error: ${e.message} (Path: ${e.path})';
      } else {
        // Catch any other general exceptions
        errorMessage = 'An unexpected error occurred while saving: $e';
      }

      if (mounted) {
        if (e.toString().startsWith(
          'Exception: ${NoteApi.validationErrorCode}:',
        )) {
          final message = e.toString().substring(
            'Exception(flutter): ${NoteApi.validationErrorCode}:'.length,
          );
          widget.showSnackBar(
            context,
            'Validation Error:\n$message',
            Colors.red,
          );
        } else {
          widget.showSnackBar(
            context,
            'An unknown error occurred(flutter).',
            Colors.red,
          );
        }
      }

      print(errorMessage);
      
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper for input styling (unchanged)
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

    return Scaffold(
      // --- NEW: Set background color for the whole page ---
      backgroundColor: const Color(0xFF2E313D),

      // --- NEW: AppBar for the page title ---
      appBar: AppBar(
        title: Text(
          'New Note',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E313D),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface), // Back arrow
      ),

      // --- NEW: FloatingActionButton for the Save action ---
      floatingActionButton: _isLoading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: colorScheme.secondary.withOpacity(0.5),
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _submitForm,
              label: const Text('Save Note'),
              icon: const Icon(Icons.save),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),

      // --- MODIFIED: Body of the page ---
      body: Center(
        child: ConstrainedBox(
          // --- NEW: Constrain width for readability on large screens ---
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            // --- NEW: Add padding to the whole form ---
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- All form fields below are UNCHANGED ---

                  // 1. Note Topic (Dropdown)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTopic,
                    dropdownColor: const Color(0xFF2E313D),
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Topic',
                      icon: Icons.category,
                      colorScheme: colorScheme,
                    ),
                    items: _topic
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTopic = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a topic';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Title
                  TextFormField(
                    controller: _noteTitleController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Note Title',
                      hintText: 'Enter a title for your note',
                      icon: Icons.title,
                      colorScheme: colorScheme,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. FILE UPLOAD WIDGET
                  FloatingActionButton(onPressed: uploadFile),
                  const SizedBox(height: 16),

                  // 4. MARKDOWN NOTES
                  TextFormField(
                    controller: _noteMarkdownController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Markdown Notes',
                      hintText: 'write with markdown',
                      icon: Icons.description,
                      colorScheme: colorScheme,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a markdown';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. LIVE PREVIEW
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Preview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MarkdownPreview(
                        markdownText: _noteMarkdownController.text,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 8. note visibility
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      'Visibility',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    subtitle: Text(
                      _noteVisibility ? 'Public' : 'Private',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    value: _noteVisibility,
                    onChanged: (bool value) {
                      setState(() {
                        _noteVisibility = value;
                      });
                    },
                    secondary: Icon(
                      _noteVisibility ? Icons.visibility : Icons.visibility_off,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    activeThumbColor: colorScheme.primary,
                    tileColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // --- NEW: Add extra space at the bottom ---
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
