import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:code_play/models/level.dart';
import 'package:code_play/api/game_api.dart';
import 'package:flutter/foundation.dart';
import 'package:code_play/utils/local_asset_server.dart';
import 'package:code_play/api/auth_api.dart';
import 'package:code_play/services/local_level_storage.dart';
import 'package:code_play/admin_teacher/widgets/game/index_file_preview.dart';
import 'package:code_play/constants/api_constants.dart';
import 'dart:convert';

/// Opens the edit dialog
Future<void> showEditGamePage({
  required BuildContext context,
  required String userRole, // ✅ Pass current user's role
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
  required LevelModel level,
}) async {
  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return EditGamePage(
        showSnackBar: showSnackBar,
        parentContext: context,
        level: level,
        userRole: userRole, // Pass role to the page
      );
    },
  );
}

class EditGamePage extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final LevelModel level;
  final BuildContext parentContext;
  final String userRole; // Current user role

  const EditGamePage({
    super.key,
    required this.showSnackBar,
    required this.parentContext,
    required this.level,
    required this.userRole,
  });

  @override
  State<EditGamePage> createState() => _EditGamePageState();
}

class _EditGamePageState extends State<EditGamePage> {
  late String selectedValue;
  late String levelName;
  bool _saving = false;
  late TextEditingController _nameController;
  // Validation state
  bool _nameError = false;
  // Timer state
  late TextEditingController _timerController;

  final GlobalKey<IndexFilePreviewState> previewKey =
      GlobalKey<IndexFilePreviewState>();

  List<String> get levelTypes {
    if (widget.userRole.toLowerCase() == 'teacher') {
      return ['Quiz'];
    }
    return ['HTML', 'CSS', 'JS', 'PHP', 'Quiz'];
  }

  LocalAssetServer? _server;
  LocalAssetServer? _previewServer;
  String? _serverUrl;
  String? _previewServerUrl;

  String? _userId;
  final _levelStorage = LocalLevelStorage();

  @override
  void initState() {
    super.initState();
    levelName = widget.level.levelName ?? '';
    _nameController = TextEditingController(text: levelName);
    selectedValue = widget.level.levelTypeName ?? 'HTML';
    _timerController = TextEditingController(
      text: (widget.level.timer ?? 0).toString(),
    );
    _initServer().then((_) => _loadLevelDetails());
  }

  Future<void> _loadLevelDetails() async {
    if (widget.level.levelId != null) {
      await GameAPI.fetchLevelById(
        widget.level.levelId!,
        userRole: widget.userRole,
      );
    }
  }

  Future<void> _initServer() async {
    _server = LocalAssetServer();
    _previewServer = LocalAssetServer();
    String? userId;
    try {
      // Fetch user ID for storage path
      final user = await AuthApi.getStoredUser();
      userId = user?['user_id']?.toString();

      if (kIsWeb) {
        setState(() {
          _serverUrl = 'assets';
          _previewServerUrl = 'web_storage';
          _userId = userId;
        });
        return;
      }

      await _server!.start(path: 'assets');

      // Clear index files for this level to ensure a fresh preview
      try {
      if (widget.level.levelId != null) {
        await _levelStorage.clearIndexFiles(
          levelId: widget.level.levelId!,
          userId: userId,
        );
        }
      } catch (e) {
        // Continue anyway - not critical
      }

      setState(() {
        _userId = userId;
      });

      // Start preview server for local storage base path
      try {
      final storageBasePath = await _levelStorage.getBasePath(userId: userId);
      await _previewServer!.start(path: storageBasePath);
      } catch (e) {
        // Try to continue
      }

      setState(() {
        _serverUrl = 'http://localhost:${_server!.port}';
        _previewServerUrl = _previewServer != null
            ? 'http://localhost:${_previewServer!.port}'
            : 'http://localhost:8081';
      });
    } catch (e) {
      // Set default values even on error to prevent UI from hanging
      setState(() {
        _serverUrl = kIsWeb ? 'assets' : 'http://localhost:8080';
        _previewServerUrl = kIsWeb ? 'web_storage' : 'http://localhost:8081';
        _userId = userId ?? _userId ?? '';
      });
    }
  }

  @override
  void dispose() {
    // Stop servers (synchronous)
    try {
    _server?.stop();
    _previewServer?.stop();
    } catch (e) {
      // Silently handle error
    }
    
    // Dispose controllers
    _nameController.dispose();
    _timerController.dispose();
    
    // Don't manually stop WebView - Flutter will handle disposal automatically
    // Trying to stop it manually causes race conditions with Flutter's disposal
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_serverUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(
                  onPressed: () {
                    // Clear files (synchronous operation)
                    try {
                    GameAPI.clearFiles();
                    } catch (e) {
                      // Silently handle error - continue with navigation
                    }
                    
                    // Navigate immediately - let Flutter's dispose() handle cleanup
                    // Don't try to manually stop WebViews as it causes race conditions
                    if (mounted) {
                    Navigator.of(context).pop();
                    }
                  },
                ),
                Text(
                  "Edit Level",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.cyan),
                ),
                const SizedBox(height: 16),

                // Level Name TextField
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Enter level name *',
                    border: const OutlineInputBorder(),
                    errorText: _nameError ? 'Level name is required' : null,
                  ),
                  onChanged: (value) {
                    levelName = value;
                    if (_nameError && value.isNotEmpty) {
                      setState(() {
                        _nameError = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown + Save Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: selectedValue,
                      items: levelTypes
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(value),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => selectedValue = newValue);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    // Timer Input (Only for Quiz)
                    if (selectedValue == 'Quiz')
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _timerController,
                          decoration: const InputDecoration(
                            labelText: 'Timer (s)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    if (selectedValue == 'Quiz') const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (levelName.isEmpty) {
                                setState(() {
                                  _nameError = true;
                                });
                                return;
                              }

                              setState(() => _saving = true);

                              // Sync Unity data from local storage back to server
                              final storage = LocalLevelStorage();
                              final levelTypes = ['html', 'css', 'js', 'php'];

                              Map<String, String?> currentLevelData = {};
                              Map<String, String?> currentWinData = {};

                              final originalLevelData =
                                  widget.level.levelData != null
                                  ? jsonDecode(widget.level.levelData!)
                                  : {};
                              final originalWinData =
                                  widget.level.winCondition != null
                                  ? jsonDecode(widget.level.winCondition!)
                                  : {};

                              for (final type in levelTypes) {
                                final localLevel = await storage.getFileContent(
                                  levelId: widget.level.levelId!,
                                  type: type,
                                  dataType: 'level',
                                  userId: _userId,
                                  userRole: widget.userRole,
                                );
                                // Use local or fallback to original
                                final localWin = await storage.getFileContent(
                                  levelId: widget.level.levelId!,
                                  type: type,
                                  dataType: 'win',
                                  userId: _userId,
                                  userRole: widget.userRole,
                                );

                                if (kDebugMode) {
                                  print('[EDIT_GAME_PAGE] Loading level data');
                                  print('[EDIT_GAME_PAGE] Data: ${localLevel ?? originalLevelData[type]?.toString() ?? "null"}');
                                  print('[EDIT_GAME_PAGE] Loading win data');
                                  print('[EDIT_GAME_PAGE] Data: ${localWin ?? originalWinData[type]?.toString() ?? "null"}');
                                }

                                currentLevelData[type] =
                                    localLevel ??
                                    originalLevelData[type]?.toString();
                                currentWinData[type] =
                                    localWin ??
                                    originalWinData[type]?.toString();
                              }

                              final ApiResponse
                              response = await GameAPI.updateLevel(
                                levelId: widget.level.levelId!,
                                levelName: levelName,
                                levelTypeName: selectedValue,
                                levelData: jsonEncode(currentLevelData),
                                winCondition: jsonEncode(currentWinData),
                                timer: int.tryParse(_timerController.text) ?? 0,
                              );

                              setState(() => _saving = false);

                              if (response.success) {
                                widget.showSnackBar(
                                  widget.parentContext,
                                  "Level updated!",
                                  Colors.green,
                                );
                                Navigator.of(context).pop();
                                previewKey.currentState?.reloadPreview(
                                  widget.userRole,
                                );
                              } else {
                                widget.showSnackBar(
                                  widget.parentContext,
                                  "Failed to update level: ${response.message}",
                                  Colors.red,
                                );
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Unity WebView preview
                Center(
                  child: SizedBox(
                    height: 1000,
                    width: 1250,
                    child: InAppWebView(
                      key: ValueKey(
                        'unity_webview_edit_${widget.level.levelId}',
                      ),
                      initialUrlRequest: URLRequest(
                        url: WebUri(
                          kIsWeb
                              ? Uri.base
                                    .resolve('assets/unity/index.html')
                                    .replace(
                                      queryParameters: {
                                        'role': widget.userRole,
                                        'level_Id': widget.level.levelId ?? '',
                                        'user_Id': _userId ?? '',
                                        'level_Type': selectedValue,
                                      },
                                    )
                                    .toString()
                              : "$_serverUrl/unity/index.html?role=${widget.userRole}&level_Id=${widget.level.levelId}&user_Id=$_userId&level_Type=$selectedValue",
                        ),
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                      ),
                      onWebViewCreated: (controller) {
                        // Wrap all handlers in try-catch to prevent web crashes
                        try {
                        // Handler for saving level data (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'saveLevelFile',
                          callback: (args) async {
                            // Check if widget is still mounted
                            if (!mounted) return false;
                            
                            // Unity calls: window.flutter_inappwebview.callHandler('saveLevelFile', levelId, type, dataType, content)
                            if (args.length >= 4) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final dataType =
                                  args[2] as String? ?? 'levelData';
                              final content = args[3] as String? ?? '';

                              if (kDebugMode) {
                                final normalizedDataType = dataType.toLowerCase().contains('win') ? 'win' : 'level';
                                print('[EDIT_GAME_PAGE] Saving $normalizedDataType data');
                                print('[EDIT_GAME_PAGE] Data: $content');
                              }

                              final storage = LocalLevelStorage();
                              return await storage.saveDataFile(
                                levelId: levelId,
                                userId: _userId,
                                type: type,
                                dataType: dataType,
                                content: content,
                              );
                            }
                            return false;
                          },
                        );

                        // Handler for saving index file (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'saveIndexFile',
                          callback: (args) async {
                            // Check if widget is still mounted
                            if (!mounted) return false;
                            
                            // Unity calls: window.flutter_inappwebview.callHandler('saveIndexFile', levelId, type, content)
                            if (args.length >= 3) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final content = args[2] as String? ?? '';

                              final storage = LocalLevelStorage();
                              return await storage.saveIndexFile(
                                levelId: levelId,
                                userId: _userId,
                                type: type,
                                content: content,
                              );
                            }
                            return false;
                          },
                        );

                        // Handler for getting level files (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'getLevelFile',
                          callback: (args) async {
                            // Check if widget is still mounted
                            if (!mounted) return '';
                            
                            // Unity calls: window.flutter_inappwebview.callHandler('getLevelFile', levelId, type, dataType, useProgress)
                            if (args.length >= 3) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final dataType =
                                  args[2] as String? ?? 'level';
                              final useProgress = args.length >= 4
                                  ? (args[3] as bool? ?? false)
                                  : false;

                              final storage = LocalLevelStorage();
                              final content = await storage.getFileContent(
                                levelId: levelId,
                                userId: _userId,
                                type: type,
                                dataType: dataType,
                                useProgress: useProgress,
                                userRole: widget.userRole,
                                );

                              return content ?? '';
                            }
                            return '';
                          },
                        );
                        } catch (e) {
                          // Continue - handlers might not work on web but shouldn't crash
                        }
                      },
                      onLoadStop: (controller, url) async {
                        // Check if widget is still mounted before proceeding
                        if (!mounted) return;
                        
                        // Wait a bit for Unity to initialize
                        await Future.delayed(const Duration(milliseconds: 500));
                        
                        // Check again after delay
                        if (!mounted) return;
                        
                        // Set API URL and auth token in localStorage for Unity to access
                        try {
                          if (!mounted) return;
                          
                          final apiUrl = ApiConstants.baseUrl;
                          final token = await AuthApi.getToken();
                          
                          if (!mounted) return;
                          
                          final jsCode = '''
                            localStorage.setItem('laravel_api_url', '$apiUrl');
                            ${token != null ? "localStorage.setItem('auth_token', '$token');" : ''}
                          ''';
                          await controller.evaluateJavascript(source: jsCode);
                        } catch (e) {
                          // Silently handle error
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        previewKey.currentState?.reloadPreview(widget.userRole);
                      },
                      child: const Text("Reload Preview"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Preview Container
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    height: 500,
                    width: 500,
                    child: IndexFilePreview(
                      key: previewKey,
                      userRole: widget.userRole,
                      serverUrl: _previewServerUrl ?? '', // Use preview server
                      levelId: widget.level.levelId ?? '',
                      userId: _userId,
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
