import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/file_helper.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/file_picker.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/file_upload_zone.dart';

import 'package:flutter_codelab/models/note_data.dart';

import 'package:flutter_codelab/api/file_api.dart';


// --- NEW IMPORTS FOR HTML RENDERING ---
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// --- Helper Class to Track Upload State ---
class UploadedAttachment {
  final PlatformFile localFile;
  final String? serverFileId;
  final String? publicUrl; // Stores URL for inserting into Markdown
  final bool isUploading;
  final bool isFailed;

  UploadedAttachment({
    required this.localFile,
    this.serverFileId,
    this.publicUrl,
    this.isUploading = false,
    this.isFailed = false,
  });
}

void showCreateNotesDialog({
  required BuildContext context,
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

  const CreateNotePage({super.key, required this.showSnackBar});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final _formKey = GlobalKey<FormState>();
  final FileApi _fileApi = FileApi();

  // Controllers
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteMarkdownController = TextEditingController();

  // State
  String? _selectedTopic;
  bool _noteVisibility = true;
  bool _isLoading = false;
  List<UploadedAttachment> _attachments = [];

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

  // --- HELPER: Insert Markdown Text at Cursor Position ---
  void _insertMarkdownLink(String fileName, String url, bool isImage) {
    final text = _noteMarkdownController.text;
    final selection = _noteMarkdownController.selection;

    // Construct the markdown string
    // Image: ![name](url)
    // File:  [name](url)
    final prefix = isImage ? '!' : '';
    final newText = '\n$prefix[$fileName]($url)\n';

    String newString;
    int newCursorPos;

    if (selection.isValid && selection.start >= 0) {
      // Insert at current cursor position
      final start = selection.start;
      final end = selection.end;
      newString = text.replaceRange(start, end, newText);
      newCursorPos = start + newText.length;
    } else {
      // Append to end if no cursor focus
      newString = text + newText;
      newCursorPos = newString.length;
    }

    _noteMarkdownController.value = TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    // Trigger preview update
    setState(() {});
  }

  // --- UPLOAD LOGIC ---
  Future<void> _handleFileUpload() async {
    // 1. Pick Files
    List<PlatformFile> pickedFiles = await pickAndUploadFiles();

    if (pickedFiles.isEmpty) return;

    // 2. Add to UI immediately
    setState(() {
      for (var file in pickedFiles) {
        print('Uploaded note path: ${file.path}');
        _attachments
            .add(UploadedAttachment(localFile: file, isUploading: true));
      }
    });

    // 3. Upload Loop
    for (int i = 0; i < _attachments.length; i++) {
      if (_attachments[i].isUploading && _attachments[i].serverFileId == null) {
        // Call API
        Map<String, dynamic>? result =
            await _fileApi.uploadSingleAttachment(_attachments[i].localFile);

        if (!mounted) return;

        setState(() {
          if (result != null) {
            // Success: Update with ID and URL
            _attachments[i] = UploadedAttachment(
              localFile: _attachments[i].localFile,
              serverFileId: result['id'],
              publicUrl: result['url'],
              isUploading: false,
            );
          } else {
            // Failure
            _attachments[i] = UploadedAttachment(
              localFile: _attachments[i].localFile,
              isUploading: false,
              isFailed: true,
            );
            widget.showSnackBar(context,
                'Failed to upload ${_attachments[i].localFile.name}', Colors.red);
          }
        });
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  // --- SUBMIT FORM LOGIC ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Block submit if files are still uploading
    if (_attachments.any((a) => a.isUploading)) {
      widget.showSnackBar(
          context, 'Please wait for files to finish uploading.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final fileContent = _noteMarkdownController.text;
    final String fileName =
        '${_noteTitleController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.md';

    FileHelper output = FileHelper(fileName: fileName, folderName: 'notes');

    try {
      // 1. Create Markdown File Locally
      final File markdownFile = await output.writeStringToFile(
        content: fileContent,
        fileName: fileName,
      );
      print('Uploaded note path: ${markdownFile.path}');

      // 2. Collect IDs of successfully uploaded files
      List<String> attachmentIds = _attachments
          .where((a) => a.serverFileId != null)
          .map((a) => a.serverFileId!)
          .toList();

      // 3. Send Data to Backend
      bool success = await _fileApi.createNoteWithLinkedFiles(
        title: _noteTitleController.text,
        visibility: _noteVisibility,
        topic: _selectedTopic!,
        markdownFile: markdownFile,
        attachmentIds: attachmentIds,
      );

      if (success && mounted) {
        widget.showSnackBar(
            context, 'Note created successfully!', Colors.green);
        Navigator.of(context).pop();
      } else if (mounted) {
        widget.showSnackBar(context, 'Failed to create note.', Colors.red);
      }
    } catch (e) {
      if (mounted) widget.showSnackBar(context, 'Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET BUILDERS ---

  Widget _buildUploadedFilePreview(ColorScheme colorScheme) {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Files (${_attachments.length})',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attachments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _attachments[index];
            final file = item.localFile;
            final isImage = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif']
                .contains(file.extension?.toLowerCase());

            return Container(
              decoration: BoxDecoration(
                // Use surfaceContainer for cards/list items in M3
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: item.isFailed
                        ? colorScheme.error
                        : colorScheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: isImage && file.path != null
                      ? Image.file(File(file.path!), fit: BoxFit.cover)
                      : Icon(Icons.insert_drive_file,
                          color: colorScheme.primary),
                ),
                title: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                ),
                subtitle: item.isUploading
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: colorScheme.surfaceVariant,
                          color: colorScheme.primary,
                        ),
                      )
                    : item.isFailed
                        ? Text('Upload Failed',
                            style: TextStyle(
                                color: colorScheme.error, fontSize: 12))
                        : SelectableText(
                            item.publicUrl ?? 'Ready to insert',
                            style: TextStyle(
                                color: colorScheme.primary, fontSize: 12),
                            maxLines: 1,
                          ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!item.isUploading &&
                        !item.isFailed &&
                        item.publicUrl != null)
                      IconButton(
                        icon: const Icon(Icons.add_link),
                        color: colorScheme.primary,
                        tooltip: 'Insert into text',
                        onPressed: () {
                          _insertMarkdownLink(
                              file.name, item.publicUrl!, isImage);
                          widget.showSnackBar(
                              context, 'Link inserted!', Colors.green);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: colorScheme.error,
                      tooltip: 'Remove file',
                      onPressed: () => _removeFile(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
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
      // Use surfaceContainerHighest for input fields (standard M3)
      fillColor: colorScheme.surfaceContainerHighest,
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Let the theme handle the background color (light vs dark)
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('New Note',
            style: TextStyle(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Topic Selector
                  DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    // Remove hardcoded color, let it use theme canvas/surface
                    dropdownColor: colorScheme.surfaceContainer,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Topic',
                      icon: Icons.category,
                      colorScheme: colorScheme,
                    ),
                    items: _topic
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTopic = value),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please select a topic'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Title Field
                  TextFormField(
                    controller: _noteTitleController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Note Title',
                      hintText: 'Enter a title',
                      icon: Icons.title,
                      colorScheme: colorScheme,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. File Upload Zone
                  FileUploadZone(
                    onTap: _handleFileUpload,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // 4. Attachments Preview
                  _buildUploadedFilePreview(colorScheme),

                  // 5. Markdown Editor
                  TextFormField(
                    controller: _noteMarkdownController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: _inputDecoration(
                      labelText: 'Markdown Notes',
                      hintText:
                          'Type notes or HTML here. Images insert automatically.',
                      icon: Icons.description,
                      colorScheme: colorScheme,
                    ),
                    maxLines: 8,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter content'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // --- 6. LIVE PREVIEW (HTML + Markdown) ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Preview',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),

                      // Preview Box
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 100),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          // Use surfaceContainer for distinction against the main background
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: HtmlWidget(
                          md.markdownToHtml(_noteMarkdownController.text),
                          textStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                          customStylesBuilder: (element) {
                            if (element.localName == 'h1') {
                              return {
                                'margin-bottom': '10px',
                                'font-weight': 'bold'
                              };
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 7. Visibility Switch
                  SwitchListTile(
                    title: Text('Visibility',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    subtitle: Text(_noteVisibility ? 'Public' : 'Private',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant
                                .withOpacity(0.6))),
                    value: _noteVisibility,
                    onChanged: (bool value) =>
                        setState(() => _noteVisibility = value),
                    secondary: Icon(
                        _noteVisibility
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onSurfaceVariant),
                    activeColor: colorScheme.primary,
                    // Use surfaceContainer for the tile background
                    tileColor: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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