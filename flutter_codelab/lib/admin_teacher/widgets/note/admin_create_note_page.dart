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
        _attachments.add(
          UploadedAttachment(localFile: file, isUploading: true),
        );
      }
    });

    // 3. Upload Loop
    for (int i = 0; i < _attachments.length; i++) {
      if (_attachments[i].isUploading && _attachments[i].serverFileId == null) {
        // Call API
        Map<String, dynamic>? result = await _fileApi.uploadSingleAttachment(
          _attachments[i].localFile,
          folderName: _noteTitleController.text, // Pass title as folder
        );

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
            widget.showSnackBar(
              context,
              'Failed to upload ${_attachments[i].localFile.name}',
              Colors.red,
            );
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

  Future<void> _insertCodeBlock(UploadedAttachment item) async {
    final file = item.localFile;
    String? content;

    try {
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
    } catch (e) {
      widget.showSnackBar(context, 'Failed to read file: $e', Colors.red);
      return;
    }

    if (content != null) {
      final ext = file.extension?.toLowerCase() ?? '';
      final codeBlock = '\n```$ext\n$content\n```\n';

      final text = _noteMarkdownController.text;
      final selection = _noteMarkdownController.selection;
      String newString;
      int newCursorPos;

      if (selection.isValid && selection.start >= 0) {
        newString = text.replaceRange(
          selection.start,
          selection.end,
          codeBlock,
        );
        newCursorPos = selection.start + codeBlock.length;
      } else {
        newString = text + codeBlock;
        newCursorPos = newString.length;
      }

      _noteMarkdownController.value = TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );

      widget.showSnackBar(context, 'Code inserted!', Colors.green);
      setState(() {});
    }
  }

  // --- IMPORT MARKDOWN LOGIC ---
  Future<void> _handleImportMarkdown() async {
    // 1. Pick MD or TXT File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;
    if (pickedFile.path == null) return;

    setState(() => _isLoading = true);
    widget.showSnackBar(context, 'Importing note...', Colors.blue);

    try {
      final file = File(pickedFile.path!);
      final content = await file.readAsString();
      final baseDir = file.parent.path;

      // 2. Set Title (Filename without extension)
      final title = pickedFile.name.replaceAll(
        RegExp(r'\.(md|txt)$', caseSensitive: false),
        '',
      );
      _noteTitleController.text = title;

      // 3. Parse Attachments
      // Robust Regex to match ![alt](path) handling one level of nested parentheses
      // e.g. matches "image (1).png" inside ![alt](image (1).png)
      // Dart's RegExp engine (standard JS-like) supports non-capturing groups
      final imageRegex = RegExp(r'!\[(.*?)\]\(((?:[^()]|\([^()]*\))+)\)');

      String updatedContent = content;
      final matches = imageRegex.allMatches(content);

      // Find all UNIQUE paths first
      Set<String> uniquePaths = {};
      for (final match in matches) {
        final path = match.group(2);
        if (path != null && !path.trim().startsWith('http')) {
          uniquePaths.add(path);
        }
      }

      int uploadedCount = 0;

      for (String relativePath in uniquePaths) {
        // Clean the path: strip quotes, whitespace
        String cleanPath = relativePath.trim();
        if ((cleanPath.startsWith('"') && cleanPath.endsWith('"')) ||
            (cleanPath.startsWith("'") && cleanPath.endsWith("'"))) {
          cleanPath = cleanPath.substring(1, cleanPath.length - 1);
        }

        // Possible candidates for the local file
        List<String> candidates = [];

        // 1. Exact relative path (decoded)
        String decoded = Uri.decodeFull(cleanPath);
        candidates.add(decoded);

        // 2. Windows-style path (backslashes)
        if (Platform.isWindows) {
          candidates.add(decoded.replaceAll('/', '\\'));
        }

        // 3. Just the filename (Flat import)
        String filename = decoded.split('/').last.split('\\').last;
        candidates.add(filename);

        File? localFile;

        // Try finding the file
        for (final candidate in candidates) {
          final attemptPath = '$baseDir${Platform.pathSeparator}$candidate';
          final f = File(attemptPath);
          if (await f.exists()) {
            localFile = f;
            break;
          }
        }

        if (localFile == null) {
          // 4. Recursive Fallback (Aggressive Search)
          // If we still haven't found it, search the entire base directory for the filename.
          try {
            final parentDir = Directory(baseDir);
            if (await parentDir.exists()) {
              await for (var entity in parentDir.list(
                recursive: true,
                followLinks: false,
              )) {
                if (entity is File) {
                  String name = entity.path.split(Platform.pathSeparator).last;
                  if (name.toLowerCase() == filename.toLowerCase()) {
                    localFile = entity;
                    debugPrint("Found recursively: ${entity.path}");
                    break;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Recursive search error: $e");
          }
        }

        if (localFile != null) {
          // Upload it
          // Create PlatformFile for the API
          final pFile = PlatformFile(
            name: localFile.path.split(Platform.pathSeparator).last,
            path: localFile.path,
            size: await localFile.length(),
          );

          // Trigger Upload
          Map<String, dynamic>? res = await _fileApi.uploadSingleAttachment(
            pFile,
          );

          if (res != null && res['url'] != null) {
            final serverUrl = res['url'];
            final serverId = res['id'];

            // Replace in Markdown
            // We use replaceAll to replace ALL occurrences of this specific relative path
            // This is safe enough for "image.png" -> "http://.../uuid.png"
            updatedContent = updatedContent.replaceAll(relativePath, serverUrl);

            // Add to attachments list for UI
            setState(() {
              _attachments.add(
                UploadedAttachment(
                  localFile: pFile,
                  serverFileId: serverId,
                  publicUrl: serverUrl,
                  isUploading: false,
                ),
              );
            });
            uploadedCount++;
          }
        } else {
          debugPrint(
            "Skipping: Could not find local file for '$cleanPath' in '$baseDir'",
          );
        }
      }

      // 4. Update Content
      _noteMarkdownController.text = updatedContent;

      widget.showSnackBar(
        context,
        'Imported "$title" with $uploadedCount images.',
        Colors.green,
      );
    } catch (e) {
      debugPrint("Import Error: $e");
      widget.showSnackBar(context, 'Import failed: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- SUBMIT FORM LOGIC ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Block submit if files are still uploading
    if (_attachments.any((a) => a.isUploading)) {
      widget.showSnackBar(
        context,
        'Please wait for files to finish uploading.',
        Colors.orange,
      );
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
          context,
          'Note created successfully!',
          Colors.green,
        );
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
        title: Text(
          'New Note',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),

        actions: [
          IconButton(
            icon: Icon(Icons.file_upload, color: colorScheme.primary),
            tooltip: 'Import Markdown(.txt, .md)',
            onPressed: _isLoading ? null : _handleImportMarkdown,
          ),
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(Icons.check, color: colorScheme.primary),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
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
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
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
                    attachments: _attachments,
                    onRemove: _removeFile,
                    onInsertLink: (item) {
                      final isImage = [
                        'jpg',
                        'jpeg',
                        'png',
                        'webp',
                        'bmp',
                        'gif',
                      ].contains(item.localFile.extension?.toLowerCase());
                      if (item.publicUrl != null) {
                        _insertMarkdownLink(
                          item.localFile.name,
                          item.publicUrl!,
                          isImage,
                        );
                        widget.showSnackBar(
                          context,
                          'Link inserted!',
                          Colors.green,
                        );
                      }
                    },
                    onInsertCode: _insertCodeBlock,
                  ),
                  const SizedBox(height: 16),

                  // 4. Attachments Preview (Moved to FileUploadZone)
                  // _buildUploadedFilePreview(colorScheme), -- Removed

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
                      Text(
                        'Live Preview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                                'font-weight': 'bold',
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
                    onChanged: (bool value) =>
                        setState(() => _noteVisibility = value),
                    secondary: Icon(
                      _noteVisibility ? Icons.visibility : Icons.visibility_off,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    activeColor: colorScheme.primary,
                    // Use surfaceContainer for the tile background
                    tileColor: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
