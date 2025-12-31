import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../../../constants/api_constants.dart';
import 'package:code_play/admin_teacher/services/breadcrumb_navigation.dart';
import 'package:code_play/utils/brand_color_extension.dart';

class CodeFile {
  String name;
  String content;
  CodeFile({required this.name, required this.content});
}

class RunCodePage extends StatefulWidget {
  final String initialCode;
  final String? contextId;
  final String? initialFileName;

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

  final String topic;
  final String noteTitle;
  final bool isAdmin;
  final Function(String oldName, String newName)? onFileRenamed;

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
  Timer? _debounceTimer; // For auto-saving

  String _browserTitle = "Preview";
  InAppLocalhostServer? _localhostServer;
  int _serverPort = 8080;
  String _output = "";
  final Completer<void> _serverReady = Completer<void>();
  String _phpSessionId = "";

  // Cache for your libraries
  final Map<String, String> _bundledLibraries = {};

  // Resolved path for the context directory (handles typos/spaces mismatch)
  String? _resolvedContextPath;

  // Cache for allowed files to prevent backend sync from re-adding hidden files
  Set<String>? _allowedFilesCache;

  @override
  void initState() {
    super.initState();
    _startLocalServer();

    // Initialize files - Default filename based on content
    // Initialize files - Default filename based on content
    String defaultName = widget.initialFileName ?? 'index.html';
    if (widget.initialFileName == null &&
        widget.initialCode.contains('<?php')) {
      defaultName = 'main.php';
    }

    _files = [CodeFile(name: defaultName, content: widget.initialCode)];
    _activeFileIndex = 0;

    // Generate a fixed session ID for this run session
    _phpSessionId =
        "sess-${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecond % 1000)}";

    _codeController = TextEditingController(text: _files[0].content);
    _codeController.addListener(_onCodeChanged);

    _updateTitleFromCode(widget.initialCode);

    // Load libraries in background
    _loadBundledLibraries();

    // Resolve context path, THEN load assets
    _resolveContextPath().then((_) {
      _loadContextAssets();
    });
  }

  Future<void> _resolveContextPath() async {
    if (widget.contextId == null) return;

    final rawName = widget.contextId!;
    // Standard path
    final strictPath = 'assets/www/$rawName';

    // Check if strict path exists
    try {
      if (await Directory(strictPath).exists()) {
        _resolvedContextPath = strictPath;
        print("DEBUG: Context Path Exact Match: $strictPath");
        return;
      }
    } catch (e) {
      // Ignore invalid path syntax (errno 123) and fall through to fuzzy match
    }

    // Try fuzzy match in assets/www
    try {
      final wwwDir = Directory('assets/www');
      if (await wwwDir.exists()) {
        final entities = wwwDir.listSync();
        for (var entity in entities) {
          if (entity is Directory) {
            // Get just the folder name and NORMALIZE whitespace (remove newlines/tabs)
            String folderName = entity.path.split(Platform.pathSeparator).last;
            if (folderName.trim().isEmpty)
              folderName = entity.path.split('/').last;

            // Replace any whitespace sequence (newline, tab, multi-space) with single space
            folderName = folderName.replaceAll(RegExp(r'\s+'), ' ').trim();

            // Compare ignoring spaces and case
            // print("DEBUG: Checking folder: '$folderName'");
            // Compare removing ALL whitespace (including \r \n) and case
            final cleanFolder = folderName
                .replaceAll(RegExp(r'\s+'), '')
                .toLowerCase();
            final cleanRaw = rawName
                .replaceAll(RegExp(r'\s+'), '')
                .toLowerCase();

            // print("DEBUG: Copy check: '$cleanFolder' vs '$cleanRaw'");

            if (cleanFolder == cleanRaw) {
              // Found a match!
              // Construct path with forward slashes for Asset usage
              // We need the RELATIVE path starting from assets/www
              _resolvedContextPath = 'assets/www/$folderName';
              print("DEBUG: Context Path Fuzzy Match: $_resolvedContextPath");
              return;
            }
          }
        }
      }
    } catch (e) {
      print("Error resolving context path: $e");
    }

    // If we failed to find a match, just use strict path (will likely fail later but consistent)
    if (_resolvedContextPath == null) {
      _resolvedContextPath = strictPath;
    }
  }

  Future<void> _loadContextAssets() async {
    if (_resolvedContextPath == null) return;

    // Use the resolved path
    final dirPath = _resolvedContextPath!;

    try {
      final dir = Directory(dirPath);
      // Check existence safely
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir
            .list(recursive: true)
            .toList();

        // 1. First Pass: Load all candidates into memory to find the "Real Name" of initial file
        List<CodeFile> loadedCandidates = [];
        String? detectedRealName;

        for (var entity in entities) {
          if (entity is File) {
            // SKIP BINARY FILES & JSON
            final lPath = entity.path.toLowerCase();
            if (lPath.endsWith('.png') ||
                lPath.endsWith('.jpg') ||
                lPath.endsWith('.jpeg') ||
                lPath.endsWith('.gif') ||
                lPath.endsWith('.ico') ||
                lPath.endsWith('.pdf') ||
                lPath.endsWith('.json')) {
              continue; // Skip these
            }

            final content = await entity.readAsString();
            // Relative path calculation
            String relativeName = entity.path.replaceAll(r'\', '/');
            final prefix = '$dirPath/'.replaceAll(r'\', '/');
            if (relativeName.startsWith(prefix)) {
              relativeName = relativeName.substring(prefix.length);
            } else if (relativeName.contains('/$dirPath/')) {
              relativeName = relativeName.split('/$dirPath/').last;
            }

            // Check match with initial code
            if (detectedRealName == null && content == _files[0].content) {
              detectedRealName = relativeName;
            }

            loadedCandidates.add(
              CodeFile(name: relativeName, content: content),
            );
          }
        }

        // 2. Update the initial file name if we found a match
        String effectiveEntryName = _files[0].name;
        if (detectedRealName != null) {
          effectiveEntryName = detectedRealName;
          // We can update the UI state for this later or now.
          // Let's do it in the final batch, but for logic we use effectiveEntryName.
        }

        // 3. Determine Allowed Files (Filtering)
        Set<String>? allowedFiles;
        Set<String> privateFiles = {};
        Set<String> allClaimedFiles = {}; // Implicit Privacy

        try {
          final visibleFile = File('$dirPath/visible_files.json');
          if (await visibleFile.exists()) {
            final content = await visibleFile.readAsString();
            final Map<String, dynamic> json = jsonDecode(content);

            // Read Rules
            if (json.containsKey('rules')) {
              final Map<String, dynamic> rules = json['rules'];
              // Only apply rule if we are SURE we matched the file on disk (Content Match)
              // This prevents "New" code blocks (which default to index.html) from inheriting
              // the tabs of the "Real" index.html.
              if (detectedRealName != null &&
                  rules.containsKey(effectiveEntryName)) {
                final List<dynamic> allowed = rules[effectiveEntryName];
                final allowedSet = allowed
                    .map((e) => e.toString().trim())
                    .toSet();
                allowedSet.add(effectiveEntryName); // Always keep self
                _allowedFilesCache = allowedSet;
                allowedFiles = allowedSet;
                print("DEBUG: Keeping only (Whitelist): $allowedFiles");
              } else if (rules.containsKey(effectiveEntryName)) {
                print(
                  "DEBUG: Skipping rule for '$effectiveEntryName' due to content mismatch (Isolation).",
                );
              }

              // Collect ALL claimed files for Implicit Privacy
              // If a file is claimed by ANY entry point, it should be hidden from others
              // unless specifically whitelisted (which is handled by Rule 1 above).
              rules.forEach((key, value) {
                if (value is List) {
                  allClaimedFiles.addAll(value.map((e) => e.toString().trim()));
                }
              });
              print("DEBUG: All Claimed Files: $allClaimedFiles");
            } else {
              // Legacy format support where root object IS the rules
              // Check if root keys look like filenames (contain dots) or start small
              // For now, assume if 'rules' missing, root might be rules, or just empty.
              if (json.containsKey(effectiveEntryName)) {
                // It's the old format
                final List<dynamic> allowed = json[effectiveEntryName];
                final allowedSet = allowed
                    .map((e) => e.toString().trim())
                    .toSet();
                allowedSet.add(effectiveEntryName);
                _allowedFilesCache = allowedSet;
                allowedFiles = allowedSet;
              }
              // Legacy Claimed collection (approximate since we don't know structure perfectly)
              // Assume keys are entry points
              json.forEach((key, value) {
                if (value is List) {
                  allClaimedFiles.addAll(value.map((e) => e.toString().trim()));
                }
              });
            }

            // Read _private
            if (json.containsKey('_private')) {
              final List<dynamic> private = json['_private'];
              privateFiles = private.map((e) => e.toString().trim()).toSet();
              print("DEBUG: Private files: $privateFiles");
            }
          }
        } catch (e) {
          print("Error parsing visible_files.json: $e");
        }

        // 4. Final Batch Update
        setState(() {
          // Update main file name if detected
          if (detectedRealName != null) {
            _files[0].name = detectedRealName;
          }

          // Add candidates ONLY if they adhere to the rules
          for (var candidate in loadedCandidates) {
            // Don't duplicate the main file (which is already in _files[0])
            if (candidate.name == _files[0].name) {
              print(
                "DEBUG: Candidate '${candidate.name}' SKIPPED (Duplicate/Main)",
              );
              continue;
            }
            ;
            if (_files.any((f) => f.name == candidate.name)) {
              print(
                "DEBUG: Candidate '${candidate.name}' SKIPPED (Already exists)",
              );
              continue;
            }
            ;

            // Apply filter
            if (allowedFiles != null) {
              // Rule 1: Strict Whitelist (if defined for this entry point)
              // NOTE: trim() is important for safety
              final isAllowed = allowedFiles.contains(candidate.name.trim());
              if (!isAllowed) {
                print(
                  "DEBUG: Candidate '${candidate.name}' REJECTED by Whitelist.",
                );
                continue;
              }
            } else {
              // Rule 2: Default "Show All" EXCEPT Private OR Claimed
              final candidateName = candidate.name.trim();
              final isPrivate = privateFiles.contains(candidateName);
              final isClaimed = allClaimedFiles.contains(candidateName);

              print(
                "DEBUG: Default Filter '$candidateName'. Private? $isPrivate. Claimed? $isClaimed",
              );

              if (isPrivate) {
                print(
                  "DEBUG: Candidate '$candidateName' HIDDEN (Private file).",
                );
                continue;
              }
              if (isClaimed) {
                print(
                  "DEBUG: Candidate '$candidateName' HIDDEN (Implicitly Claimed by another block).",
                );
                continue;
              }
            }

            print("DEBUG: Candidate '${candidate.name}' ACCEPTED.");
            _files.add(candidate);
          }
        });
      }
    } catch (e) {
      // Gracefully handle invalid paths, non-existent directories on some platforms, etc.
      print("Warning: Could not load context assets for '$dirPath': $e");
    }
  }

  void _onCodeChanged() {
    // Sync controller text to active file model
    if (_activeFileIndex < _files.length) {
      final currentFile = _files[_activeFileIndex];
      final newContent = _codeController.text;

      // Only act if content changed
      if (currentFile.content != newContent) {
        currentFile.content = newContent;

        // Auto-save logic for Admins
        if (widget.isAdmin) {
          if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
            _saveAssetFileContent(currentFile.name, currentFile.content);
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

  // --- FILE PERSISTENCE HELPERS (ADMIN ONLY) ---
  Future<void> _createAssetFile(String fileName) async {
    if (_resolvedContextPath == null) return;
    try {
      final file = File('$_resolvedContextPath/$fileName');
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(""); // Empty file
        print("DEBUG: Created asset file: ${file.path}");
      }
    } catch (e) {
      print("Error creating asset file: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error creating file: $e")));
      }
    }
  }

  Future<void> _renameAssetFile(String oldName, String newName) async {
    if (_resolvedContextPath == null) return;
    try {
      final oldFile = File('$_resolvedContextPath/$oldName');
      if (await oldFile.exists()) {
        await oldFile.rename('$_resolvedContextPath/$newName');
        print("DEBUG: Renamed asset file from $oldName to $newName");
      }
    } catch (e) {
      print("Error renaming asset file: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error renaming file: $e")));
      }
    }
  }

  Future<void> _deleteAssetFile(String fileName) async {
    if (_resolvedContextPath == null) return;
    try {
      final file = File('$_resolvedContextPath/$fileName');
      if (await file.exists()) {
        await file.delete();
        print("DEBUG: Deleted asset file: ${file.path}");
      }
    } catch (e) {
      print("Error deleting asset file: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error deleting file: $e")));
      }
    }
  }

  Future<void> _saveAssetFileContent(String fileName, String content) async {
    if (_resolvedContextPath == null) return;
    try {
      final file = File('$_resolvedContextPath/$fileName');
      // Only write if file exists (don't create new ones implicitly if deleted)
      // Actually, if it's in our tabs, it should exist or be created?
      // Let's create it if missing, as it's an "insert".
      await file.create(recursive: true);
      await file.writeAsString(content);
      print("DEBUG: Auto-saved content for $fileName");
    } catch (e) {
      print("Error saving asset file content: $e");
    }
  }

  Future<void> _updateVisibleFiles(
    String entryName,
    String targetFile, {
    String? oldName,
    bool isDelete = false,
  }) async {
    if (_resolvedContextPath == null) return;
    try {
      final visibleFile = File('$_resolvedContextPath/visible_files.json');
      Map<String, dynamic> json = {};

      // Read existing or init
      if (await visibleFile.exists()) {
        try {
          json = jsonDecode(await visibleFile.readAsString());
        } catch (_) {} // Align with empty if corrupt
      }

      // 1. Structure Check
      if (!json.containsKey('rules') && !json.containsKey('_private')) {
        // Migration: If root has keys that look like rules, move them.
        if (json.isNotEmpty) {
          bool looksLikeRules = json.keys.any((k) => k.contains('.'));
          if (looksLikeRules) {
            json = {'rules': Map<String, dynamic>.from(json), '_private': []};
          } else {
            json = {'rules': {}, '_private': []};
          }
        } else {
          json = {'rules': {}, '_private': []};
        }
      }

      json.putIfAbsent('rules', () => {});
      json.putIfAbsent('_private', () => []);

      final Map<String, dynamic> rules = json['rules'];
      final List<dynamic> private = json['_private'];

      // Helpers
      void removeFromList(List<dynamic> list, String item) {
        list.removeWhere((e) => e.toString() == item);
      }

      void addToList(List<dynamic> list, String item) {
        if (!list.any((e) => e.toString() == item)) list.add(item);
      }

      if (isDelete) {
        // DELETE
        removeFromList(private, targetFile);
        rules.forEach((key, val) {
          if (val is List) removeFromList(val, targetFile);
        });
      } else if (oldName != null) {
        // RENAME

        // 1. Rename Key (if this was an Entry Point)
        if (rules.containsKey(oldName)) {
          final content = rules[oldName];
          rules.remove(oldName);
          rules[targetFile] = content;
          print("DEBUG: Renamed Rule Key from $oldName to $targetFile");
        }

        // 2. Rename Value (if it appeared in other lists)
        removeFromList(private, oldName);
        addToList(private, targetFile);

        rules.forEach((key, val) {
          if (val is List) {
            if (val.contains(oldName)) {
              removeFromList(val, oldName);
              addToList(val, targetFile);
            }
          }
        });
      } else {
        // ADD
        // 1. Mark as private (hidden from others)
        addToList(private, targetFile);

        // 2. Add to Rule for THIS entry point
        if (!rules.containsKey(entryName)) {
          // If rule missing, create it.
          // CRITICAL: Must snapshot current visible files so we don't accidentally hide them
          // by switching from "Default Show All" to "Strict Whitelist".
          final currentVisible = _files.map((f) => f.name).toList();
          if (!currentVisible.contains(targetFile))
            currentVisible.add(targetFile);
          rules[entryName] = currentVisible;
        } else {
          final List<dynamic> currentRule = rules[entryName];
          addToList(currentRule, targetFile);
        }
      }

      // Save
      await visibleFile.writeAsString(jsonEncode(json));
      print("DEBUG: visible_files.json updated for $targetFile");
    } catch (e) {
      print("Error updating visible_files.json: $e");
    }
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
                if (widget.isAdmin) {
                  _createAssetFile(newName);
                  // Update visibility (Entry Point is likely _files[0] BEFORE this add, or we rely on 'files' state)
                  // _files was just updated with .add.
                  // The "Entry Point" is usually the first file loaded.
                  if (_files.isNotEmpty) {
                    _updateVisibleFiles(_files[0].name, newName);
                  }
                }
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
                final oldName = _files[index].name;
                setState(() {
                  _files[index].name = newName;
                });
                if (widget.isAdmin) {
                  _renameAssetFile(oldName, newName);
                  if (_files.isNotEmpty) {
                    _updateVisibleFiles(
                      _files[0].name,
                      newName,
                      oldName: oldName,
                    );
                  }
                  // Notify parent to update Markdown
                  widget.onFileRenamed?.call(oldName, newName);
                }
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
              final nameToDelete = _files[index].name;
              setState(() {
                _files.removeAt(index);
                if (_activeFileIndex >= _files.length) {
                  _activeFileIndex = _files.length - 1;
                }
                _codeController.text = _files[_activeFileIndex].content;
              });
              if (widget.isAdmin) {
                _deleteAssetFile(nameToDelete);
                // Note: _files content changed, but we need the entry point.
                // Assuming entry point is still index 0 if we didn't delete it.
                if (_files.isNotEmpty) {
                  _updateVisibleFiles(
                    _files[0].name,
                    nameToDelete,
                    isDelete: true,
                  );
                }
              }
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
        print("DEBUG: Server Request: $path");

        // --- 0. PROXY POST REQUESTS (PHP FORM SUPPORT) ---
        if (request.method == 'POST') {
          try {
            final content = await utf8.decoder.bind(request).join();
            final formData = Uri.splitQueryString(content);

            print("DEBUG: ----------------------------------------");
            print("DEBUG: PHP POST INTERCEPTED");
            print("DEBUG: Target: $path");
            print("DEBUG: Form Data: $formData");
            print("DEBUG: ----------------------------------------");

            // --- MULTI-FILE PHP SUPPORT ---
            // If the POST is to a specific .php file (e.g., /Biodata.php),
            // the backend RunCodeController now handles looking it up in assets/temp dir
            // if it's not explicitly in the sent files list.

            // ------------------------------

            // Executing PHP with this form data

            // 1. Determine local file match from our tabs
            // path might be like /run_12345678/action_page.php
            // We just want the filename part because our backend env is flat
            final uriSegments = Uri.parse("http://dummy$path").pathSegments;
            final fileName = uriSegments.isNotEmpty
                ? uriSegments.last
                : "index.php";

            // Check if we have this file in our tabs
            final matchingFileIndex = _files.indexWhere(
              (f) => f.name == fileName,
            );

            if (matchingFileIndex != -1) {
              print("DEBUG: Found target file in tabs: $fileName");
            }

            // Execute using our new signature
            final output = await _executePhp(
              files: _files,
              entryPoint: fileName, // Send just the filename
              formData: formData,
              getData: request.uri.queryParameters,
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

        // --- 0.5 INTERCEPT PHP GET REQUESTS (LINKING/REDIRECTION) ---
        if (request.method == 'GET' && path.endsWith('.php')) {
          try {
            // 1. Determine filename
            final uriSegments = Uri.parse("http://dummy$path").pathSegments;
            final fileName = uriSegments.isNotEmpty
                ? uriSegments.last
                : "index.php";

            print("DEBUG: ----------------------------------------");
            print("DEBUG: PHP GET INTERCEPTED");
            print("DEBUG: Target: $fileName");
            print("DEBUG: Query Params: ${request.uri.queryParameters}");
            print("DEBUG: ----------------------------------------");

            // Execute using our new signature
            final output = await _executePhp(
              files: _files,
              entryPoint: fileName,
              getData: request.uri.queryParameters,
            );

            // Serve the result back to the browser
            request.response
              ..headers.contentType = ContentType.html
              ..write(output)
              ..close();
            return;
          } catch (e) {
            print("Error executing PHP GET: $e");
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write("Error executing file: $e")
              ..close();
            return;
          }
        }

        // --- 1. SERVE FILES FROM RUN DIRECTORY OR FALLBACK ---
        // This handles HTML, CSS, JS, and Images for the running code.
        // It first looks in the temporary run directory (where we write the editor files).
        // If not found there (e.g. static assets like images), it looks in the context assets.

        if (path.contains('/run_') || path == '/') {
          final dir = await getTemporaryDirectory();
          // Extract the run directory if present, or just assume root?
          // The path is already /run_timestamp/something.

          final filePath = (path == '/') ? 'index.html' : path.substring(1);
          final file = File('${dir.path}/$filePath');

          // 1a. Try Temp Dir
          print("DEBUG: Checking temp file: ${file.path}");
          if (await file.exists()) {
            print("DEBUG: Found temp file! Serving...");
            final contentType = _getContentType(path);
            request.response.headers.contentType = contentType;
            // Read as bytes to support images/binary too (if we ever write them there)
            await request.response.addStream(file.openRead());
            await request.response.close();
            return;
          } else {
            print("DEBUG: Temp file NOT found!");
          }

          // 1b. Fallback to Asset Context (for images not in editor)
          // We use _resolvedContextPath which might be fuzzy matched
          // 1b. Fallback to Asset Context (for images not in editor)
          // We use _resolvedContextPath which might be fuzzy matched
          if (_resolvedContextPath != null) {
            try {
              // Extract relative path from validity check
              // path: /run_123456/LogoKelab.png -> relative: LogoKelab.png
              // path: /run_123456/css/style.css -> relative: css/style.css
              final segments = Uri.parse("http://dummy$path").pathSegments;
              // Filter out the 'run_xxxxx' segment
              final relevantSegments = segments
                  .where((s) => !s.startsWith('run_'))
                  .toList();

              if (relevantSegments.isNotEmpty) {
                final relativePath = relevantSegments.join('/');
                // _resolvedContextPath is like 'assets/www/Folder Name'
                final assetKey = '$_resolvedContextPath/$relativePath';
                print("DEBUG: Fallback attempting to load: $assetKey");

                Uint8List? bodyBytes;

                // 1. Try Filesystem FIRST (For "Live" changes)
                try {
                  File file = File(assetKey);
                  if (await file.exists()) {
                    bodyBytes = await file.readAsBytes();
                    print("DEBUG: Asset found on filesystem (Live)!");
                  } else {
                    // Try with platform separators just in case
                    final fixedPath = assetKey.replaceAll(
                      '/',
                      Platform.pathSeparator,
                    );
                    final fileFixed = File(fixedPath);
                    if (await fileFixed.exists()) {
                      bodyBytes = await fileFixed.readAsBytes();
                      print(
                        "DEBUG: Asset found on filesystem (Live/FixedSep)!",
                      );
                    }
                  }
                } catch (e) {
                  // fs failed, move on
                }

                // 2. Fallback to Bundle (If not on disk / Release mode)
                if (bodyBytes == null) {
                  try {
                    // Try plain key
                    final data = await rootBundle.load(assetKey);
                    bodyBytes = data.buffer.asUint8List();
                    print("DEBUG: Asset found in bundle (plain)!");
                  } catch (e) {
                    // 3. Try encoded key (handle spaces as %20)
                    try {
                      final encodedKey = Uri.encodeFull(assetKey);
                      print("DEBUG: Trying encoded key: $encodedKey");
                      final data = await rootBundle.load(encodedKey);
                      bodyBytes = data.buffer.asUint8List();
                      print("DEBUG: Asset found in bundle (encoded)!");
                    } catch (eEncoded) {
                      print("DEBUG: Asset load failed entirely for $assetKey");
                    }
                  }
                }

                if (bodyBytes != null) {
                  final contentType = _getContentType(path);
                  request.response.headers.contentType = contentType;
                  request.response.add(bodyBytes);
                  await request.response.close();
                  return;
                }
              }
            } catch (e) {
              print("DEBUG: Asset fallback failed: $e");
            }
          }

          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
          return;
        }

        // 2. Serve General Static Assets (from assets/www direct access)
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
      // DEBUG: Check what assets are actually bundled
      try {
        final manifestContent = await rootBundle.loadString(
          'AssetManifest.json',
        );
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        final matchingKeys = manifestMap.keys
            .where((key) => key.toLowerCase().contains('logokelab'))
            .toList();
        print("DEBUG: Bundled 'LogoKelab' keys: $matchingKeys");

        // Also print keys for the specific folder if possible
        final folderKeys = manifestMap.keys
            .where((key) => key.contains('3.2.9'))
            .take(5)
            .toList();
        print("DEBUG: Sample bundled keys for 3.2.9: $folderKeys");
      } catch (e) {
        print("DEBUG: Could not check manifest: $e");
      }

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
        await f.create(recursive: true); // Ensure parent dirs exist
        await f.writeAsString(file.content);
        print(
          "DEBUG: Wrote temp file: ${f.path} (Size: ${file.content.length})",
        );
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
    Map<String, dynamic>? getData,
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
        'php_session_id': _phpSessionId,
        if (formData != null) 'form_data': formData,
        if (getData != null) 'get_data': getData,
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

        // --- SYNC MODIFIED FILES ---
        if (data['files'] != null && data['files'] is List) {
          final List<dynamic> returnedFiles = data['files'];
          for (var item in returnedFiles) {
            final String rName = item['name'];
            final String rContent = item['content'];

            // Check if we have this file to update
            final index = _files.indexWhere((f) => f.name == rName);
            if (index != -1) {
              // Update content if different
              if (_files[index].content != rContent) {
                setState(() {
                  _files[index].content = rContent;
                  // If this is the active file, update controller too
                  if (index == _activeFileIndex) {
                    _codeController.text = rContent;
                  }
                });
                print("DEBUG: Synced file update for $rName");
              }
            } else {
              // Optionally add new files created by backend?

              // --- FILTERING CHECK (Backend Sync) ---
              // Check if we should ignore this file based on visible_files.json rules
              // We need to re-read or cache the allowed rules.
              // Since we don't have easy access to the rule set here (it's in _loadContextAssets),
              // we can rely on a simpler check:
              // If the user has explicitly loaded a context and we have hidden files, they shouldn't come back.

              // However, since we don't persist 'allowedFiles' as a class member, we need to check if we can add it.
              // Strategy: If the file was available in the context BUT is not in _files, it means it was filtered out.
              // So we should NOT add it back.

              // BUT: What if it's a NEW file created by the script (e.g. output.txt)? We probably want to see that.

              // Let's rely on `_resolvedContextPath`. If the file exists in that path, but is NOT in _files,
              // it means it was filtered.

              bool shouldSkip = false;
              if (_resolvedContextPath != null) {
                // If it exists on disk (meaning it's part of the original set) but not in our tabs,
                // it must have been filtered. Skip it.
                // CAUTION: This assumes synchronous FS, which we can't do easily here without await.
                // But we can just add it and let the user see it?
                // NO, the user complained about "reappearing".

                // Better: Pass the 'allowedSet' to _executePhp? Or store it in class State.
                // Let's store `_allowedFilesCache` in State.
                if (_allowedFilesCache != null &&
                    !_allowedFilesCache!.contains(rName)) {
                  print(
                    "DEBUG: Backend returned '$rName' but it is filtered out. Skipping add.",
                  );
                  shouldSkip = true;
                }
              }

              if (!shouldSkip) {
                setState(() {
                  _files.add(CodeFile(name: rName, content: rContent));
                });
              }
            }
          }
        }

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: BreadcrumbNavigation(
          items: [
            BreadcrumbItem(
              label: 'Note',
              onTap: () {
                // Return a specific signal to pop all the way back to list
                Navigator.of(context).pop('navigate_home');
              },
            ),
            BreadcrumbItem(
              label: widget.topic,
              onTap: () {
                // Return signal to pop back to list with topic filter
                Navigator.of(context).pop('navigate_topic');
              },
            ),
            BreadcrumbItem(
              label: widget.noteTitle,
              onTap: () => Navigator.of(context).pop(),
            ),
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
