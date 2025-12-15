import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_codelab/api/note_api.dart';
// Make sure this import path matches where you created the file above
 
import 'package:flutter_codelab/admin_teacher/widgets/note/run_code_page.dart';
import 'package:flutter_codelab/student/widgets/note/pdf_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:markdown/markdown.dart' as md;

class StudentNoteDetailPage extends StatefulWidget {
  final String noteId;
  final String noteTitle;

  const StudentNoteDetailPage({
    super.key,
    required this.noteId,
    required this.noteTitle,
  });

  @override
  State<StudentNoteDetailPage> createState() => _StudentNoteDetailPageState();
}

class _StudentNoteDetailPageState extends State<StudentNoteDetailPage> {
  final NoteApi _noteApi = NoteApi();
  final PdfService _pdfService = PdfService(); // Initialize the new service

  bool _isLoading = true;
  bool _isDownloadingPdf = false;
  String _markdownContent = "";
  late String _currentTitle;

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
        setState(() {
          _markdownContent = noteData['content'] ?? '';
          _currentTitle = noteData['title'] ?? widget.noteTitle;
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
        content: Text(message,
            style: TextStyle(
                color: isError ? colorScheme.onError : colorScheme.onSecondary)),
        backgroundColor: isError ? colorScheme.error : colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- PDF Logic (Now using Service) ---
  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);

    try {
      await _pdfService.generateAndDownloadPdf(
        title: _currentTitle,
        content: _markdownContent,
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
          _markdownContent, extensionSet: md.ExtensionSet.gitHubFlavored);
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
      if (index < _matchKeys.length && _matchKeys[index].currentContext != null) {
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
        _currentMatchIndex = (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
      });
      _scrollToMatch(_currentMatchIndex);
    }
  }

  void _openRunPage(String code) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RunCodePage(initialCode: code)),
    );
  }

  // --- UI WIDGETS ---
  Widget _buildHighlightedHtml(ColorScheme colorScheme) {
    _matchKeys = [];

    String htmlContent = md.markdownToHtml(_markdownContent,
        extensionSet: md.ExtensionSet.gitHubFlavored);

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
        final pattern = RegExp('(${RegExp.escape(_searchTerm)})(?![^<]*>)',
            caseSensitive: false, multiLine: true);
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
      customStylesBuilder: (element) {
        if (element.localName == 'table') {
          return {
            'border-collapse': 'collapse',
            'width': '100%',
            'margin-bottom': '15px'
          };
        }
        if (element.localName == 'th' || element.localName == 'td') {
          return {
            'border': '1px solid $borderColor',
            'padding': '8px',
            'vertical-align': 'top'
          };
        }
        return null;
      },
      customWidgetBuilder: (element) {
        if (element.localName == 'pre') {
          final codeText = element.text;
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
                  child: Text(codeText,
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace')),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _openRunPage(codeText),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow,
                            size: 14, color: colorScheme.onPrimary),
                        const SizedBox(width: 4),
                        Text('Run',
                            style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _toggleSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _toggleSearch,
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
              title: Text(_currentTitle,
                  style: TextStyle(
                      color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
              backgroundColor: colorScheme.surface,
              iconTheme: IconThemeData(color: colorScheme.onSurface),
              elevation: 0,
              actions: [
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
                                strokeWidth: 2, color: colorScheme.primary)))
                    : IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: _downloadPdf), // Calls the new function
                const SizedBox(width: 8),
              ],
            ),
            body: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildHighlightedHtml(colorScheme),
                        ),
                      ),
                      if (_isSearching)
                        Positioned(
                          top: 16,
                          right: 16,
                          width: screenWidth > 350 ? 350 : screenWidth - 32,
                          child: Material(
                            elevation: 6,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            color: colorScheme.surfaceContainerHigh,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      cursorColor: colorScheme.primary,
                                      style: TextStyle(color: colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        hintText: 'Find...',
                                        hintStyle: TextStyle(
                                            color: colorScheme.onSurfaceVariant),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  if (_searchTerm.isNotEmpty)
                                    Text(
                                      _totalMatches > 0
                                          ? '${_currentMatchIndex + 1}/$_totalMatches'
                                          : 'No results',
                                      style: TextStyle(
                                          color: _totalMatches > 0
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.error,
                                          fontSize: 14),
                                    ),
                                  IconButton(
                                      icon: Icon(Icons.arrow_upward, size: 20),
                                      onPressed: _prevMatch),
                                  IconButton(
                                      icon: Icon(Icons.arrow_downward, size: 20),
                                      onPressed: _nextMatch),
                                  IconButton(
                                      icon: Icon(Icons.close, size: 20),
                                      onPressed: _toggleSearch),
                                ],
                              ),
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