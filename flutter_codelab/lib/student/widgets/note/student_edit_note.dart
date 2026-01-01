import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for keyboard shortcuts
import 'package:flutter_codelab/admin_teacher/widgets/note/run_code_page.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_codelab/admin_teacher/widgets/note/search_note.dart';

class ViewNotePage extends StatefulWidget {
  final String noteId;
  final String currentTitle;
  final String currentContent;
  final String currentTopic;
  final bool currentVisibility;
  final int? initialCursorIndex;

  const ViewNotePage({
    super.key,
    required this.noteId,
    required this.currentTitle,
    required this.currentContent,
    required this.currentTopic,
    required this.currentVisibility,
    this.initialCursorIndex,
  });

  @override
  State<ViewNotePage> createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  late String _content;

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
    _content = widget.currentContent;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageFocusNode.dispose();
    super.dispose();
  }

  // --- Search Logic ---
  void _onSearchChanged() {
    final term = _searchController.text.trim();
    int newTotal = 0;
    if (term.isNotEmpty) {
      String htmlContent = md.markdownToHtml(
        _processMarkdown(_content),
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

  void _openRunPage(String code) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunCodePage(
          initialCode: code,
          contextId: widget.currentTitle,
          topic: widget.currentTopic,
          noteTitle: widget.currentTitle,
          isAdmin: false,
        ),
      ),
    );
  }

  // Helper to ensure absolute URLs
  String _processMarkdown(String content) {
    final domain = ApiConstants.domain;
    return content.replaceAll('](/storage/', ']($domain/storage/');
  }

  // --- HTML Rendering with Highlighting ---
  Widget _buildHighlightedHtml(ColorScheme colorScheme) {
    _matchKeys = [];

    // 1. Convert Markdown to HTML string
    String htmlContent = md.markdownToHtml(
      _processMarkdown(_content),
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

    // 2. If searching, inject Highlight spans
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
          // Extract text. Note: If we highlighted inside the pre tag, the
          // <span> tags are technically part of the text now.
          // For the code runner, we want clean code, so we strip tags if needed.
          final codeText = element.text;
          // Use innerHtml to preserve highlighting spans, wrapped in pre to preserve whitespace
          final htmlContent =
              '<pre style="margin: 0; padding: 0;">${element.innerHtml}</pre>';

          return Column(
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
                  // Use HtmlWidget to render the code with highlights
                  child: HtmlWidget(
                    htmlContent,
                    textStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
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
              // "Run" Button overlay
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
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
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Shortcuts wrapper handles Ctrl+F / Cmd+F
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
              title: Text(
                widget.currentTitle,
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
                  // Toggle icon based on state
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  tooltip: _isSearching ? 'Close Search' : 'Search (Ctrl+F)',
                  onPressed: _toggleSearch,
                ),
              ],
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Topic and Visibility
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                'Topic: ${widget.currentTopic}',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            widget.currentVisibility ? 'Public' : 'Private',
                            style: TextStyle(
                              color: widget.currentVisibility
                                  ? colorScheme.secondary
                                  : colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Live Preview of the Content
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
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
                                'Note Content',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                // This renders the HTML with highlighted words
                                child: _buildHighlightedHtml(colorScheme),
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
      ),
    );
  }
}
