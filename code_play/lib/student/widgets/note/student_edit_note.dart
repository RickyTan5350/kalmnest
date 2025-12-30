import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for keyboard shortcuts
import 'package:code_play/admin_teacher/widgets/note/run_code_page.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// NOTE: Assuming 'run_code_page.dart' is in the same or accessible path.


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
  String _searchTerm = '';
  // --------------------

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
    super.dispose();
  }
  
  // --- Search Logic ---
  void _onSearchChanged() {
    setState(() {
      // Update the search term to trigger a rebuild of the HTML widget
      _searchTerm = _searchController.text.trim();
    });
  }

  void _toggleSearch(BuildContext context) {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        // Request focus when search bar appears
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        // Clear search state when closing
        _searchController.clear();
        _searchTerm = '';
        FocusScope.of(context).unfocus(); // Dismiss keyboard
      }
    });
  }

  void _openRunPage(String code) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunCodePage(initialCode: code),
      ),
    );
  }
  
  // --- HTML Rendering with Highlighting ---
  Widget _buildHighlightedHtml(ColorScheme colorScheme) {
    // 1. Convert Markdown to HTML string
    String htmlContent = md.markdownToHtml(
      _content, 
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    // 2. If searching, inject Highlight spans
    if (_searchTerm.isNotEmpty) {
      // This Regex looks for the search term, BUT uses a "Negative Lookahead" (?![^<]*>)
      // to ensure we don't replace text inside HTML tags (like <div class="search">).
      // It matches the term only if it's NOT followed by a '>' without a preceding '<'.
      try {
        final pattern = RegExp(
          '(${RegExp.escape(_searchTerm)})(?![^<]*>)', 
          caseSensitive: false,
          multiLine: true,
        );
        
        // Wrap matches in a span with a yellow highlight color
        // You can customize the background-color hex code here.
        htmlContent = htmlContent.replaceAllMapped(pattern, (match) {
          return '<span style="background-color: #ffd54f; color: black;">${match.group(1)}</span>';
        });
      } catch (e) {
        // Fallback if regex fails (rare)
        debugPrint("Regex error: $e");
      }
    }

    return HtmlWidget(
      htmlContent, // Pass the modified HTML string
      textStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
      customWidgetBuilder: (element) {
        if (element.localName == 'pre') {
          // Extract text. Note: If we highlighted inside the pre tag, the 
          // <span> tags are technically part of the text now. 
          // For the code runner, we want clean code, so we strip tags if needed.
          final codeText = element.text; 

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
                  child: Text(
                    codeText,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 12, color: colorScheme.onPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'Run',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold
                            )
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
        return null;
      },
      customStylesBuilder: (element) {
        if (element.localName == 'h1') return {'margin-bottom': '10px', 'font-weight': 'bold', 'border-bottom': '1px solid ${colorScheme.outlineVariant.value.toRadixString(16).substring(2)}'};
        if (element.localName == 'table') return {'border-collapse': 'collapse', 'width': '100%'};
        if (element.localName == 'th' || element.localName == 'td') return {'border': '1px solid ${colorScheme.outlineVariant.value.toRadixString(16).substring(2)}', 'padding': '8px'};
        return null;
      },
    );
  }
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Shortcuts wrapper handles Ctrl+F / Cmd+F
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyF): const ActivateIntent(), 
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) => _toggleSearch(context),
          ),
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(
              widget.currentTitle, 
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
            ),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            actions: [
              IconButton(
                // Toggle icon based on state
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: _isSearching ? 'Close Search' : 'Search (Ctrl+F)',
                onPressed: () => _toggleSearch(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Search Bar Widget ---
                if (_isSearching) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search in note...',
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHigh,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              prefixIcon: const Icon(Icons.search, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // -----------------------------
                
                // Display Topic and Visibility
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Topic: ${widget.currentTopic}', 
                          style: TextStyle(color: colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                    Text(
                      widget.currentVisibility ? 'Public' : 'Private',
                      style: TextStyle(
                        color: widget.currentVisibility ? colorScheme.secondary : colorScheme.error,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        ),
                        child: Text('Note Content', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
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
        ),
      ),
    );
  }
}
