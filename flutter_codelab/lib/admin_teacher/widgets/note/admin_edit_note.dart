import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/file_picker.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/file_upload_zone.dart';
import 'package:flutter_codelab/api/note_api.dart';
import 'package:flutter_codelab/api/file_api.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter_codelab/admin_teacher/services/breadcrumb_navigation.dart';
import 'run_code_page.dart';
import 'quiz_widget.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/search_note.dart';
import 'package:flutter_codelab/theme.dart';
import 'package:flutter_codelab/utils/brand_color_extension.dart';

class EditNotePage extends StatefulWidget {
  final String noteId;
  final String currentTitle;
  final String currentContent;
  final String currentTopic;
  final bool currentVisibility;
  final int? initialCursorIndex;

  const EditNotePage({
    super.key,
    required this.noteId,
    required this.currentTitle,
    required this.currentContent,
    required this.currentTopic,
    required this.currentVisibility,
    this.initialCursorIndex,
  });

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final _formKey = GlobalKey<FormState>();
  final NoteApi _noteApi = NoteApi();
  final FileApi _fileApi = FileApi();

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late String? _selectedTopic;
  late bool _noteVisibility;
  final List<String> _topics = ['HTML', 'CSS', 'JS', 'PHP'];

  bool _isLoading = false;
  List<UploadedAttachment> _attachments = [];

  // --- Search State ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _pageFocusNode = FocusNode();

  String _searchTerm = '';
  int _currentMatchIndex = 0;
  int _totalMatches = 0;
  bool _isHoveringInput = false;
  final ScrollController _inputScrollController = ScrollController();
  List<GlobalKey> _matchKeys = [];
  Timer? _quizHoverTimer;
  bool _showQuizPopup = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _contentController = TextEditingController(text: widget.currentContent);

    _contentController.addListener(_onContentChanged);
    _searchController.addListener(_onSearchChanged);
    _inputScrollController.addListener(() {
      if (mounted) setState(() {});
    });

    _selectedTopic = widget.currentTopic;
    _noteVisibility = widget.currentVisibility;

    // Ensure the current topic is in the list to avoid Dropdown assertion error
    if (!_topics.contains(_selectedTopic)) {
      _topics.add(_selectedTopic!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCursorIndex != null) {
        int idx = widget.initialCursorIndex!;
        if (idx < 0) idx = 0;
        if (idx > _contentController.text.length)
          idx = _contentController.text.length;
        _contentController.selection = TextSelection.collapsed(offset: idx);
      }
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    _inputScrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();

    _pageFocusNode.dispose();
    _quizHoverTimer?.cancel();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {});
  }

  InputDecoration _inputDecoration({
    required String labelText,
    IconData? icon,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: colorScheme.onSurfaceVariant)
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      fillColor: colorScheme.surfaceContainerHighest,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      isDense: true,
    );
  }

  // Helper to ensure absolute URLs
  String _processMarkdown(String content) {
    // Replace relative paths starting with /storage/
    // Example: ](/storage/...) -> ](https://domain.com/storage/...)
    // Also handle existing partials if any
    final domain = ApiConstants.domain;
    return content.replaceAll('](/storage/', ']($domain/storage/');
  }

  void _insertMarkdownLink(String fileName, String url, bool isImage) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final prefix = isImage ? '!' : '';
    final newText = '\n$prefix[$fileName]($url)\n';

    String newString;
    int newCursorPos;

    if (selection.isValid && selection.start >= 0) {
      newString = text.replaceRange(selection.start, selection.end, newText);
      newCursorPos = selection.start + newText.length;
    } else {
      newString = text + newText;
      newCursorPos = newString.length;
    }

    _contentController.value = TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link inserted!'),
        duration: Duration(seconds: 1),
      ),
    );

    setState(() {});
  }

  Future<void> _handleFileUpload() async {
    List<PlatformFile> pickedFiles = await pickAndUploadFiles();
    if (pickedFiles.isEmpty) return;

    setState(() {
      for (var file in pickedFiles) {
        _attachments.add(
          UploadedAttachment(localFile: file, isUploading: true),
        );
      }
    });

    for (int i = 0; i < _attachments.length; i++) {
      if (_attachments[i].isUploading && _attachments[i].serverFileId == null) {
        Map<String, dynamic>? result = await _fileApi.uploadSingleAttachment(
          _attachments[i].localFile,
          folderName: _titleController.text, // Pass title as folder
        );

        if (!mounted) return;

        setState(() {
          if (result != null) {
            _attachments[i] = UploadedAttachment(
              localFile: _attachments[i].localFile,
              serverFileId: result['id'],
              publicUrl: result['url'],
              isUploading: false,
            );
          } else {
            _attachments[i] = UploadedAttachment(
              localFile: _attachments[i].localFile,
              isUploading: false,
              isFailed: true,
            );
          }
        });
      }
    }
  }

  Future<void> _insertCodeBlock(UploadedAttachment item) async {
    final file = item.localFile;
    String? content;

    try {
      if (file.path != null) {
        content = await File(file.path!).readAsString();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read file: $e')));
      return;
    }

    if (content != null) {
      final ext = file.extension?.toLowerCase() ?? '';
      // Only insert if it's not empty, or even if empty if user wants structure
      final codeBlock = '\n```$ext\n$content\n```\n';

      final text = _contentController.text;
      final selection = _contentController.selection;
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

      _contentController.value = TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code block inserted!'),
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {});
    }
  }

  // --- QUIZ INSERTION LOGIC ---
  Future<void> _insertQuiz() async {
    String question = '';
    List<String> options = ['', '']; // Start with 2 options
    int correctIndex = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Insert Quiz'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Question'),
                      onChanged: (value) => question = value,
                    ),
                    const SizedBox(height: 10),
                    const Text('Options:'),
                    ...options.asMap().entries.map((entry) {
                      int idx = entry.key;
                      return Row(
                        children: [
                          Radio<int>(
                            value: idx,
                            groupValue: correctIndex,
                            onChanged: (val) {
                              setStateDialog(() => correctIndex = val!);
                            },
                          ),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Option ${idx + 1}',
                              ),
                              controller:
                                  TextEditingController(text: options[idx])
                                    ..selection = TextSelection.collapsed(
                                      offset: options[idx].length,
                                    ),
                              onChanged: (val) => options[idx] = val,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: options.length > 2
                                ? () {
                                    setStateDialog(() {
                                      options.removeAt(idx);
                                      if (correctIndex >= options.length) {
                                        correctIndex = options.length - 1;
                                      }
                                    });
                                  }
                                : null,
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                      onPressed: () {
                        setStateDialog(() {
                          options.add('');
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Validation
                    if (question.isEmpty || options.any((o) => o.isEmpty)) {
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Insert'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result == true) {
        final quizData = {
          'question': question,
          'options': options,
          'correctIndex': correctIndex,
        };
        final jsonStr = const JsonEncoder.withIndent('  ').convert(quizData);
        final codeBlock = '\n```quiz\n$jsonStr\n```\n';

        final text = _contentController.text;
        final selection = _contentController.selection;
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

        _contentController.value = TextEditingValue(
          text: newString,
          selection: TextSelection.collapsed(offset: newCursorPos),
        );
        setState(() {});
      }
    });
  }

  void _removeFile(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  bool _allowExit = false;

  bool get _hasUnsavedChanges {
    return _titleController.text != widget.currentTitle ||
        _contentController.text != widget.currentContent ||
        _selectedTopic != widget.currentTopic ||
        _noteVisibility != widget.currentVisibility;
  }

  Future<void> _showUnsavedChangesDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Do you want to save them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result == 'discard') {
      setState(() => _allowExit = true);
      Navigator.pop(context);
    } else if (result == 'save') {
      await _saveChanges();
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_attachments.any((a) => a.isUploading)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wait for uploads...')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await _noteApi.updateNote(
      widget.noteId,
      _titleController.text,
      _contentController.text,
      _selectedTopic!,
      _noteVisibility,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        setState(() => _allowExit = true);
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openRunPage(String code) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunCodePage(
          initialCode: code,
          contextId: widget.currentTitle,
          topic: _selectedTopic ?? widget.currentTopic,
          noteTitle: _titleController.text,
          isAdmin: true,
        ),
      ),
    );
  }

  // --- Search Logic ---
  void _onSearchChanged() {
    final term = _searchController.text.trim();
    int newTotal = 0;
    if (term.isNotEmpty) {
      String htmlContent = md.markdownToHtml(
        _processMarkdown(_contentController.text),
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );
      final pattern = RegExp(
        '(${RegExp.escape(term)})(?![^<]*>)',
        caseSensitive: false,
        multiLine: true,
      );
      newTotal = pattern.allMatches(htmlContent).length;
    }

    setState(() {
      _searchTerm = term;
      _totalMatches = newTotal;
      _currentMatchIndex = 0;
    });

    if (newTotal > 0) {
      _scrollToMatch(0);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _searchTerm = '';
        _pageFocusNode.requestFocus();
      }
    });
  }

  void _scrollToMatch(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index < _matchKeys.length &&
          _matchKeys[index].currentContext != null) {
        Scrollable.ensureVisible(
          _matchKeys[index].currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _nextMatch() {
    if (_totalMatches > 0) {
      setState(() {
        _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatches;
      });
      _scrollToMatch(_currentMatchIndex);
    }
  }

  void _prevMatch() {
    if (_totalMatches > 0) {
      setState(() {
        _currentMatchIndex =
            (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
      });
      _scrollToMatch(_currentMatchIndex);
    }
  }

  Widget _buildHighlightedHtml(ColorScheme colorScheme) {
    _matchKeys = [];

    String htmlContent = md.markdownToHtml(
      _processMarkdown(_contentController.text),
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    final String activeBg =
        '#${colorScheme.primary.value.toRadixString(16).substring(2)}';
    final String activeText =
        '#${colorScheme.onPrimary.value.toRadixString(16).substring(2)}';
    final String inactiveBg =
        '#${colorScheme.primaryContainer.value.toRadixString(16).substring(2)}';
    final String inactiveText =
        '#${colorScheme.onPrimaryContainer.value.toRadixString(16).substring(2)}';

    if (_searchTerm.isNotEmpty) {
      try {
        final pattern = RegExp(
          '(${RegExp.escape(_searchTerm)})(?![^<]*>)',
          caseSensitive: false,
          multiLine: true,
        );
        int matchCounter = 0;
        htmlContent = htmlContent.replaceAllMapped(pattern, (match) {
          final bool isActive = matchCounter == _currentMatchIndex;
          final String bg = isActive ? activeBg : inactiveBg;
          final String txt = isActive ? activeText : inactiveText;
          final String replacement =
              '<span data-scroll-index="$matchCounter"></span><span style="background-color: $bg; color: $txt;">${match.group(1)}</span>';
          matchCounter++;
          return replacement;
        });
      } catch (e) {
        debugPrint("Regex error: $e");
      }
    }

    return HtmlWidget(
      htmlContent,
      baseUrl: Uri.parse(ApiConstants.domain),
      textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 15),
      customWidgetBuilder: (element) {
        if (element.localName == 'pre') {
          if (element.children.isNotEmpty &&
              element.children.first.localName == 'code') {
            final codeClass = element.children.first.attributes['class'] ?? '';

            // 1. Check for Quiz
            if (codeClass.contains('language-quiz')) {
              final jsonStr = element.text;
              try {
                final quizData = jsonDecode(jsonStr);
                return QuizWidget(
                  question: quizData['question'],
                  options: List<String>.from(quizData['options']),
                  correctIndex: quizData['correctIndex'],
                );
              } catch (e) {
                return Text(
                  'Error parsing quiz: $e',
                  style: const TextStyle(color: Colors.red),
                );
              }
            }
          }
          final codeText = element.text;
          // Use innerHtml to preserve highlighting spans, wrapped in pre to preserve whitespace
          final htmlContent =
              '<pre style="margin: 0; padding: 0;">${element.innerHtml}</pre>';

          return Stack(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // Use HtmlWidget again to render the code with highlights
                  child: HtmlWidget(
                    htmlContent,
                    textStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    // Recursively handle scroll indices inside the code block
                    customWidgetBuilder: (innerElement) {
                      if (innerElement.attributes.containsKey(
                        'data-scroll-index',
                      )) {
                        final GlobalKey key = GlobalKey();
                        _matchKeys.add(key);
                        return SizedBox(width: 1, height: 1, key: key);
                      }
                      return null;
                    },
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _openRunPage(codeText),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          size: 12,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Run',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        if (element.attributes.containsKey('data-scroll-index')) {
          final GlobalKey key = GlobalKey();
          _matchKeys.add(key);
          return SizedBox(width: 1, height: 1, key: key);
        }
        return null;
      },
      customStylesBuilder: (element) {
        if (element.localName == 'h1')
          return {
            'margin-bottom': '10px',
            'font-weight': 'bold',
            'border-bottom':
                '1px solid ${colorScheme.outlineVariant.value.toRadixString(16).substring(2)}',
          };
        if (element.localName == 'table')
          return {'border-collapse': 'collapse', 'width': '100%'};
        if (element.localName == 'th' || element.localName == 'td')
          return {
            'border':
                '1px solid ${colorScheme.outlineVariant.value.toRadixString(16).substring(2)}',
            'padding': '8px',
          };
        return null;
      },
    );
  }

  // --- Dynamic Popup Positioning ---
  double _getCursorVerticalPosition() {
    final selection = _contentController.selection;
    final text = _contentController.text;

    // Default to top padding if no selection or text
    double position = 16.0;

    if (selection.baseOffset >= 0 && text.isNotEmpty) {
      // Safety check for index out of bounds
      int offset = selection.baseOffset;
      if (offset > text.length) offset = text.length;

      final textBeforeCursor = text.substring(0, offset);
      final lineCount = textBeforeCursor.split('\n').length;
      final lineHeight = 15.0 * 1.5; // fontSize * height

      position = 16.0 + (lineCount - 1) * lineHeight;
    }

    // Adjust for scroll offset
    if (_inputScrollController.hasClients) {
      position -= _inputScrollController.offset;
    }

    // Clamp to ensure it doesn't go too far up/down if wanted,
    // but allowing negative values hides it correctly if scrolled out.
    return position;
  }

  Widget _buildHoverFileInserter(ColorScheme colorScheme) {
    final uniqueFiles = _attachments
        .where((a) => !a.isFailed && a.publicUrl != null)
        .toList();

    if (uniqueFiles.isEmpty) return const SizedBox.shrink();

    final brandColors = Theme.of(context).extension<BrandColors>();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Insert File',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemCount: uniqueFiles.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = uniqueFiles[index];
                final file = item.localFile;
                final ext = file.extension?.toLowerCase() ?? '';

                final isImage = [
                  'jpg',
                  'jpeg',
                  'png',
                  'webp',
                  'bmp',
                  'gif',
                ].contains(ext);
                final isCode = ['html', 'css', 'js', 'php'].contains(ext);

                IconData iconData = Icons.insert_drive_file;
                Color iconColor = colorScheme.primary;

                if (isImage) {
                  iconData = Icons.image;
                } else if (isCode) {
                  iconData = Icons.code;
                  if (brandColors != null) {
                    if (ext == 'html')
                      iconColor = brandColors.html;
                    else if (ext == 'css')
                      iconColor = brandColors.css;
                    else if (ext == 'js')
                      iconColor = brandColors.javascript;
                    else if (ext == 'php')
                      iconColor = brandColors.php;
                  }
                } else {
                  if (brandColors != null) iconColor = brandColors.other;
                }

                return InkWell(
                  onTap: () {
                    // Logic: Code files -> Code Block ONLY. Others -> Link.
                    if (isCode) {
                      _insertCodeBlock(item);
                    } else {
                      _insertMarkdownLink(file.name, item.publicUrl!, isImage);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(iconData, size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isCode ? Icons.data_object : Icons.add_link,
                          size: 16,
                          color: isCode ? iconColor : colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoverQuizPopup(ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: _insertQuiz,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Insert Quiz',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: _allowExit || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showUnsavedChangesDialog();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              _toggleSearch,
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
              _toggleSearch,
        },
        child: Focus(
          focusNode: _pageFocusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: BreadcrumbNavigation(
                items: [
                  BreadcrumbItem(label: 'Note'),
                  BreadcrumbItem(label: _selectedTopic ?? widget.currentTopic),
                  BreadcrumbItem(
                    label: _titleController.text,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  BreadcrumbItem(label: 'Edit'),
                ],
              ),
              backgroundColor: context
                  .getBrandColorForTopic(_selectedTopic ?? widget.currentTopic)
                  .withOpacity(0.2),
              elevation: 0,
              iconTheme: IconThemeData(color: colorScheme.onSurface),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  tooltip: _isSearching ? 'Close Search' : 'Search (Ctrl+F)',
                  onPressed: _toggleSearch,
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
                  onPressed: _isLoading ? null : _saveChanges,
                ),
              ],
            ),
            body: Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child:
                                              DropdownButtonFormField<String>(
                                                value: _selectedTopic,
                                                dropdownColor: colorScheme
                                                    .surfaceContainer,
                                                style: TextStyle(
                                                  color: colorScheme.onSurface,
                                                ),
                                                decoration: _inputDecoration(
                                                  labelText: 'Topic',
                                                  icon: Icons.category,
                                                  colorScheme: colorScheme,
                                                ),
                                                items: _topics
                                                    .map(
                                                      (value) =>
                                                          DropdownMenuItem(
                                                            value: value,
                                                            child: Text(value),
                                                          ),
                                                    )
                                                    .toList(),
                                                onChanged: (value) => setState(
                                                  () => _selectedTopic = value,
                                                ),
                                                validator: (value) =>
                                                    value == null ||
                                                        value.isEmpty
                                                    ? 'Required'
                                                    : null,
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    colorScheme.outlineVariant,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Visibility',
                                                      style: TextStyle(
                                                        color: colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                    Text(
                                                      _noteVisibility
                                                          ? 'Public'
                                                          : 'Private',
                                                      style: TextStyle(
                                                        color: colorScheme
                                                            .onSurface,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Transform.scale(
                                                  scale: 0.8,
                                                  child: Switch(
                                                    value: _noteVisibility,
                                                    onChanged: (bool value) =>
                                                        setState(
                                                          () =>
                                                              _noteVisibility =
                                                                  value,
                                                        ),
                                                    activeColor:
                                                        colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _titleController,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: _inputDecoration(
                                        labelText: 'Title',
                                        icon: Icons.title,
                                        colorScheme: colorScheme,
                                      ),
                                      validator: (v) =>
                                          v!.isEmpty ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    FileUploadZone(
                                      onTap: _handleFileUpload,
                                      isLoading: _isLoading,
                                      attachments: _attachments,
                                      onRemove: _removeFile,
                                      onInsertLink: (item) {
                                        final isImage =
                                            [
                                              'jpg',
                                              'jpeg',
                                              'png',
                                              'webp',
                                              'bmp',
                                              'gif',
                                            ].contains(
                                              item.localFile.extension
                                                  ?.toLowerCase(),
                                            );
                                        if (item.publicUrl != null) {
                                          _insertMarkdownLink(
                                            item.localFile.name,
                                            item.publicUrl!,
                                            isImage,
                                          );
                                        }
                                      },
                                      onInsertCode: _insertCodeBlock,
                                    ),
                                    const SizedBox(height: 16),

                                    // Quiz Button
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: _insertQuiz,
                                        icon: Icon(
                                          Icons.quiz,
                                          color: colorScheme.primary,
                                        ),
                                        label: Text(
                                          'Insert Quiz',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              colorScheme.surfaceContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // _buildAttachmentList was here, now integrated into FileUploadZone
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ];
                      },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    'Markdown Input',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: MouseRegion(
                                    onEnter: (_) {
                                      setState(() => _isHoveringInput = true);
                                      _quizHoverTimer = Timer(
                                        const Duration(seconds: 2),
                                        () {
                                          if (mounted && _isHoveringInput) {
                                            setState(
                                              () => _showQuizPopup = true,
                                            );
                                          }
                                        },
                                      );
                                    },
                                    onExit: (_) {
                                      _quizHoverTimer?.cancel();
                                      setState(() {
                                        _isHoveringInput = false;
                                        _showQuizPopup = false;
                                      });
                                    },
                                    child: Stack(
                                      children: [
                                        TextFormField(
                                          controller: _contentController,
                                          scrollController:
                                              _inputScrollController,
                                          style: TextStyle(
                                            color: colorScheme.onSurface,
                                            fontSize: 15,
                                            fontFamily: 'monospace',
                                            height: 1.5,
                                          ),
                                          maxLines: null,
                                          minLines: null,
                                          expands: true,
                                          textAlignVertical:
                                              TextAlignVertical.top,
                                          keyboardType: TextInputType.multiline,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(16),
                                          ),
                                          validator: (v) =>
                                              v!.isEmpty ? 'Required' : null,
                                        ),
                                        if (_attachments.isNotEmpty &&
                                            _isHoveringInput)
                                          Positioned(
                                            top: _getCursorVerticalPosition(),
                                            right: 16,
                                            child: _buildHoverFileInserter(
                                              colorScheme,
                                            ),
                                          ),
                                        if (_showQuizPopup)
                                          Positioned(
                                            top: _getCursorVerticalPosition(),
                                            left: 16,
                                            child: _buildHoverQuizPopup(
                                              colorScheme,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    'Live Preview',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    ),
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: _buildHighlightedHtml(
                                          colorScheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSearching)
                  Positioned(
                    top: 16,
                    right: 16,
                    width: screenWidth > 350 ? 350 : screenWidth - 32,
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter):
                            _nextMatch,
                      },
                      child: SearchNote(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        matchCount: _currentMatchIndex,
                        totalMatches: _totalMatches,
                        onNext: _nextMatch,
                        onPrev: _prevMatch,
                        onClose: _toggleSearch,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
