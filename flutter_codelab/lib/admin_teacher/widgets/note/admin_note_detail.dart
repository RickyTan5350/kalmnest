import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Required for downloading images
import 'package:code_play/admin_teacher/widgets/note/admin_edit_note.dart';
import 'package:code_play/api/note_api.dart';
import 'package:code_play/admin_teacher/widgets/note/run_code_page.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'delete_note.dart';
import 'package:code_play/admin_teacher/widgets/note/search_note.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/utils/brand_color_extension.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'quiz_widget.dart';

class AdminNoteDetailPage extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  final bool isStudent;

  const AdminNoteDetailPage({
    super.key,
    required this.noteId,
    required this.noteTitle,
    required this.isStudent,
  });

  @override
  State<AdminNoteDetailPage> createState() => _AdminNoteDetailPageState();
}

class _AdminNoteDetailPageState extends State<AdminNoteDetailPage> {
  final NoteApi _noteApi = NoteApi();

  // State variables
  bool _isLoading = true; // Used for fetching note content
  bool _isDownloadingPdf = false; // Used for PDF generation status
  String _markdownContent = "";
  late String _currentTitle;
  String _currentTopic = "HTML";
  bool _currentVisibility = true;

  late TextEditingController _readOnlyController;

  // --- Search State ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _pageFocusNode = FocusNode();

  String _searchTerm = '';
  int _currentMatchIndex = 0;
  int _totalMatches = 0;
  List<GlobalKey> _matchKeys = [];

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.noteTitle;
    _readOnlyController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _fetchContent();
  }

  @override
  void dispose() {
    _readOnlyController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchContent() async {
    setState(() => _isLoading = true);
    try {
      final noteData = await _noteApi.getNote(widget.noteId);

      if (mounted) {
        setState(() {
          _markdownContent = noteData['content'] ?? '';
          _currentTitle = noteData['title'] ?? widget.noteTitle;
          _currentTopic = noteData['topic'] ?? 'HTML';

          final vis = noteData['visibility'];
          if (vis is int) {
            _currentVisibility = vis == 1;
          } else if (vis is bool) {
            _currentVisibility = vis;
          } else {
            _currentVisibility = true;
          }

          _readOnlyController.text = _markdownContent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _navigateToEdit({int? cursorIndex}) async {
    // Security Block
    if (widget.isStudent) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNotePage(
          noteId: widget.noteId,
          currentTitle: _currentTitle,
          currentContent: _markdownContent,
          currentTopic: _currentTopic,
          currentVisibility: _currentVisibility,
          initialCursorIndex: cursorIndex,
        ),
      ),
    );

    if (result == true) {
      _fetchContent();
    }
  }

  Future<void> _openRunPage(String code, {String? fileName}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunCodePage(
          initialCode: code,
          contextId: _currentTitle,
          initialFileName: fileName,
          topic: _currentTopic,
          noteTitle: _currentTitle,
          isAdmin: !widget.isStudent,
          onFileRenamed: _handleFileRename,
        ),
      ),
    );

    if (result == 'navigate_home') {
      if (mounted) Navigator.pop(context, 'navigate_home');
    } else if (result == 'navigate_topic') {
      if (mounted) Navigator.pop(context, _currentTopic);
    }
  }

  Future<void> _handleFileRename(String oldName, String newName) async {
    // 1. Update Markdown Content (Regex Replace)
    final regex = RegExp(
      ':src=${RegExp.escape(oldName)}\\b', // Match :src=oldName word boundary
    );

    if (_markdownContent.contains(regex)) {
      final newContent = _markdownContent.replaceAll(regex, ':src=$newName');

      setState(() {
        _markdownContent = newContent; // Update local state
        _readOnlyController.text = newContent; // Update UI source view
      });

      // 2. Persist to Backend
      final success = await _noteApi.updateNote(
        widget.noteId,
        _currentTitle, // Keep current title
        newContent, // New content
        _currentTopic, // Keep current topic
        _currentVisibility, // Keep visibility
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Renamed "$oldName" to "$newName" and updated Note links.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save renamed file link to Note.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      debugPrint(
        "Warning: Renamed '$oldName' but found no reference in Markdown to update.",
      );
    }
  }

  // ====================================================================
  // PDF GENERATION LOGIC (With Image Support)
  // ====================================================================

  // --- Search Logic ---
  void _onSearchChanged() {
    final term = _searchController.text.trim();
    int newTotal = 0;
    if (term.isNotEmpty) {
      String htmlContent = md.markdownToHtml(
        _markdownContent,
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

  Future<void> _downloadPdf() async {
    // Show a different loading indicator for PDF download
    setState(() => _isDownloadingPdf = true);

    try {
      final pdf = pw.Document();

      // 1. Parse Markdown and Download Images
      final List<pw.Widget> contentWidgets = await _buildPdfContent(
        _markdownContent,
      );

      // 2. Build the PDF Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _currentTitle,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 20),
                // Spread the widgets (Text + Images) into the column
                ...contentWidgets,
              ],
            );
          },
        ),
      );

      // 3. Save file
      final dir = await getApplicationDocumentsDirectory();
      // Sanitize filename
      final safeTitle = _currentTitle
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      final file = File('${dir.path}/$safeTitle.pdf');

      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  /// Helper to convert Markdown text with images into PDF widgets
  Future<List<pw.Widget>> _buildPdfContent(String content) async {
    List<pw.Widget> widgets = [];

    // Regex to match Markdown images: ![Alt Text](URL)
    final regex = RegExp(r'!\[(.*?)\]\((.*?)\)');

    int lastIndex = 0;

    // Loop through all matches
    for (final match in regex.allMatches(content)) {
      // 1. Text BEFORE the image
      if (match.start > lastIndex) {
        final textSegment = content.substring(lastIndex, match.start);
        if (textSegment.trim().isNotEmpty) {
          widgets.add(pw.Paragraph(text: textSegment));
          widgets.add(pw.SizedBox(height: 10));
        }
      }

      // 2. The Image itself
      final imageUrl = match.group(2); // Group 2 is the URL
      if (imageUrl != null) {
        try {
          // Download image bytes
          debugPrint("DEBUG PDF: Downloading image: $imageUrl");
          final response = await http.get(Uri.parse(imageUrl));
          debugPrint(
            "DEBUG PDF: Image download status: ${response.statusCode}",
          );
          if (response.statusCode == 200) {
            final imageBytes = response.bodyBytes;
            widgets.add(
              pw.Container(
                alignment: pw.Alignment.center,
                height: 200, // Constrain height to prevent page overflow issues
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
          } else {
            widgets.add(
              pw.Text(
                "[Image failed to load]",
                style: const pw.TextStyle(color: PdfColors.red),
              ),
            );
          }
        } catch (e) {
          widgets.add(
            pw.Text(
              "[Error loading image]",
              style: const pw.TextStyle(color: PdfColors.red),
            ),
          );
        }
      }

      lastIndex = match.end;
    }

    // 3. Text AFTER the last image
    if (lastIndex < content.length) {
      final remainingText = content.substring(lastIndex);
      if (remainingText.trim().isNotEmpty) {
        widgets.add(pw.Paragraph(text: remainingText));
      }
    }

    // If no images were found at all, just return the whole text
    if (widgets.isEmpty && content.isNotEmpty) {
      widgets.add(pw.Paragraph(text: content));
    }

    return widgets;
  }

  Future<String> _loadLinkedFile(String fileName) async {
    try {
      final cwd = Directory.current;
      final assetsWwwPath = p.join(cwd.path, 'assets', 'www');
      // sanitize title for path: replace newlines with space and trim
      final cleanTitle = _currentTitle
          .replaceAll(RegExp(r'[\r\n]+'), ' ')
          .trim();
      final file = File(p.join(assetsWwwPath, cleanTitle, fileName));
      debugPrint(
        "Debug: Trying to load asset using clean title: '$cleanTitle', path: ${file.path}",
      );
      if (await file.exists()) {
        debugPrint("Debug: Asset found: ${file.path}");
        final content = await file.readAsString();
        // Simple HTML escape for display
        return content
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
      }
      return "File not found: $fileName (in $_currentTitle)";
    } catch (e) {
      return "Error reading file: $e";
    }
  }

  Widget _buildCodeBlockUI(
    String htmlContent,
    String rawCode,
    String? fileName,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
            child: HtmlWidget(
              htmlContent,
              textStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
              customWidgetBuilder: (innerElement) {
                if (innerElement.attributes.containsKey('data-scroll-index')) {
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
            onTap: () => _openRunPage(rawCode, fileName: fileName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    size: 14,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Run',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
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

  Widget _buildHighlightedHtml(ColorScheme colorScheme) {
    _matchKeys = [];

    String htmlContent = md.markdownToHtml(
      _markdownContent,
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
    final String borderColor =
        '#${colorScheme.outlineVariant.value.toRadixString(16).substring(2)}';

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
      textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      customWidgetBuilder: (element) {
        if (element.localName == 'pre') {
          // Check for linked file in class
          String? linkedFileName;
          if (element.children.isNotEmpty &&
              element.children.first.localName == 'code') {
            final codeClass = element.children.first.attributes['class'] ?? '';

            // 1. Check for Quiz
            if (codeClass.contains('language-quiz')) {
              final jsonStr = element.text.trim();
              try {
                final quizData = jsonDecode(jsonStr);
                return QuizWidget(
                  question: quizData['question'],
                  options: List<String>.from(quizData['options']),
                  correctIndex: quizData['correctIndex'],
                );
              } catch (e) {
                return Text(
                  'Error parsing quiz: $e\n$jsonStr',
                  style: const TextStyle(color: Colors.red),
                );
              }
            }

            // 2. Search for :src=filename.ext
            final match = RegExp(r':src=([^\s]+)').firstMatch(codeClass);
            if (match != null) {
              linkedFileName = match.group(1);
            }
          }

          if (linkedFileName != null) {
            return FutureBuilder<String>(
              future: _loadLinkedFile(linkedFileName),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final escapedContent = snapshot.data!;
                  // Wrap in pre for styling consistency
                  final html =
                      '<pre style="margin: 0; padding: 0;">$escapedContent</pre>';
                  // Raw content is unescaped for running
                  final raw = escapedContent
                      .replaceAll('&lt;', '<')
                      .replaceAll('&gt;', '>')
                      .replaceAll('&amp;', '&');
                  // Wait, loadLinkedFile returned escaped!
                  // Actually I should have _loadLinkedFile return RAW and then escape it for display.
                  // I'll fix that.

                  // Re-decode for running, or just load again?
                  // Sticking to "load returns escaped" is weird.
                  // Better: load returns raw.

                  return _buildCodeBlockUI(html, raw, linkedFileName);
                }
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            );
          }

          final codeText = element.text;
          final htmlBlock =
              '<pre style="margin: 0; padding: 0;">${element.innerHtml}</pre>';
          return _buildCodeBlockUI(htmlBlock, codeText, null);
        }

        if (element.localName == 'img') {
          final src = element.attributes['src'];
          debugPrint("DEBUG Admin HtmlWidget: Rendering Image with src: $src");
          if (src != null) {
            // 1. Check for direct local assets
            if (src.startsWith('assets/')) {
              return Image.asset(src);
            }

            // 2. Check for Storage URLs that should be local assets
            if (src.contains('/storage/notes/')) {
              try {
                final uri = Uri.parse(src);
                final filename = uri.pathSegments.last;
                // Remove timestamp prefix
                final cleanFilename = filename.replaceFirst(
                  RegExp(r'^\d+_'),
                  '',
                );

                // Map topic to folder
                String folder = 'JS'; // Default or based on topic
                if (_currentTopic == 'HTML') folder = 'HTML';
                if (_currentTopic == 'CSS') folder = 'CSS';
                if (_currentTopic == 'PHP') folder = 'PHP';

                final assetPath = 'assets/www/pictures/$folder/$cleanFilename';
                debugPrint(
                  "DEBUG Admin HtmlWidget: Trying local asset: $assetPath",
                );

                return Image.asset(
                  assetPath,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      "DEBUG Admin HtmlWidget: Local asset failed ($assetPath), falling back to network",
                    );
                    return Image.network(src);
                  },
                );
              } catch (e) {
                debugPrint("DEBUG Admin HtmlWidget: Error parsing URL: $e");
              }
            }
          }
        }

        if (element.attributes.containsKey('data-scroll-index')) {
          final GlobalKey key = GlobalKey();
          _matchKeys.add(key);
          return SizedBox(width: 1, height: 1, key: key);
        }
        return null;
      },
      customStylesBuilder: (element) {
        if (element.localName == 'table') {
          return {
            'border-collapse': 'collapse',
            'width': '100%',
            'margin-bottom': '15px',
          };
        }
        if (element.localName == 'th' || element.localName == 'td') {
          return {
            'border': '1px solid $borderColor',
            'padding': '8px',
            'vertical-align': 'top',
          };
        }
        return null;
      },
    );
  }

  // ====================================================================
  // UI BUILD METHOD
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return CallbackShortcuts(
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
                BreadcrumbItem(
                  label: 'Note',
                  onTap: () => Navigator.of(context).pop('navigate_home'),
                ),
                BreadcrumbItem(
                  label: _currentTopic,
                  onTap: () => Navigator.of(context).pop(_currentTopic),
                ),
                BreadcrumbItem(label: _currentTitle),
              ],
            ),
            backgroundColor: context
                .getBrandColorForTopic(_currentTopic)
                .withOpacity(0.2),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            elevation: 0,
            actions: [
              if (!_isLoading) ...[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _fetchContent,
                ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  tooltip: _isSearching ? 'Close Search' : 'Search (Ctrl+F)',
                  onPressed: _toggleSearch,
                ),
                if (widget.isStudent)
                  // --- STUDENT VIEW: DOWNLOAD BUTTON ---
                  _isDownloadingPdf
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Download PDF',
                          onPressed: _downloadPdf,
                        )
                else ...[
                  // --- ADMIN VIEW: EDIT/DELETE ---
                  IconButton(
                    icon: Icon(
                      _currentVisibility
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _currentVisibility
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                    tooltip: _currentVisibility ? 'Public' : 'Private',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _currentVisibility
                                ? 'This note is Public'
                                : 'This note is Private',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Note',
                    onPressed: () => _navigateToEdit(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: colorScheme.error),
                    tooltip: 'Delete Note',
                    onPressed: () => DeleteNoteHandler.showDeleteDialog(
                      context,
                      widget.noteId,
                    ),
                  ),
                ],
              ],
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- MARKDOWN SOURCE (Hidden for Students) ---
                          if (!widget.isStudent) ...[
                            Expanded(
                              flex: 1,
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
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Markdown Source',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerLow,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _readOnlyController,
                                        readOnly: true,
                                        maxLines: null,
                                        expands: true,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                          height: 1.5,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.all(16),
                                        ),
                                        onTap: () {
                                          // Redundant check, but good for safety
                                          if (!widget.isStudent) {
                                            Future.delayed(
                                              const Duration(milliseconds: 50),
                                              () {
                                                final cursor =
                                                    _readOnlyController
                                                        .selection
                                                        .baseOffset;
                                                _navigateToEdit(
                                                  cursorIndex: cursor,
                                                );
                                              },
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],

                          // --- PREVIEW SECTION (Expanded for Students) ---
                          Expanded(
                            flex: 1,
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
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Preview',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Only allow tap-to-edit for Admins
                                      if (!widget.isStudent) _navigateToEdit();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerLow,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                        border: Border.all(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: SingleChildScrollView(
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
                        ],
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
    );
  }
}
