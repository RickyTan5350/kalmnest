import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';
// import 'dart:io'; // NOT ON WEB
import 'package:code_play/admin_teacher/widgets/note/models/code_file.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/utils/brand_color_extension.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:code_play/constants/api_constants.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class RunCodePage extends StatefulWidget {
  final String initialCode;
  final String? contextId;
  final String? initialFileName;
  final String topic;
  final String noteTitle;
  final bool isAdmin;
  final Function(String oldName, String newName)? onFileRenamed;

  const RunCodePage({
    super.key,
    required this.initialCode,
    this.contextId,
    this.initialFileName,
    required this.topic,
    required this.noteTitle,
    this.isAdmin = false,
    this.onFileRenamed,
  });

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
  late String _webSessionId;
  StreamSubscription? _messageSubscription;

  String? _resolvedContextPath;

  @override
  void initState() {
    super.initState();

    // Initialize files
    String defaultName = widget.initialFileName ?? 'index.html';
    if (widget.initialFileName == null &&
        widget.initialCode.contains('<?php')) {
      defaultName = 'main.php';
    }

    _files = [CodeFile(name: defaultName, content: widget.initialCode)];
    _activeFileIndex = 0;
    _webSessionId = "web-session-${DateTime.now().millisecondsSinceEpoch}";

    _codeController = TextEditingController(text: _files[0].content);
    _codeController.addListener(_onCodeChanged);

    _resolveContextPath().then((_) {
      _loadContextAssets();
    });

    // Listen for cross-origin messages from the iframe
    _messageSubscription = web.window.onMessage.listen((event) {
      final JSAny? rawData = event.data;
      if (rawData != null && rawData.isA<JSString>()) {
        final String data = (rawData as JSString).toDart;
        if (data.startsWith('FLUTTER_WEB_BRIDGE:')) {
          try {
            final jsonStr = data.substring('FLUTTER_WEB_BRIDGE:'.length);
            final Map<String, dynamic> msg = jsonDecode(jsonStr);
            final String action = msg['action'];
            final Map<String, dynamic> msgData = msg['data'];

            print(
              "DEBUG WEB BRIDGE (postMessage): Action: $action, Data: $msgData",
            );

            if (action == 'form_submit') {
              final String urlStr = msgData['url'];
              final String method = msgData['method'];
              final Map<String, dynamic> formData = msgData['formData'];

              final uri = Uri.parse(urlStr);
              String targetFile = uri.path;
              if (targetFile.startsWith('/'))
                targetFile = targetFile.substring(1);
              if (targetFile.isEmpty || targetFile == '#') {
                targetFile = _files[_activeFileIndex].name;
              }

              // Merge existing query params if any
              Map<String, dynamic> getData = Map.from(uri.queryParameters);

              if (method == 'POST') {
                _executePhp(
                  formData: formData,
                  getData: getData.isNotEmpty ? getData : null,
                  entryPoint: targetFile,
                );
              } else {
                // For GET forms, browser normally replaces query params with form data
                // but here we might want to merge or prioritize formData.
                _executePhp(getData: formData, entryPoint: targetFile);
              }
            } else if (action == 'link_click') {
              final String urlStr = msgData['url'];
              final uri = Uri.parse(urlStr);
              String targetFile = uri.path;
              if (targetFile.startsWith('/'))
                targetFile = targetFile.substring(1);
              if (targetFile.isEmpty) {
                targetFile = _files[_activeFileIndex].name;
              }

              _executePhp(
                entryPoint: targetFile,
                getData: uri.queryParameters.isNotEmpty
                    ? uri.queryParameters
                    : null,
              );
            }
          } catch (e) {
            print("Error parsing bridge message: $e");
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _urlBarController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _resolveContextPath() async {
    // On Web, we can't crawl directories easily.
    // We rely on AssetManifest.json to find files under assets/www
    if (widget.contextId == null) return;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      // DEBUG: Print all manifest keys to help diagnosis
      if (widget.contextId != null) {
        print("DEBUG: Context ID: '${widget.contextId}'");
        print(
          "DEBUG: Manifest Keys Sample (first 10): ${assets.take(10).toList()}",
        );
        // Check for any key containing 'www'
        final wwwKeys = assets.where((k) => k.contains('assets/www')).toList();
        print("DEBUG: Total keys under assets/www: ${wwwKeys.length}");
        if (wwwKeys.isNotEmpty) {
          print("DEBUG: First 5 www keys: ${wwwKeys.take(5).toList()}");
        } else {
          print("DEBUG: NO KEYS FOUND UNDER assets/www!");
        }
      }

      final rawName = widget.contextId!;
      // Simple strict match check
      final strictPath = 'assets/www/$rawName';

      // Check if any key starts with this path (decode for space handling)
      print("DEBUG WEB: Searching for strict path: '$strictPath'");
      bool hasStrict = assets.any((key) {
        final decoded = Uri.decodeFull(key);
        return decoded.startsWith(strictPath);
      });
      if (hasStrict) {
        // Find the actual encoded path to use as dirPath
        final matchKey = assets.firstWhere((key) {
          final decoded = Uri.decodeFull(key);
          return decoded.startsWith(strictPath);
        });

        // We want the directory part only
        final lastSlash = matchKey.lastIndexOf('/');
        if (lastSlash != -1) {
          _resolvedContextPath = matchKey.substring(0, lastSlash);
        } else {
          _resolvedContextPath = matchKey;
        }
        print("DEBUG WEB: STRICT MATCH FOUND: $_resolvedContextPath");
        return;
      }

      // Fuzzy match logic similar to mobile but iterating manifest keys
      // This is expensive if manifest is huge, but necessary.
      // Group assets by folder under assets/www
      final wwwAssets = assets.where((k) => k.startsWith('assets/www/'));
      final folders = <String>{};
      for (var asset in wwwAssets) {
        final parts = asset.split('/');
        if (parts.length > 2) {
          // assets/www/FolderName/...
          folders.add(parts[2]);
        }
      }

      final cleanRaw = Uri.decodeFull(
        rawName,
      ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      print("DEBUG: looking for clean raw: '$cleanRaw'");

      for (var folder in folders) {
        // Decode the folder name from manifest too, just in case
        final decodedFolder = Uri.decodeFull(folder);
        final cleanFolder = decodedFolder.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

        // print("DEBUG: comparing entry: '$decodedFolder' -> '$cleanFolder'");

        if (cleanFolder == cleanRaw) {
          _resolvedContextPath = 'assets/www/$folder';
          print("DEBUG: Matched! Resolved path: $_resolvedContextPath");
          return;
        }

        // 2. Containment Match
        if (cleanFolder.contains(cleanRaw) || cleanRaw.contains(cleanFolder)) {
          _resolvedContextPath = 'assets/www/$folder';
          print("DEBUG: Containment Match Found: $folder");
          return;
        }
      }
    } catch (e) {
      print("Error resolving web context: $e");
    }

    if (_resolvedContextPath == null && mounted) {
      // Show debug warning to user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Warning: Could not find assets for '${widget.contextId}'. check console.",
            ),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: "Retry",
              onPressed: () => _resolveContextPath(),
            ),
          ),
        );
      });
    }
  }

  Future<void> _loadContextAssets() async {
    if (_resolvedContextPath == null) return;
    final dirPath = _resolvedContextPath!;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      final assets = allAssets.where((k) => k.startsWith('$dirPath/'));

      List<CodeFile> loadedCandidates = [];
      String? detectedRealName;

      for (var assetPath in assets) {
        // Skip binaries
        final lPath = assetPath.toLowerCase();
        if (lPath.endsWith('.png') ||
            lPath.endsWith('.jpg') ||
            lPath.endsWith('.jpeg') ||
            lPath.endsWith('.gif') ||
            lPath.endsWith('.ico') ||
            lPath.endsWith('.pdf') ||
            lPath.endsWith('.json')) {
          continue;
        }

        final content = await rootBundle.loadString(assetPath);

        // Calculate relative name (decode for rules matching)
        String relativeName = Uri.decodeFull(assetPath);
        final decodedDirPath = Uri.decodeFull(dirPath);
        if (relativeName.startsWith('$decodedDirPath/')) {
          relativeName = relativeName.substring(decodedDirPath.length + 1);
        }

        if (detectedRealName == null) {
          // Normalise for comparison (trim, line endings)
          final normContent = content.replaceAll('\r\n', '\n').trim();
          final normInitial = _files[0].content.replaceAll('\r\n', '\n').trim();
          if (normContent == normInitial) {
            detectedRealName = relativeName;
            print(
              "DEBUG WEB: Detected real name by content: $detectedRealName",
            );
          }
        }

        loadedCandidates.add(CodeFile(name: relativeName, content: content));
      }

      // 2. Identify and Parse Visibility Rules
      Set<String>? allowedFiles;
      Set<String> privateFiles = {};
      Set<String> allClaimedFiles = {};

      final String decodedDirPath = Uri.decodeFull(dirPath);
      final visibleFileAsset = assets.firstWhere((k) {
        final decoded = Uri.decodeFull(k);
        return decoded == '$decodedDirPath/visible_files.json' ||
            decoded == '$decodedDirPath/visible.json';
      }, orElse: () => '');

      print("DEBUG WEB: visibleFileAsset found: '$visibleFileAsset'");
      if (visibleFileAsset.isNotEmpty) {
        try {
          final content = await rootBundle.loadString(visibleFileAsset);
          final Map<String, dynamic> json = jsonDecode(content);

          final effectiveEntryName = (detectedRealName ?? _files[0].name)
              .trim()
              .toLowerCase();
          print(
            "DEBUG WEB: effectiveEntryName (normalized): '$effectiveEntryName'",
          );

          Map<String, dynamic> rules = {};
          if (json.containsKey('rules')) {
            rules = Map<String, dynamic>.from(json['rules']);
          } else if (!json.containsKey('_private')) {
            // If it has neither 'rules' nor '_private', the root is the rules
            rules = json;
          }

          // Case-insensitive / Trimmed search
          String? matchKey;
          for (var k in rules.keys) {
            if (k.toString().trim().toLowerCase() == effectiveEntryName) {
              matchKey = k.toString();
              break;
            }
          }

          if (matchKey != null) {
            print("DEBUG WEB: Rule found for '$matchKey'");
            final dynamic allowed = rules[matchKey];
            if (allowed is List) {
              final allowedSet = allowed
                  .map((e) => e.toString().trim())
                  .toSet();
              allowedSet.add(effectiveEntryName);
              allowedSet.add(matchKey.trim());
              allowedFiles = allowedSet;
              print("DEBUG WEB: Whitelist applied: $allowedFiles");
            }
          } else {
            print("DEBUG WEB: No whitelist rule for '$effectiveEntryName'");
          }

          // Collect all claimed files for Implicit Privacy
          rules.forEach((key, value) {
            if (value is List) {
              allClaimedFiles.addAll(value.map((e) => e.toString().trim()));
            }
          });

          // Read _private (Always at root)
          if (json.containsKey('_private')) {
            final List<dynamic> private = json['_private'];
            privateFiles = private.map((e) => e.toString().trim()).toSet();
          }
        } catch (e) {
          print("Error parsing web visibility rules: $e");
        }
      }

      // 3. Update state with filtered files
      if (!mounted) return;
      setState(() {
        if (detectedRealName != null) {
          _files[0].name = detectedRealName;
        }

        for (var candidate in loadedCandidates) {
          final name = candidate.name.trim();
          if (name == _files[0].name) continue;
          if (_files.any((f) => f.name == name)) continue;

          // Apply Visibility Logic
          if (allowedFiles != null) {
            // Rule 1: Strict Whitelist for this entry point
            if (!allowedFiles.contains(name)) {
              print("DEBUG WEB: Hiding '$name' (Not in whitelist)");
              continue;
            }
          } else {
            // Rule 2: Implicit Privacy / Default Show
            if (privateFiles.contains(name)) {
              print("DEBUG WEB: Hiding '$name' (Private)");
              continue;
            }
            if (allClaimedFiles.contains(name)) {
              print("DEBUG WEB: Hiding '$name' (Claimed by another block)");
              continue;
            }
          }

          _files.add(candidate);
        }
      });
    } catch (e) {
      print("Error loading web context assets: $e");
    }
  }

  void _onCodeChanged() {
    if (_activeFileIndex < _files.length) {
      if (_files[_activeFileIndex].content != _codeController.text) {
        _files[_activeFileIndex].content = _codeController.text;
        // No auto-save on web (read-only mostly)
      }
    }
  }

  void _switchTab(int index) {
    if (index == _activeFileIndex) return;
    setState(() {
      _activeFileIndex = index;
      _codeController.text = _files[index].content;
    });
  }

  Future<void> _executePhp({
    Map<String, dynamic>? formData,
    Map<String, dynamic>? getData,
    String? entryPoint,
  }) async {
    final currentFile = _files[_activeFileIndex];
    final targetFileName = entryPoint ?? currentFile.name;

    // Prepare files payload
    final filesPayload = _files
        .map((f) => {'name': f.name, 'content': f.content})
        .toList();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/run-code');

      print("DEBUG WEB RUN: Sending request to $url");
      print(
        "DEBUG WEB RUN: Context: ${widget.contextId}, File: $targetFileName",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': (targetFileName == currentFile.name)
              ? currentFile.content
              : null,
          'files': filesPayload,
          'entry_point': targetFileName,
          'context_id': widget.contextId,
          'php_session_id': _webSessionId,
          'form_data': formData,
          'get_data': getData,
        }),
      );

      print("DEBUG WEB RUN: Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final output = data['output'] ?? '';

        // Wrap output with JS Bridge
        final wrappedOutput = _wrapHtmlWeb(output);

        // Load output into WebView
        _webViewController?.loadData(
          data: wrappedOutput,
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri(
            '${ApiConstants.domain}/',
          ), // Set Base URL for relative links
        );
      } else {
        _showWebWarning('Execution Failed: ${response.statusCode}');
        _webViewController?.loadData(
          data:
              '<h3 style="color:red">Execution Error: ${response.statusCode}</h3><pre>${response.body}</pre>',
          mimeType: 'text/html',
          encoding: 'utf-8',
        );
      }
    } catch (e) {
      print("DEBUG WEB RUN ERROR: $e");
      _showWebWarning('Error executing PHP: $e');
      _webViewController?.loadData(
        data: '<h3 style="color:red">Client Error</h3><pre>$e</pre>',
        mimeType: 'text/html',
        encoding: 'utf-8',
      );
    }
  }

  String _wrapHtmlWeb(String content) {
    if (!content.contains('<html') && !content.contains('<body')) {
      content = '<body>$content</body>';
    }

    final String bridgeScript = r'''
<script>
(function() {
  console.log("PHP Web Bridge: Initializing...");
  
  function sendToFlutter(action, data) {
    var msg = { action: action, data: data };
    var bridgeMsg = 'FLUTTER_WEB_BRIDGE:' + JSON.stringify(msg);
    if (window.parent !== window) {
       window.parent.postMessage(bridgeMsg, '*');
    }
    console.log(bridgeMsg);
  }

  // Intercept forms
  document.addEventListener('submit', function(e) {
    var form = e.target;
    // Check if it's a PHP target
    var action = form.getAttribute('action') || '';
    if (action.endsWith('.php') || action === '' || action === '#') {
       e.preventDefault();
       var formData = {};
       var formObj = new FormData(form);
       formObj.forEach(function(value, key) {
          formData[key] = value;
       });
       
       console.log("PHP Web Bridge: Intercepted Form Submit to " + action);
       sendToFlutter('form_submit', {
          url: action,
          method: form.method ? form.method.toUpperCase() : 'GET',
          formData: formData
       });
    }
  });

  // Intercept links
  document.addEventListener('click', function(e) {
    var link = e.target.closest('a');
    if (link && link.getAttribute('href')) {
      var href = link.getAttribute('href');
      // Match .php followed by ?, #, or end of string
      if (/\.php(\?|#|$)/i.test(href) && !href.startsWith('http')) {
        e.preventDefault();
        console.log("PHP Web Bridge: Intercepted Link Click to " + href);
        sendToFlutter('link_click', { url: href });
      }
    }
  });
})();
</script>
''';

    if (content.contains('</body>')) {
      return content.replaceFirst('</body>', '$bridgeScript</body>');
    } else {
      return content + bridgeScript;
    }
  }

  void _runCode() {
    // On Web, we can't run PHP.
    // If it's HTML/JS/CSS, we can load it into the iframe/webview.
    final currentFile = _files[_activeFileIndex];
    if (currentFile.name.endsWith('.php')) {
      _executePhp();
      return;
    }

    String contentToLoad = currentFile.content;
    _webViewController?.loadData(
      data: contentToLoad,
      mimeType: 'text/html',
      encoding: 'utf-8',
    );
  }

  void _showWebWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- NEW FILE / RENAME / DELETE (Stubbed for Web UI consistency) ---
  void _addNewFile() {
    _showWebWarning("File creation not persistent on Web.");
    // We could implement in-memory add for playground feel
  }

  void _renameFile(int index) {
    _showWebWarning("File renaming not persistent on Web.");
  }

  void _deleteFile(int index) {
    _showWebWarning("File deletion not persistent on Web.");
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(label: widget.topic),
            BreadcrumbItem(label: widget.noteTitle),
            const BreadcrumbItem(label: 'Run Code'),
          ],
        ),
        backgroundColor: context
            .getBrandColorForTopic(widget.topic)
            .withOpacity(0.2),
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
                        // Add File Button (Stubbed)
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
                                    readOnly: true, // Readonly on web fake env
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                        bottom: 2,
                                      ),
                                      hintText: "Preview",
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
                      key: ValueKey('webview_${widget.contextId}'),
                      initialSettings: InAppWebViewSettings(
                        isInspectable: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                      ),
                      onWebViewCreated: (controller) async {
                        _webViewController = controller;
                      },
                      onTitleChanged: (controller, title) {
                        if (mounted && title != null && title.isNotEmpty) {
                          setState(() => _browserTitle = title);
                        }
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
