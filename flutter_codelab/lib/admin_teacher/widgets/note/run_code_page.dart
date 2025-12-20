import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RunCodePage extends StatefulWidget {
  final String initialCode;

  const RunCodePage({super.key, required this.initialCode});

  @override
  State<RunCodePage> createState() => _RunCodePageState();
}

class _RunCodePageState extends State<RunCodePage> {
  late TextEditingController _codeController;
  InAppWebViewController? _webViewController;
  final TextEditingController _urlBarController = TextEditingController(text: "https://mysite.com/preview");
  
  bool _isRealBrowserReady = false;
  String _browserTitle = "Preview";

  // Cache for your libraries
  final Map<String, String> _bundledLibraries = {};

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);
    _updateTitleFromCode(widget.initialCode);
    
    // Load libraries in background
    _loadBundledLibraries();
  }

  // --- 1. Load Libraries from Assets ---
  Future<void> _loadBundledLibraries() async {
    try {
      _bundledLibraries['math.js'] = await rootBundle.loadString('assets/js/math.js');
      _bundledLibraries['date.js'] = await rootBundle.loadString('assets/js/date.js');
      print("Libraries loaded successfully");
    } catch (e) {
      print("Error loading libraries: $e");
    }
  }

  void _updateTitleFromCode(String code) {
    final RegExp titleRegex = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, multiLine: true);
    final Match? match = titleRegex.firstMatch(code);

    setState(() {
      if (match != null && match.groupCount >= 1) {
        _browserTitle = match.group(1) ?? "Preview";
      } else {
        if (!_browserTitle.startsWith("http")) {
           _browserTitle = "Preview";
        }
      }
    });
  }

  // --- FIXED SMART WRAPPER ---
  String _wrapHtml(String rawContent) {
    const String forcedStyles = '''
<style>
  body { 
    background-color: #ffffff !important; 
    color: #000000 !important; 
    font-family: sans-serif;
    margin: 0;
    padding: 8px;
  }
</style>
''';

    // 1. Separate Top-Level JS (if any) from HTML
    String topPartJs = "";
    String htmlPart = rawContent;

    if (rawContent.contains('<html')) {
      int htmlStartIndex = rawContent.indexOf('<html');
      
      // Only extract top JS if <html> isn't at the very start
      if (htmlStartIndex > 0) {
        topPartJs = rawContent.substring(0, htmlStartIndex).trim();
        htmlPart = rawContent.substring(htmlStartIndex);
      }
    } else {
      // Fallback for simple snippets
      return '''
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">$forcedStyles</head>
<body>$rawContent</body>
</html>
      ''';
    }

    // 2. LIBRARY INJECTION (Runs on the HTML part)
    
    // Regex for standard <script src="..."></script>
    final scriptRegex = RegExp(r'''<script\b[^>]*\bsrc=["']([\w\d_.-]+\.js)["'][^>]*>.*?</\s*script>''', caseSensitive: false, dotAll: true);
    
    // Regex for self-closing <script src="..." />
    final selfClosingRegex = RegExp(r'''<script\b[^>]*\bsrc=["']([\w\d_.-]+\.js)["'][^>]*/>''', caseSensitive: false);

    // Replace standard tags
    htmlPart = htmlPart.replaceAllMapped(scriptRegex, (match) {
      String filename = match.group(1) ?? "";
      if (_bundledLibraries.containsKey(filename)) {
        return '<script>\n/* Injected $filename */\n${_bundledLibraries[filename]}\n</script>';
      }
      return ""; // Remove unknown scripts to prevent errors
    });

    // Replace self-closing tags
    htmlPart = htmlPart.replaceAllMapped(selfClosingRegex, (match) {
      String filename = match.group(1) ?? "";
      if (_bundledLibraries.containsKey(filename)) {
        return '<script>\n/* Injected $filename */\n${_bundledLibraries[filename]}\n</script>';
      }
      return "";
    });

    // 3. Inject the "Top Part JS" if it existed
    if (topPartJs.isNotEmpty) {
      if (htmlPart.contains('</head>')) {
        htmlPart = htmlPart.replaceFirst(
          '</head>', 
          '<script>\n/* Injected Top JS */\n$topPartJs\n</script>\n</head>'
        );
      } else {
        htmlPart = '<script>\n$topPartJs\n</script>\n$htmlPart';
      }
    }

    // 4. Inject CSS Styles
    return _injectStyles(htmlPart, forcedStyles);
  }

  String _injectStyles(String content, String styles) {
    if (content.toLowerCase().contains('</head>')) {
      return content.replaceFirst(
          RegExp(r'</head>', caseSensitive: false), '$styles</head>');
    } else if (content.toLowerCase().contains('<body>')) {
      return content.replaceFirst(
          RegExp(r'<body>', caseSensitive: false), '<body>$styles');
    }
    return styles + content;
  }

  void _runCode() {
    _updateTitleFromCode(_codeController.text);

    if (_webViewController != null) {
       final fullHtml = _wrapHtml(_codeController.text);
      _webViewController!.loadData(data: fullHtml);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code executed!'), duration: Duration(milliseconds: 500)),
    );
  }

  void _loadRealUrl(String url) {
    if (_webViewController == null) return;
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _urlBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Code Editor', 
          style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _runCode,
              icon: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
              label: Text(
                "Run", 
                style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary, 
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // --- LEFT: EDITOR ---
          Expanded(
            flex: 1,
            child: Container(
              color: colorScheme.surface, 
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: colorScheme.surfaceContainerHighest, 
                    child: Text(
                      "Source Code", 
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _codeController,
                        style: TextStyle(
                          color: colorScheme.onSurface, 
                          fontFamily: 'monospace', 
                          fontSize: 14, 
                          height: 1.5
                        ),
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          VerticalDivider(width: 8, thickness: 8, color: colorScheme.outlineVariant),

          // --- RIGHT: PREVIEW ---
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white, 
              child: Column(
                children: [
                  // Browser Header
                  Container(
                    height: 36,
                    color: const Color(0xFFF1F1F1),
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.public, size: 14, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _browserTitle,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis, color: Colors.black87)
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // URL Bar
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Colors.white, 
                      border: Border(bottom: BorderSide(color: Colors.black12))
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.refresh, size: 18, color: Colors.black54), onPressed: () => _webViewController?.reload()),
                        Expanded(
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                const Icon(Icons.lock, size: 12, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _urlBarController,
                                    onSubmitted: (value) => _loadRealUrl(value),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(bottom: 2), hintText: "Enter URL"),
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Real Browser
                  Expanded(
                    child: InAppWebView(
                      initialSettings: InAppWebViewSettings(
                        isInspectable: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        iframeAllow: "camera; microphone",
                        iframeAllowFullscreen: true,
                      ),
                      onWebViewCreated: (controller) async {
                        _webViewController = controller;
                        _isRealBrowserReady = true;
                        
                        // Load initial content
                         final fullHtml = _wrapHtml(_codeController.text);
                         await _webViewController!.loadData(data: fullHtml);
                      },
                      onLoadStop: (controller, url) {
                        if (mounted) {
                           _urlBarController.text = url.toString();
                        }
                      },
                      onTitleChanged: (controller, title) {
                        if (mounted && title != null && title.isNotEmpty) {
                           setState(() => _browserTitle = title);
                        }
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        print("Console: ${consoleMessage.message}");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
