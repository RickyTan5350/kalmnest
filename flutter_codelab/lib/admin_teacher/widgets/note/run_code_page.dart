import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../constants/api_constants.dart';

class CodeFile {
  String name;
  String content;
  CodeFile({required this.name, required this.content});
}

class RunCodePage extends StatefulWidget {
  final String initialCode;
  final String? contextId;

  const RunCodePage({super.key, required this.initialCode, this.contextId});

  @override
  State<RunCodePage> createState() => _RunCodePageState();
}

class _RunCodePageState extends State<RunCodePage> {
  late TextEditingController _codeController;
  InAppWebViewController? _webViewController;
  final TextEditingController _urlBarController = TextEditingController(
    text: "https://mysite.com/preview",
  );

  // Multi-tab state
  List<CodeFile> _files = [];
  int _activeFileIndex = 0;

  String _browserTitle = "Preview";
  InAppLocalhostServer? _localhostServer;
  int _serverPort = 8080;
  String _output = "";
  final Completer<void> _serverReady = Completer<void>();

  // Cache for your libraries
  final Map<String, String> _bundledLibraries = {};

  @override
  void initState() {
    super.initState();
    _startLocalServer();

    // Initialize files - Default filename based on content
    String defaultName = 'index.html';
    if (widget.initialCode.contains('<?php')) {
      defaultName = 'main.php';
    }

    _files = [CodeFile(name: defaultName, content: widget.initialCode)];
    _activeFileIndex = 0;

    _codeController = TextEditingController(text: _files[0].content);
    _codeController.addListener(_onCodeChanged);

    _updateTitleFromCode(widget.initialCode);

    // Load libraries in background
    _loadBundledLibraries();
  }

  void _onCodeChanged() {
    // Sync controller text to active file model
    if (_activeFileIndex < _files.length) {
      _files[_activeFileIndex].content = _codeController.text;
    }
  }

  void _switchTab(int index) {
    if (index == _activeFileIndex) return;
    setState(() {
      _activeFileIndex = index;
      _codeController.text = _files[index].content;
    });
  }

  void _addNewFile() {
    showDialog(
      context: context,
      builder: (context) {
        String newName = "new_file.txt";
        return AlertDialog(
          title: const Text("New File"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: "File Name"),
            onChanged: (v) => newName = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _files.add(CodeFile(name: newName, content: ""));
                  _switchTab(_files.length - 1);
                });
                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _renameFile(int index) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = _files[index].name;
        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            autofocus: true,
            controller: TextEditingController(text: newName),
            decoration: const InputDecoration(labelText: "File Name"),
            onChanged: (v) => newName = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _files[index].name = newName;
                });
                Navigator.pop(context);
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _deleteFile(int index) {
    if (_files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete the last file.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete File"),
        content: Text("Delete ${_files[index].name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _files.removeAt(index);
                if (_activeFileIndex >= _files.length) {
                  _activeFileIndex = _files.length - 1;
                }
                _codeController.text = _files[_activeFileIndex].content;
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _startLocalServer() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _serverPort = server.port;
      _localhostServer = null;
      if (!_serverReady.isCompleted) _serverReady.complete();

      server.listen((HttpRequest request) async {
        final path = request.uri.path;

        // --- 0. PROXY POST REQUESTS (PHP FORM SUPPORT) ---
        if (request.method == 'POST') {
          try {
            final content = await utf8.decoder.bind(request).join();
            final formData = Uri.splitQueryString(content);

            print("DEBUG: Intercepted POST request: $formData");

            String codeToExecute = _codeController.text;

            // --- MULTI-FILE PHP SUPPORT ---
            // If the POST is to a specific .php file (e.g., /Biodata.php), try to load it from assets.
            if (path.endsWith('.php') && widget.contextId != null) {
              try {
                // path has leading slash, e.g. /Biodata.php
                final assetPath = 'assets/www/${widget.contextId}$path';
                final fileData = await rootBundle.loadString(assetPath);
                codeToExecute = fileData;
                print("DEBUG: Resolved PHP file from assets: $assetPath");
              } catch (e) {
                print("DEBUG: Asset load failed ($path): $e");

                // Fallback: Try reading directly from filesystem (Local Dev Mode)
                try {
                  // Try to construct absolute path or relative path
                  // Assuming running from project root or typical structure
                  final localFile = File('assets/www/${widget.contextId}$path');
                  if (await localFile.exists()) {
                    codeToExecute = await localFile.readAsString();
                    print(
                      "DEBUG: Resolved PHP file from Local Filesystem: ${localFile.path}",
                    );
                  } else {
                    // Attempt one level up if in nested execution?
                    // D:\Github_Project\kalmnest\flutter_codelab\assets\www\...
                    // Current dir might be different depending on runner.
                    // Let's print CWD to debug if this fails, but usually it works for flutter run
                    print(
                      "DEBUG: File not found on disk at: ${localFile.path} (CWD: ${Directory.current.path})",
                    );
                  }
                } catch (e2) {
                  print("DEBUG: Filesystem fallback failed: $e2");
                }
              }
            }
            // ------------------------------

            // Executing PHP with this form data

            // 1. Determine local file match from our tabs
            // path is like /submit.php
            final relativeName = path.startsWith('/')
                ? path.substring(1)
                : path;

            // Check if we have this file in our tabs
            final matchingFileIndex = _files.indexWhere(
              (f) => f.name == relativeName,
            );

            if (matchingFileIndex != -1) {
              codeToExecute = _files[matchingFileIndex].content;
              print("DEBUG: Found target file in tabs: $relativeName");
            }

            // Execute using our new signature
            final output = await _executePhp(
              files: _files,
              entryPoint: relativeName,
              formData: formData,
            );

            // Serve the result back to the browser
            request.response
              ..headers.contentType = ContentType.html
              ..write(output)
              ..close();
          } catch (e) {
            print("Error parsing POST data: $e");
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write("Error processing form: $e")
              ..close();
          }
          return;
        }

        // 1. Serve Dynamic HTML Files (from Temp Dir)
        if (path.endsWith('.html') || path == '/') {
          final dir = await getTemporaryDirectory();
          // Default to index.html if root requested, though we usually request specific files now
          final filePath = (path == '/') ? 'index.html' : path.substring(1);
          final file = File('${dir.path}/$filePath');

          if (await file.exists()) {
            final content = await file.readAsString();
            request.response
              ..headers.contentType = ContentType.html
              ..write(content)
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..close();
          }
          return;
        }

        // 2. Serve Static Assets (from assets/www)
        try {
          // Remove leading slash for asset key
          final assetKey = 'assets/www${path}';
          final data = await rootBundle.load(assetKey);

          final contentType = _getContentType(path);
          request.response.headers.contentType = contentType;
          request.response.add(data.buffer.asUint8List());
          request.response.close();
        } catch (e) {
          print("Asset not found: $path ($e)");
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });

      print("Local server started on port $_serverPort");
    } catch (e) {
      print("Failed to start local server: $e");
    }
  }

  ContentType _getContentType(String path) {
    if (path.endsWith('.html')) return ContentType.html;
    if (path.endsWith('.js')) return ContentType('application', 'javascript');
    if (path.endsWith('.css')) return ContentType('text', 'css');
    if (path.endsWith('.png')) return ContentType('image', 'png');
    if (path.endsWith('.jpg') || path.endsWith('.jpeg'))
      return ContentType('image', 'jpeg');
    if (path.endsWith('.json')) return ContentType.json;
    return ContentType.binary;
  }

  // --- 1. Load Libraries from Assets ---
  Future<void> _loadBundledLibraries() async {
    try {
      _bundledLibraries['math.js'] = await rootBundle.loadString(
        'assets/js/math.js',
      );
      _bundledLibraries['date.js'] = await rootBundle.loadString(
        'assets/js/date.js',
      );
      print("Libraries loaded successfully");
    } catch (e) {
      print("Error loading libraries: $e");
    }
  }

  void _updateTitleFromCode(String code) {
    final RegExp titleRegex = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      multiLine: true,
    );
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
    final scriptRegex = RegExp(
      r'''<script\b[^>]*\bsrc=["']([\w\d_.-]+\.js)["'][^>]*>.*?</\s*script>''',
      caseSensitive: false,
      dotAll: true,
    );

    // Regex for self-closing <script src="..." />
    final selfClosingRegex = RegExp(
      r'''<script\b[^>]*\bsrc=["']([\w\d_.-]+\.js)["'][^>]*/>''',
      caseSensitive: false,
    );

    // Replace standard tags
    htmlPart = htmlPart.replaceAllMapped(scriptRegex, (match) {
      String filename = match.group(1) ?? "";
      if (_bundledLibraries.containsKey(filename)) {
        return '<script>\n/* Injected \$filename */\n${_bundledLibraries[filename]}\n</script>';
      }
      return ""; // Remove unknown scripts to prevent errors
    });

    // Replace self-closing tags
    htmlPart = htmlPart.replaceAllMapped(selfClosingRegex, (match) {
      String filename = match.group(1) ?? "";
      if (_bundledLibraries.containsKey(filename)) {
        return '<script>\n/* Injected \$filename */\n${_bundledLibraries[filename]}\n</script>';
      }
      return "";
    });

    // 3. Inject the "Top Part JS" if it existed
    if (topPartJs.isNotEmpty) {
      if (htmlPart.contains('</head>')) {
        htmlPart = htmlPart.replaceFirst(
          '</head>',
          '<script>\n/* Injected Top JS */\n$topPartJs\n</script>\n</head>',
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
        RegExp(r'</head>', caseSensitive: false),
        '$styles</head>',
      );
    } else if (content.toLowerCase().contains('<body>')) {
      return content.replaceFirst(
        RegExp(r'<body>', caseSensitive: false),
        '<body>$styles',
      );
    }
    return styles + content;
  }

  Future<void> _updateAndReload(String content) async {
    // 1. Write ALL files to a temp directory so they can reference each other
    try {
      final dir = await getTemporaryDirectory();
      // Use timestamp to ensure unique folder for this run
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final runDir = Directory('${dir.path}/run_$timestamp');
      await runDir.create();

      // Write all files
      for (var file in _files) {
        final f = File('${runDir.path}/${file.name}');
        await f.writeAsString(file.content);
      }

      // If we are showing an output (PHP result), write that as index.html or similar
      // Or if we are in local mode, we want to load the ACTIVE file.

      String targetUrl = "";

      // If content is provided (PHP Output), write it as a special preview file
      if (content != _files[_activeFileIndex].content) {
        final previewFile = File('${runDir.path}/preview_output.html');
        // Apply the wrapper
        final fullHtml = _wrapHtml(content);
        await previewFile.writeAsString(fullHtml);
        targetUrl =
            "http://localhost:$_serverPort/run_$timestamp/preview_output.html";
      } else {
        // Local Mode: Load the active file
        // If it's HTML, load it. If JS/CSS, maybe warn or show raw?
        // Usually we run the HTML file.
        final activeFileName = _files[_activeFileIndex].name;
        targetUrl =
            "http://localhost:$_serverPort/run_$timestamp/$activeFileName";
      }

      print("DEBUG: Loading URL: $targetUrl");

      if (_webViewController != null) {
        // Wait for server to be ready
        await _serverReady.future;
        _webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(targetUrl)),
        );
      }
    } catch (e) {
      print("Error writing file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error writing preview file: $e')));
    }
  }

  // --- PHP EXECUTION HELPER ---
  Future<String> _executePhp({
    required List<CodeFile> files,
    String? entryPoint,
    Map<String, dynamic>? formData,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/run-code');
      // Pass both files and form_data (if any)
      final body = {
        'files': files
            .map((f) => {'name': f.name, 'content': f.content})
            .toList(),
        'entry_point': entryPoint,
        'context_id': widget.contextId,
        if (formData != null) 'form_data': formData,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['output'] ?? ''; // Return the output HTML
      } else {
        return "Backend Error (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      return "Network Error: $e";
    }
  }

  Future<void> _runCode() async {
    // 1. Sync active file content logic is already handled by listener,
    // but good to ensure before run.
    if (_activeFileIndex < _files.length) {
      _files[_activeFileIndex].content = _codeController.text;
    }

    final currentFile = _files[_activeFileIndex];

    // Detect Language Mode
    bool isPhp = _files.any((f) => f.name.endsWith('.php'));

    if (isPhp) {
      // --- PHP MODE ---
      print(
        "DEBUG: [PHP MODE] Sending code to: ${ApiConstants.baseUrl}/run-code",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Executing PHP on backend...'),
          duration: Duration(milliseconds: 800),
        ),
      );

      final output = await _executePhp(
        files: _files,
        entryPoint: currentFile.name,
      );

      print(
        "DEBUG: _executePhp returned: ${output.length > 50 ? output.substring(0, 50) : output}...",
      );

      _updateTitleFromCode(output);
      setState(() {
        _output = output;
      });
      // For PHP, we display the OUTPUT string, not the source file
      await _updateAndReload(output);
    } else {
      // --- LOCAL WEB MODE ---
      print("DEBUG: [WEB MODE] Running locally");
      // Just reload. _updateAndReload will write all files and load the active one.
      _updateTitleFromCode(currentFile.content);
      setState(() {
        _output = currentFile.content;
      });
      // Pass content same as file content to indicate we are just loading the file
      await _updateAndReload(currentFile.content);
    }
  }

  Future<void> _loadRealUrl(String url) async {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    if (_webViewController == null) return;
    _webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _urlBarController.dispose();
    _localhostServer?.close(); // Identify if we used specific class
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
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: ElevatedButton.icon(
              onPressed: _runCode,
              icon: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
              label: Text(
                "Run",
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
                    height: 40,
                    color: colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              final isActive = index == _activeFileIndex;
                              return GestureDetector(
                                onTap: () => _switchTab(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? colorScheme.surface
                                        : Colors.transparent,
                                    border: Border(
                                      right: BorderSide(
                                        color: colorScheme.outlineVariant,
                                        width: 1,
                                      ),
                                      top: isActive
                                          ? BorderSide(
                                              color: colorScheme.primary,
                                              width: 2,
                                            )
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        file.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isActive
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 100,
                                          ),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'rename',
                                              height: 32,
                                              child: Text(
                                                "Rename",
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              height: 32,
                                              child: Text(
                                                "Delete",
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'rename')
                                              _renameFile(index);
                                            if (value == 'delete')
                                              _deleteFile(index);
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Add File Button
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: "New File",
                          onPressed: _addNewFile,
                        ),
                      ],
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
                          height: 1.5,
                        ),
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          VerticalDivider(
            width: 8,
            thickness: 8,
            color: colorScheme.outlineVariant,
          ),

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.public,
                                size: 14,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _browserTitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis,
                                    color: Colors.black87,
                                  ),
                                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.black54,
                          ),
                          onPressed: () => _webViewController?.reload(),
                        ),
                        Expanded(
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _urlBarController,
                                    onSubmitted: (value) => _loadRealUrl(value),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                        bottom: 2,
                                      ),
                                      hintText: "Enter URL",
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
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

                  // Real Browser
                  Expanded(
                    child: InAppWebView(
                      initialSettings: InAppWebViewSettings(
                        isInspectable: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        allowUniversalAccessFromFileURLs: true,
                      ),
                      onWebViewCreated: (controller) async {
                        print("DEBUG: onWebViewCreated fired!");
                        _webViewController = controller;

                        // Initial load
                        if (widget.initialCode.isNotEmpty) {
                          _updateAndReload(widget.initialCode);
                        }
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
