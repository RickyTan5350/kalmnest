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

    _codeController = TextEditingController(text: _files[0].content);
    _codeController.addListener(_onCodeChanged);

    _resolveContextPath().then((_) {
      _loadContextAssets();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _urlBarController.dispose();
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

      // Check if any key starts with this path
      bool hasStrict = assets.any((key) => key.startsWith(strictPath));
      if (hasStrict) {
        _resolvedContextPath = strictPath;
        return;
      }

      // Fuzzy match logic with robust fallback
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

      String? matchedFolder;
      List<String> candidateFolders = [];

      for (var folder in folders) {
        final decodedFolder = Uri.decodeFull(folder);
        final cleanFolder = decodedFolder.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

        // 1. Exact Match
        if (cleanFolder == cleanRaw) {
          matchedFolder = folder;
          print("DEBUG: Exact Match Found: $folder");
          break;
        }

        // 2. Containment Match
        if (cleanFolder.contains(cleanRaw) || cleanRaw.contains(cleanFolder)) {
          matchedFolder = folder;
          print("DEBUG: Containment Match Found: $folder");
          break;
        }

        candidateFolders.add(folder);
      }

      // 3. Fallback: If no match but very similar (manual proximity or assume single result?)
      // Not implemented here to avoid false positives, but Containment usually catches "truncated" names.

      if (matchedFolder != null) {
        _resolvedContextPath = 'assets/www/$matchedFolder';
        print("DEBUG: Matched! Resolved path: $_resolvedContextPath");
        return;
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

        // Calculate relative name
        String relativeName = assetPath;
        if (relativeName.startsWith('$dirPath/')) {
          relativeName = relativeName.substring(dirPath.length + 1);
        }

        if (detectedRealName == null && content == _files[0].content) {
          detectedRealName = relativeName;
        }

        loadedCandidates.add(CodeFile(name: relativeName, content: content));
      }

      // 2. Identify and Parse Visibility Rules
      Set<String>? allowedFiles;
      Set<String> privateFiles = {};
      Set<String> allClaimedFiles = {};

      final visibleFileAsset = assets.firstWhere(
        (k) => k == '$dirPath/visible_files.json',
        orElse: () => '',
      );

      if (visibleFileAsset.isNotEmpty) {
        try {
          final content = await rootBundle.loadString(visibleFileAsset);
          final Map<String, dynamic> json = jsonDecode(content);

          final effectiveEntryName = detectedRealName ?? _files[0].name;

          // Read Rules
          if (json.containsKey('rules')) {
            final Map<String, dynamic> rules = json['rules'];
            if (detectedRealName != null &&
                rules.containsKey(effectiveEntryName)) {
              final List<dynamic> allowed = rules[effectiveEntryName];
              final allowedSet = allowed
                  .map((e) => e.toString().trim())
                  .toSet();
              allowedSet.add(effectiveEntryName);
              allowedFiles = allowedSet;
              print("DEBUG WEB: Whitelist applied: $allowedFiles");
            }

            // Collect all claimed files for Implicit Privacy
            rules.forEach((key, value) {
              if (value is List) {
                allClaimedFiles.addAll(value.map((e) => e.toString().trim()));
              }
            });
          }

          // Read _private
          if (json.containsKey('_private')) {
            final List<dynamic> private = json['_private'];
            privateFiles = private.map((e) => e.toString().trim()).toSet();
          }
        } catch (e) {
          print("Error parsing web visible_files.json: $e");
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

          print("DEBUG WEB: Adding visible tab: '$name'");
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

  Future<void> _executePhp() async {
    final currentFile = _files[_activeFileIndex];
    final phpSessionId =
        "web-session-${DateTime.now().millisecondsSinceEpoch}"; // Simple session ID for web

    // Prepare files payload
    final filesPayload = _files
        .map((f) => {'name': f.name, 'content': f.content})
        .toList();

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/run-code');

      print("DEBUG WEB RUN: Sending request to $url");
      print(
        "DEBUG WEB RUN: Context: ${widget.contextId}, File: ${currentFile.name}",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': currentFile.content,
          'files': filesPayload,
          'entry_point': currentFile.name,
          'context_id': widget.contextId, // Use context ID for assets
          'php_session_id': phpSessionId, // Optional persistence
        }),
      );

      print("DEBUG WEB RUN: Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final output = data['output'] ?? '';

        // Load output into WebView
        _webViewController?.loadData(
          data: output,
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri(
            '${ApiConstants.domain}/',
          ), // Set Base URL for relative links
        );
      } else {
        _showWebWarning('Execution Failed: ${response.statusCode}');
        // Show error in webview to be helpful
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

  void _runCode() {
    // On Web, we can't run PHP locally, but we can send it to backend!
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
