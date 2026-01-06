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
import 'package:code_play/api/note_api.dart';
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
  Timer? _debounceTimer;

  String _browserTitle = "Preview";
  late String _webSessionId;
  StreamSubscription? _messageSubscription;

  String? _resolvedContextPath;
  final Map<String, String> _bundledLibraries = {};
  final Map<String, String> _virtualAssets = {};

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

    _loadBundledLibraries();
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

      // Alias common minified/CDN names to our bundled content
      _bundledLibraries['math.min.js'] = _bundledLibraries['math.js']!;
      _bundledLibraries['date-min.js'] = _bundledLibraries['date.js']!;
      _bundledLibraries['date.min.js'] = _bundledLibraries['date.js']!;

      print("Libraries loaded successfully (Web)");
    } catch (e) {
      print("Error loading libraries (Web): $e");
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _urlBarController.dispose();
    _messageSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- 2. Context Resolution (Server-First) ---
  Future<void> _resolveContextPath() async {
    if (widget.contextId == null) return;

    final rawName = widget.contextId!;
    // Default path on backend after sync: public/assets/www/<ContextID>
    // We assume strict structure matching SyncAssetsCommand.
    // However, the folder name might differ slightly (encoded/spaces),
    // but the backend sync command uses the EXACT folder name from seed_data.
    // The ContextID passed here usually comes from the navigation structure.

    // We try to verify if the path exists via API using a probe request to visible_files.json
    final probePath = 'assets/www/$rawName/visible_files.json';

    // If we can fetch this, we are good.
    // If not, we might need to fallback.
    // For now, we set a provisional path.
    _resolvedContextPath = 'assets/www/$rawName';

    print(
      "DEBUG WEB: Resolved provisional context path: $_resolvedContextPath",
    );

    // We can also double check with AssetManifest for local fallback
    // (This ensures we don't break offline or fully local usage if applicable)
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      final strictPath = 'assets/www/$rawName';
      bool hasStrict = assets.any(
        (k) => Uri.decodeFull(k).startsWith(strictPath),
      );

      if (!hasStrict) {
        // Attempt Fuzzy Match only if strict failed locally
        final wwwAssets = assets.where((k) => k.startsWith('assets/www/'));
        final folders = <String>{};
        for (var asset in wwwAssets) {
          final parts = asset.split('/');
          if (parts.length > 2) folders.add(parts[2]);
        }
        final cleanRaw = Uri.decodeFull(
          rawName,
        ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (var folder in folders) {
          final decodedFolder = Uri.decodeFull(folder);
          final cleanFolder = decodedFolder.toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          if (cleanFolder == cleanRaw) {
            // Update to the *exact* folder name used in assets
            _resolvedContextPath = 'assets/www/$decodedFolder';
            print(
              "DEBUG WEB: Fuzzy Resolved context path: $_resolvedContextPath",
            );
            break;
          }
        }
      }
    } catch (_) {}
  }

  // --- 3. Asset Loading (Server-First) ---
  Future<void> _loadContextAssets() async {
    if (_resolvedContextPath == null) return;
    _showWebWarning("Loading assets...");

    // Attempt to load from server first.
    await _loadAssetsFromServer();
  }

  Map<String, dynamic>? _visibleFilesManifest;

  Future<void> _loadAssetsFromServer() async {
    // 1. Fetch visible_files.json
    try {
      final path = '$_resolvedContextPath/visible_files.json';
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/get-file?path=$path&t=${DateTime.now().millisecondsSinceEpoch}',
      );
      print("DEBUG WEB: Fetching manifest from $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        _visibleFilesManifest = jsonDecode(response.body);
        print("DEBUG WEB: Manifest loaded: $_visibleFilesManifest");
      } else {
        print("DEBUG WEB: Manifest fetch failed (${response.statusCode})");
      }
    } catch (e) {
      print("DEBUG WEB: Error fetching manifest: $e");
    }

    // 2. Determine files to load
    List<String> filesToLoad = [];

    // Group-Based Logic
    if (widget.initialFileName != null &&
        _visibleFilesManifest != null &&
        _visibleFilesManifest!.containsKey(widget.initialFileName)) {
      final group = _visibleFilesManifest![widget.initialFileName];
      if (group is List) {
        filesToLoad = group.map((e) => e.toString()).toList();
        print(
          "DEBUG WEB: Loading Group [${widget.initialFileName}]: $filesToLoad",
        );
      }
    }
    // Legacy Logic
    else if (_visibleFilesManifest != null) {
      Set<String> uniqueFiles = {};
      _visibleFilesManifest!.forEach((key, value) {
        if (value is List) {
          uniqueFiles.addAll(value.map((e) => e.toString()));
        } else {
          uniqueFiles.add(key);
        }
      });
      filesToLoad = uniqueFiles.toList();
      print("DEBUG WEB: Loading All Manifest Files: $filesToLoad");
    }

    // 3. Fetch each file content
    if (filesToLoad.isNotEmpty) {
      List<CodeFile> loadedFiles = [];

      for (final fileName in filesToLoad) {
        final filePath = '$_resolvedContextPath/$fileName';
        final fileUri = Uri.parse(
          '${ApiConstants.baseUrl}/get-file?path=$filePath&t=${DateTime.now().millisecondsSinceEpoch}',
        );

        try {
          final resp = await http.get(fileUri);
          if (resp.statusCode == 200) {
            loadedFiles.add(CodeFile(name: fileName, content: resp.body));
          } else {
            print(
              "DEBUG WEB: Failed to load file '$fileName': ${resp.statusCode}",
            );
          }
        } catch (e) {
          // Ignore error
        }
      }

      if (loadedFiles.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _files = loadedFiles;
          if (widget.initialFileName != null) {
            final idx = _files.indexWhere(
              (f) => f.name == widget.initialFileName,
            );
            if (idx != -1) _activeFileIndex = idx;
          }
          if (_activeFileIndex >= _files.length) _activeFileIndex = 0;

          _codeController.text = _files[_activeFileIndex].content;
        });
        _showWebWarning("Assets Loaded (Server).");
        return;
      }
    }

    // 4. Fallback if Server failed or returned nothing
    print("DEBUG WEB: Server assets empty, falling back to local bundle.");
    await _loadAssetsFromBundle();
  }

  Future<void> _loadAssetsFromBundle() async {
    if (_resolvedContextPath == null) return;
    final dirPath = _resolvedContextPath!;

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();
      final assets = allAssets.where((k) => k.startsWith('$dirPath/'));

      List<CodeFile> loadedCandidates = [];
      String? detectedRealName;

      for (var assetPath in assets) {
        final lPath = assetPath.toLowerCase();
        if (lPath.endsWith('.png') ||
            lPath.endsWith('.jpg') ||
            lPath.endsWith('.jpeg') ||
            lPath.endsWith('.gif') ||
            lPath.endsWith('.ico') ||
            lPath.endsWith('.pdf') ||
            lPath.endsWith('.json'))
          continue;

        final decodedAssetPath = Uri.decodeFull(assetPath);
        final content = await rootBundle.loadString(decodedAssetPath);

        String relativeName = decodedAssetPath;
        final decodedDirPath = Uri.decodeFull(dirPath);
        if (relativeName.startsWith('$decodedDirPath/')) {
          relativeName = relativeName.substring(decodedDirPath.length + 1);
        }

        if (detectedRealName == null) {
          final normContent = content.replaceAll('\r\n', '\n').trim();
          final normInitial = _files[0].content.replaceAll('\r\n', '\n').trim();
          if (normContent == normInitial) detectedRealName = relativeName;
        }
        loadedCandidates.add(CodeFile(name: relativeName, content: content));
      }

      if (!mounted) return;

      setState(() {
        if (detectedRealName != null) _files[0].name = detectedRealName;
        for (var c in loadedCandidates) {
          if (!_files.any((f) => f.name == c.name)) {
            _files.add(c);
          }
        }
      });
      _showWebWarning("Loaded local assets (Offline Mode)");
    } catch (e) {
      print("Error loading bundle assets: $e");
    }
  }

  Future<void> _executePhp({
    Map<String, dynamic>? formData,
    Map<String, dynamic>? getData,
    String? entryPoint,
  }) async {
    final currentFile = _files[_activeFileIndex];
    final targetFileName = entryPoint ?? currentFile.name;

    final filesPayload = _files
        .map((f) => {'name': f.name, 'content': f.content})
        .toList();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/run-code');
      print("DEBUG WEB RUN: Sending request to $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': (targetFileName == currentFile.name)
              ? currentFile.content
              : null,
          'files': filesPayload,
          'entry_point': targetFileName,
          'context_id': _resolvedContextPath != null
              ? _resolvedContextPath!.replaceFirst('assets/www/', '')
              : widget.contextId,
          'php_session_id': _webSessionId,
          'form_data': formData,
          'get_data': getData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final output = data['output'] ?? '';
        final files = data['files'] as List<dynamic>?;
        if (files != null) {
          _virtualAssets.clear();
          for (var f in files) {
            final name = f['name'] as String;
            final content = f['content'] as String;
            final isBinary = f['is_binary'] == true;
            if (isBinary) {
              String mime = 'application/octet-stream';
              if (name.endsWith('.png'))
                mime = 'image/png';
              else if (name.endsWith('.jpg') || name.endsWith('.jpeg'))
                mime = 'image/jpeg';
              else if (name.endsWith('.gif'))
                mime = 'image/gif';
              _virtualAssets[name] = 'data:$mime;base64,$content';
            }
          }
        }
        final wrappedOutput = _wrapHtmlWeb(output);
        _webViewController?.loadData(
          data: wrappedOutput,
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri('${ApiConstants.domain}/'),
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
      _showWebWarning('Client Error: $e');
    }
  }

  String _wrapHtmlWeb(String content) {
    if (!content.contains('<html') && !content.contains('<body')) {
      content = '<body>$content</body>';
    }

    final String bridgeScript = r'''
<script>
(function() {
  function sendToFlutter(action, data) {
    var msg = { action: action, data: data };
    var bridgeMsg = 'FLUTTER_WEB_BRIDGE:' + JSON.stringify(msg);
    if (window.parent !== window) window.parent.postMessage(bridgeMsg, '*');
  }
  document.addEventListener('submit', function(e) {
    var form = e.target;
    var action = form.getAttribute('action') || '';
    if (action.endsWith('.php') || action === '' || action === '#') {
       e.preventDefault();
       var formData = {};
       new FormData(form).forEach(function(v, k) { formData[k] = v; });
       sendToFlutter('form_submit', { url: action, method: form.method ? form.method.toUpperCase() : 'GET', formData: formData });
    }
  });
  document.addEventListener('click', function(e) {
    var link = e.target.closest('a');
    if (link && link.getAttribute('href')) {
      var href = link.getAttribute('href');
      if (/\.php(\?|#|$)/i.test(href) && !href.startsWith('http')) {
        e.preventDefault();
        sendToFlutter('link_click', { url: href });
      }
    }
  });
})();
</script>
''';

    if (content.contains('</body>')) {
      content = content.replaceFirst('</body>', '$bridgeScript</body>');
    } else {
      content = content + bridgeScript;
    }

    // Library Injection
    final scriptRegex = RegExp(
      r'''<script\b[^>]*\bsrc=["'](?:.*?/)?([\w\d_.-]+\.js)["'][^>]*>.*?</\s*script>''',
      caseSensitive: false,
      dotAll: true,
    );
    final selfClosingRegex = RegExp(
      r'''<script\b[^>]*\bsrc=["'](?:.*?/)?([\w\d_.-]+\.js)["'][^>]*/>''',
      caseSensitive: false,
    );

    content = content.replaceAllMapped(scriptRegex, (match) {
      String filename = match.group(1) ?? "";
      if (_bundledLibraries.containsKey(filename)) {
        return '<script>\n/* Injected $filename */\n${_bundledLibraries[filename]}\n</script>';
      }
      return match.group(0)!;
    });

    content = content.replaceAllMapped(selfClosingRegex, (match) {
      String filename = match.group(1) ?? "";
      if (_bundledLibraries.containsKey(filename)) {
        return '<script>\n/* Injected $filename */\n${_bundledLibraries[filename]}\n</script>';
      }
      return match.group(0)!;
    });

    // Image Injection
    content = content.replaceAllMapped(
      RegExp(
        r'<img\s+[^>]*src=["\u0027]([^"\u0027]+)["\u0027][^>]*>',
        caseSensitive: false,
      ),
      (match) {
        final fullTag = match.group(0)!;
        final src = match.group(1)!;
        final filename = src.split('/').last;
        if (_virtualAssets.containsKey(filename)) {
          return fullTag.replaceFirst(src, _virtualAssets[filename]!);
        }
        return fullTag;
      },
    );

    return content;
  }

  void _onCodeChanged() {
    if (_activeFileIndex < _files.length) {
      if (_files[_activeFileIndex].content != _codeController.text) {
        _files[_activeFileIndex].content = _codeController.text;

        // Auto-save logic
        if (widget.isAdmin) {
          if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
            _saveCurrentFile(isAutoSave: true);
          });
        }
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

  void _runCode() {
    // On Web, we can't run PHP.
    // If it's HTML/JS/CSS, we can load it into the iframe/webview.
    final currentFile = _files[_activeFileIndex];
    if (currentFile.name.endsWith('.php')) {
      _executePhp();
      return;
    }

    String contentToLoad = currentFile.content;

    // Apply wrapper (Bridge + Library Injection)
    final wrappedOutput = _wrapHtmlWeb(contentToLoad);

    _webViewController?.loadData(
      data: wrappedOutput,
      mimeType: 'text/html',
      encoding: 'utf-8',
    );
  }

  // Implemented as internal helper
  Future<void> _saveCurrentFile({bool isAutoSave = false}) async {
    if (!widget.isAdmin || widget.contextId == null) {
      if (!isAutoSave)
        _showWebWarning("Save not available (Read-only or No Context)");
      return;
    }

    final currentFile = _files[_activeFileIndex];
    if (!isAutoSave) _showWebWarning("Saving '${currentFile.name}'...");

    try {
      await NoteApi().uploadFile(
        noteId: widget.contextId!,
        fileName: currentFile.name,
        content: currentFile.content,
      );
      if (!isAutoSave) {
        _showWebWarning("File Saved!");
      }
      print(
        "DEBUG: '${currentFile.name}' saved successfully (AutoSave: $isAutoSave).",
      );
    } catch (e) {
      print("DEBUG: Save Error: $e");
      // Always show error, even on auto-save
      _showWebWarning("Save Failed: $e");
    }
  }

  // --- NEW FILE / RENAME / DELETE (Stubbed for Web UI consistency) ---

  bool _isDialogOpen = false;

  // --- NEW FILE / RENAME / DELETE ---
  Future<void> _addNewFile() async {
    final TextEditingController filenameController = TextEditingController();

    setState(() => _isDialogOpen = true);
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("New File"),
          content: TextField(
            controller: filenameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Filename",
              hintText: "e.g. style.css",
            ),
            onSubmitted: (_) =>
                _handleCreateFile(dialogContext, filenameController.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () =>
                  _handleCreateFile(dialogContext, filenameController.text),
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
    if (mounted) setState(() => _isDialogOpen = false);
  }

  Future<void> _handleCreateFile(
    BuildContext dialogContext,
    String rawName,
  ) async {
    // ... implementation logic remains the same, but we need to ensure dialog is closed first
    // Actually Navigator.pop is called here.
    // So the await showDialog returns.
    // We should probably just let _addNewFile handle the state reset.
    // Logic:
    // 1. User clicks Create -> _handleCreateFile called.
    // 2. _handleCreateFile calls Navigator.pop
    // 3. showDialog future completes.
    // 4. _addNewFile resets state.
    // Checks out.

    final filename = rawName.trim();
    if (filename.isEmpty) {
      _showWebWarning("Please enter a filename");
      return;
    }

    Navigator.pop(dialogContext); // Close dialog

    print("DEBUG: Creating new file: $filename");
    setState(() {
      _files.add(CodeFile(name: filename, content: ""));
      _activeFileIndex = _files.length - 1;
      _codeController.text = "";
    });

    // Admin Sync
    if (widget.isAdmin && widget.contextId != null) {
      _showWebWarning(
        "Syncing '$filename' to backend (NoteID: ${widget.contextId})...",
      );
      print("DEBUG: Syncing to NoteID: ${widget.contextId}");
      try {
        await NoteApi().uploadFile(
          noteId: widget.contextId!,
          fileName: filename,
          content: "",
        );
        _showWebWarning("File Synced!");

        // Auto-update visible_files.json
        await _updateVisibleFilesManifest();
      } catch (e) {
        print("DEBUG: Sync Error: $e");
        _showWebWarning("Sync Failed: $e");
      }
    }
  }

  // ...
  // ...
  void _deleteFile(int index) async {
    if (!widget.isAdmin) {
      _showWebWarning("Only Admins can delete files.");
      return;
    }

    final fileName = _files[index].name;

    setState(() => _isDialogOpen = true);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete '$fileName'?"),
        content: const Text(
          "This will PERMANENTLY delete the file from all locations (Web, Storage, Seed Data). This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteFile(index);
            },
            child: const Text(
              "Delete Permanently",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _isDialogOpen = false);
  }

  Future<void> _updateVisibleFilesManifest() async {
    if (_resolvedContextPath == null) return;

    _showWebWarning("Updating visible_files.json...");
    try {
      // 1. Fetch existing manifest
      // Use API endpoint to bypass CORS
      final apiUri = Uri.parse('${ApiConstants.baseUrl}/get-file');
      final url = apiUri.replace(
        queryParameters: {'path': '$_resolvedContextPath/visible_files.json'},
      );
      print("DEBUG: Fetching manifest from API: $url");

      final response = await http.get(url);
      Map<String, dynamic> manifest = {};

      if (response.statusCode == 200) {
        try {
          manifest = jsonDecode(response.body);
        } catch (e) {
          print("Error decoding existing manifest: $e");
        }
      } else if (response.statusCode == 404) {
        print("Manifest not found, creating new.");
      } else {
        // CRITICAL FIX: If 500 or other error, DO NOT OVERWRITE.
        print("Server error fetching manifest: ${response.statusCode}");
        print("Response body: ${response.body}");
        _showWebWarning(
          "Manifest Fetch Error: ${response.statusCode} - ${response.body}",
        );
        return;
      }

      // 2. Update Entry
      // Key: The "Main File" (entry point)
      // If initialized via 'src=Main.php', usage is typically mapped to that key.
      // If we don't have a specific key, we might default to the first file's name.
      String key = widget.initialFileName ?? _files[0].name;

      // Filter list to names only
      final fileList = _files.map((f) => f.name).toList();

      // Update or Add
      manifest[key] = fileList;

      // 3. Upload back
      await NoteApi().uploadFile(
        noteId: widget.contextId!,
        fileName: 'visible_files.json',
        content: const JsonEncoder.withIndent('    ').convert(manifest),
      );

      _showWebWarning("Manifest Updated!");
      print("DEBUG: visible_files.json updated for key '$key'");
    } catch (e) {
      print("Error updating manifest: $e");
      _showWebWarning("Manifest Update Failed: $e");
    }
  }

  void _showWebWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _renameFile(int index) {
    _showWebWarning("File renaming not persistent on Web.");
  }

  Future<void> _handleDeleteFile(int index) async {
    final fileName = _files[index].name;
    final path = '$_resolvedContextPath/$fileName';

    _showWebWarning("Deleting '$fileName'...");
    print("DEBUG WEB: Deleting file at $path");

    try {
      // 1. Call Backend Delete API
      final uri = Uri.parse('${ApiConstants.baseUrl}/delete-file');
      final response = await http.post(uri, body: {'path': path});

      if (response.statusCode == 200) {
        print("DEBUG WEB: Delete Success: ${response.body}");

        setState(() {
          _files.removeAt(index);
          if (_activeFileIndex >= _files.length) {
            _activeFileIndex = _files.isEmpty ? 0 : _files.length - 1;
          }
          if (_files.isNotEmpty) {
            _codeController.text = _files[_activeFileIndex].content;
          } else {
            _codeController.text = "";
          }
        });

        _showWebWarning("File Deleted Successfully.");

        // 2. Update Manifest (Remove from list)
        await _updateVisibleFilesManifest();
      } else {
        print(
          "DEBUG WEB: Delete Failed: ${response.statusCode} - ${response.body}",
        );
        _showWebWarning("Delete Failed: ${response.body}");
      }
    } catch (e) {
      print("DEBUG WEB: Delete Error: $e");
      _showWebWarning("Error deleting file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: RunCodePageWeb BUILD called");
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
                    child: _isDialogOpen
                        ? Container(
                            color: Colors.white,
                            child: const Center(
                              child: Text(
                                "Interaction Paused (Dialog Open)",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : InAppWebView(
                            key: ValueKey('webview_${widget.contextId}'),
                            initialSettings: InAppWebViewSettings(
                              // ...
                              isInspectable: true,
                              mediaPlaybackRequiresUserGesture: false,
                              allowsInlineMediaPlayback: true,
                            ),
                            onWebViewCreated: (controller) async {
                              _webViewController = controller;
                            },
                            onTitleChanged: (controller, title) {
                              if (mounted &&
                                  title != null &&
                                  title.isNotEmpty) {
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
