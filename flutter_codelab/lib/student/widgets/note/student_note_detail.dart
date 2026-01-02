import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:code_play/api/note_api.dart';
// Make sure this import path matches where you created the file above
import 'package:code_play/constants/api_constants.dart';

import 'package:code_play/admin_teacher/widgets/note/run_code_launcher.dart';
import 'package:code_play/admin_teacher/widgets/note/search_note.dart';
import 'package:path/path.dart' as p;
import 'package:code_play/student/widgets/note/pdf_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:code_play/admin_teacher/widgets/note/quiz_widget.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/utils/brand_color_extension.dart';

class StudentNoteDetailPage extends StatefulWidget {
  final String noteId;
  final String noteTitle;
  final String topic;

  const StudentNoteDetailPage({
    super.key,
    required this.noteId,
    required this.noteTitle,
    this.topic = '', // Add topic with default empty
  });

  @override
  State<StudentNoteDetailPage> createState() => _StudentNoteDetailPageState();
}

class _StudentNoteDetailPageState extends State<StudentNoteDetailPage> {
  final NoteApi _noteApi = NoteApi();
  final PdfService _pdfService = PdfService();

  bool _isLoading = true;
  bool _isDownloadingPdf = false;
  String _markdownContent = "";
  late String _currentTitle;
  late String _currentTopic; // State variable for topic
  final Map<String, int> _quizStates =
      {}; // Track quiz answers: Question Text -> Selected Index

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
    _currentTopic = widget.topic; // Initialize with widget's topic
    _searchController.addListener(_onSearchChanged);
    _fetchContent();
  }

  @override
  void dispose() {
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
        // VISIBILITY CHECK
        final vis = noteData['visibility'];
        bool isVisible = true;
        if (vis is int) isVisible = vis == 1;
        if (vis is bool) isVisible = vis;

        if (!isVisible) {
          setState(() => _isLoading = false);
          if (mounted) {
            Navigator.pop(context);
            _showSnackBar('This note is private.', isError: true);
          }
          return;
        }

        setState(() {
          _markdownContent = noteData['content'] ?? '';
          _currentTitle = noteData['title'] ?? widget.noteTitle;
          // Update local topic from API response
          _currentTopic = noteData['topic'] ?? _currentTopic;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? colorScheme.onError : colorScheme.onSecondary,
          ),
        ),

        backgroundColor: isError ? colorScheme.error : colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- PDF Logic (Now using Service) ---
  Future<void> _downloadPdf() async {
    if (kIsWeb) {
      _showSnackBar('PDF download is not supported on Web.', isError: true);
      return;
    }
    setState(() => _isDownloadingPdf = true);

    try {
      await _pdfService.generateAndDownloadPdf(
        title: _currentTitle,
        content: _markdownContent,
        quizStates: _quizStates,
      );
    } catch (e) {
      _showSnackBar('Failed to generate PDF: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

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
          isAdmin: false,
        ),
      ),
    );

    if (result == 'navigate_home') {
      if (mounted) Navigator.pop(context, 'navigate_home');
    } else if (result == 'navigate_topic') {
      if (mounted) Navigator.pop(context, _currentTopic);
    }
  }

  // Helper to ensure absolute URLs
  String _processMarkdown(String content) {
    debugPrint("DEBUG processMarkdown: Raw content length: ${content.length}");
    final domain = ApiConstants.domain;
    final processed = content.replaceAll('](/storage/', ']($domain/storage/');

    // Debug: Find image links
    final imageRegex = RegExp(r'!\[.*?\]\((.*?)\)');
    final matches = imageRegex.allMatches(processed);
    for (final match in matches) {
      debugPrint("DEBUG: Found processed image URL: ${match.group(1)}");
    }

    return processed;
  }

  // --- UI WIDGETS ---
  Future<String> _loadLinkedFile(String fileName) async {
    try {
      final cleanTitle = _currentTitle
          .replaceAll(RegExp(r'[\r\n]+'), ' ')
          .trim();

      // WEB IMPLEMENTATION
      // WEB IMPLEMENTATION
      if (kIsWeb) {
        try {
          final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
          final assets = manifest.listAssets();

          final cleanRaw = Uri.decodeFull(
            _currentTitle,
          ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

          final targetFileName = fileName.toLowerCase();

          final wwwKeys = assets.where((k) => k.startsWith('assets/www/'));
          String? resolvedPath;
          List<String> validFolderCandidates = [];

          for (var key in wwwKeys) {
            final parts = key.split('/');
            if (parts.length < 4) continue;

            final fName = parts.last.toLowerCase();

            if (fName == targetFileName) {
              final folderNameRaw = parts[2];
              final decodedFolder = Uri.decodeFull(folderNameRaw);
              final cleanFolder = decodedFolder.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '',
              );

              print("DEBUG (Student) SCANNED: $key");
              print("   -> Clean Folder: '$cleanFolder' vs Raw '$cleanRaw'");

              // 1a. Exact Match
              if (cleanFolder == cleanRaw) {
                resolvedPath = key;
                break;
              }

              // 1b. Containment Match
              if (cleanFolder.contains(cleanRaw) ||
                  cleanRaw.contains(cleanFolder)) {
                resolvedPath = key;
                break;
              }

              validFolderCandidates.add(folderNameRaw);
            }
          }

          // Strategy 2: Unique candidate match
          if (resolvedPath == null && validFolderCandidates.length == 1) {
            final bestGuessFolder = validFolderCandidates.first;
            resolvedPath = wwwKeys.firstWhere(
              (k) =>
                  k.contains(bestGuessFolder) &&
                  k.toLowerCase().endsWith('/$targetFileName'),
            );
            print(
              "DEBUG (Student): Fuzzy matched by unique filename in folder: $bestGuessFolder",
            );
          }

          if (resolvedPath != null) {
            final content = await rootBundle.loadString(resolvedPath);
            return content
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;');
          }

          print(
            "DEBUG (Student) ERROR: Could not find '$fileName' for note '$_currentTitle'.",
          );
          if (validFolderCandidates.isNotEmpty) {
            return "File not found (Web): $fileName\nCandidates:\n${validFolderCandidates.join('\n')}";
          }

          return "File not found (Web): $fileName";
        } catch (e) {
          return "Error reading file (Web): $e";
        }
      }

      // MOBILE IMPLEMENTATION
      final cwd = Directory.current;
      final assetsWwwPath = p.join(cwd.path, 'assets', 'www');
      final file = File(p.join(assetsWwwPath, cleanTitle, fileName));
      debugPrint(
        "Debug: Trying to load asset using clean title: '$cleanTitle', path: ${file.path}",
      );
      if (await file.exists()) {
        debugPrint("Debug: Asset found: ${file.path}");
        final content = await file.readAsString();
        return content
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;');
      }
      return "File not found: $fileName";
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
    final canRun =
        (_currentTopic == 'HTML' ||
        _currentTopic == 'CSS' ||
        _currentTopic == 'JS' ||
        _currentTopic == 'PHP' ||
        _currentTopic == 'General');

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
        if (canRun)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _openRunPage(rawCode, fileName: fileName),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
      _processMarkdown(_markdownContent),
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
      baseUrl: Uri.parse(ApiConstants.domain),
      textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      customWidgetBuilder: (element) {
        if (element.localName == 'pre') {
          String? linkedFileName;
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
                  initialSelectedIndex: _quizStates[quizData['question']],
                  onAnswerSelected: (index) {
                    _quizStates[quizData['question']] = index;
                  },
                );
              } catch (e) {
                return Text(
                  'Error parsing quiz: $e',
                  style: const TextStyle(color: Colors.red),
                );
              }
            }

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
                  final html =
                      '<pre style="margin: 0; padding: 0;">$escapedContent</pre>';
                  final raw = escapedContent
                      .replaceAll('&lt;', '<')
                      .replaceAll('&gt;', '>')
                      .replaceAll('&amp;', '&');
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
          debugPrint("DEBUG HtmlWidget: Rendering Image with src: $src");
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
        child: GestureDetector(
          onTap: () {
            if (!_searchFocusNode.hasFocus) _pageFocusNode.requestFocus();
          },
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
                if (!_isLoading)
                  IconButton(
                    icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                    tooltip: 'Refresh',
                    onPressed: _fetchContent,
                  ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  tooltip: _isSearching ? 'Close Search' : 'Search (Ctrl+F)',
                  onPressed: _toggleSearch,
                ),
                _isDownloadingPdf
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: _downloadPdf,
                      ), // Calls the new function
                const SizedBox(width: 8),
              ],
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildHighlightedHtml(colorScheme),
                            ),
                          ),
                        ),
                      ),
                      if (_isSearching)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
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
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
