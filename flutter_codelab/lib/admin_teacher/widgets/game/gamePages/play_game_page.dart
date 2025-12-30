import 'package:flutter/material.dart';

import 'package:code_play/models/level.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/constants/api_constants.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_codelab/utils/local_asset_server.dart';
import 'package:flutter_codelab/services/local_level_storage.dart';
import 'package:flutter_codelab/api/auth_api.dart';

/// Opens the edit dialog
Future<void> showPlayGamePage({
  required BuildContext context,
  required String userRole, // ✅ Pass current user's role
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
  required LevelModel level,
}) async {
  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return PlayGamePage(
        showSnackBar: showSnackBar,
        parentContext: context,
        level: level,
        userRole: userRole, // Pass role to the page
      );
    },
  );
}

class PlayGamePage extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final LevelModel level;
  final BuildContext parentContext;
  final String userRole; // Current user role

  const PlayGamePage({
    super.key,
    required this.showSnackBar,
    required this.parentContext,
    required this.level,
    required this.userRole,
  });

  @override
  State<PlayGamePage> createState() => _PlayGamePageState();
}

class _PlayGamePageState extends State<PlayGamePage> {
  late String selectedValue;
  late String levelName;
  final bool _saving = false;

  final GlobalKey<_IndexFilePreviewState> previewKey =
      GlobalKey<_IndexFilePreviewState>();

  final List<String> levelTypes = ['HTML', 'CSS', 'JS', 'PHP', 'Quiz'];

  LocalAssetServer? _server;
  LocalAssetServer? _previewServer;
  String? _serverUrl;
  String? _previewServerUrl;
  InAppWebViewController? _webViewController;
  final LocalLevelStorage _levelStorage = LocalLevelStorage();
  String? _userId;

  @override
  void initState() {
    super.initState();
    levelName = widget.level.levelName ?? '';
    selectedValue = widget.level.levelTypeName ?? 'HTML';
    _initServer();
  }

  Future<void> _initServer() async {
    _server = LocalAssetServer();
    _previewServer = LocalAssetServer();
    try {
      await _server!.start(path: 'assets');
      
      // Fetch user ID to pass to Unity
      final user = await AuthApi.getStoredUser();
      final userId = user?['user_id']?.toString();
      
      // Start preview server pointing to local storage base path
      final storageBasePath = await _levelStorage.getBasePath(userId: userId);
      await _previewServer!.start(path: storageBasePath);
      
      setState(() {
        _serverUrl = 'http://localhost:${_server!.port}';
        _previewServerUrl = 'http://localhost:${_previewServer!.port}';
        _userId = userId;
      });
    } catch (e) {
      print("Error starting local server: $e");
    }
  }

  @override
  void dispose() {
    _server?.stop();
    _previewServer?.stop();
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
                    GameAPI.clearFiles();
                    Navigator.of(context).pop();
                  },
                ),
                Text(
                  "Play Level",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.cyan),
                ),
                const SizedBox(height: 24),
                // Beautiful Level Name Display
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyan.shade50,
                        Colors.blue.shade50,
                        Colors.cyan.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.cyan.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videogame_asset_rounded,
                            color: Colors.cyan.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              levelName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.cyan.shade900,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    height: 1.2,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.cyan.shade300,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          selectedValue,
                          style: TextStyle(
                            color: Colors.cyan.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Unity WebView preview
                Center(
                  child: SizedBox(
                    height: 1000,
                    width: 1250,
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(
                          "$_serverUrl/unity/index.html?role=${widget.userRole}&level_Id=${widget.level.levelId}&user_Id=$_userId",
                        ),
                      ),
                      initialSettings: InAppWebViewSettings(
                        // Cross-platform settings
                        javaScriptEnabled: true,
                        isInspectable: kDebugMode,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;

                        // Set up JavaScript handlers for Unity to call Flutter
                        controller.addJavaScriptHandler(
                          handlerName: 'getLevelFile',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('getLevelFile', levelId, type, dataType, useProgress)
                            if (args.length >= 3) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final dataType =
                                  args[2] as String? ??
                                  'level'; // levelData or winData
                              final useProgress = args.length >= 4
                                  ? (args[3] as bool? ?? false)
                                  : false;

                                  print("levelId : $levelId, type: $type, dataType: $dataType, useProgress: $useProgress");

                              final content = await _levelStorage
                                  .getFileContent(
                                    levelId: levelId,
                                    type: type,
                                    dataType: dataType,
                                    useProgress: useProgress,
                                    userId: _userId,
                                  );
                                  print("content: $content");

                              return content ?? '';
                            }
                            return '';
                          },
                        );

                        // Handler for save-data route
                        controller.addJavaScriptHandler(
                          handlerName: 'saveLevelFile',
                          callback: (args) async {
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

                              final success = await _levelStorage.saveDataFile(
                                levelId: levelId,
                                type: type,
                                dataType: dataType,
                                content: content,
                                userId: _userId,
                              );

                              return success;
                            }
                            return false;
                          },
                        );

                        // Handler for save-index route
                        controller.addJavaScriptHandler(
                          handlerName: 'saveIndexFile',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('saveIndexFile', levelId, type, content)
                            if (args.length >= 3) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final content = args[2] as String? ?? '';

                              final success = await _levelStorage.saveIndexFile(
                                levelId: levelId,
                                type: type,
                                content: content,
                                userId: _userId,
                              );

                              return success;
                            }
                            return false;
                          },
                        );

                        // Handler for saving student progress (saves locally and optionally syncs to Laravel)
                        controller.addJavaScriptHandler(
                          handlerName: 'saveStudentProgress',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('saveStudentProgress', levelId, savedDataJson, syncToServer)
                            if (args.length >= 2) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              final savedDataJson = args[1] as String?;
                              final syncToServer = args.length >= 3
                                  ? (args[2] as bool? ?? true)
                                  : true;

                              // Save locally first
                              final localSuccess = await _levelStorage
                                  .saveStudentProgress(
                                    levelId: levelId,
                                    savedDataJson: savedDataJson,
                                    userId: _userId,
                                  );

                              // Optionally sync to Laravel
                              if (syncToServer && savedDataJson != null) {
                                try {
                                  final response =
                                      await GameAPI.saveStudentProgress(
                                        levelId: levelId,
                                        savedData: savedDataJson,
                                      );
                                  if (kDebugMode) {
                                    print(
                                      'Synced progress to server: ${response['message']}',
                                    );
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print(
                                      'Failed to sync progress to server: $e',
                                    );
                                  }
                                  // Continue even if sync fails - local save succeeded
                                }
                              }

                              return localSuccess;
                            }
                            return false;
                          },
                        );

                        // Handler for level completion
                        controller.addJavaScriptHandler(
                          handlerName: 'completeLevel',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('completeLevel', levelId, userId)
                            if (args.length >= 1) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';
                              
                              String? userId = args.length >= 2 ? args[1] as String? : null;

                              // If userId is not provided by Unity, try to get it from stored user
                              if (userId == null || userId.isEmpty) {
                                final user = await AuthApi.getStoredUser();
                                userId = user?['user_id']?.toString();
                              }

                              if (userId != null && userId.isNotEmpty) {
                                try {
                                  final response = await GameAPI.completeLevel(
                                    levelId: levelId,
                                    userId: userId,
                                  );
                                  
                                  if (kDebugMode) {
                                    print('Level completion synced to server: ${response['message']}');
                                  }
                                  
                                  // Return true if the backend says it's a success
                                  return response['success'] != false; 
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Failed to sync level completion: $e');
                                  }
                                }
                              }
                            }
                            return false;
                          },
                        );
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        if (kDebugMode) {
                          print("Unity Console: ${consoleMessage.message}");
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

/// WebView preview for Unity build
class IndexFilePreview extends StatefulWidget {
  final String userRole;
  final String serverUrl;
  final String levelId;

  const IndexFilePreview({
    super.key,
    required this.userRole,
    required this.serverUrl,
    required this.levelId,
  });

  @override
  State<IndexFilePreview> createState() => _IndexFilePreviewState();
}

class _IndexFilePreviewState extends State<IndexFilePreview> {
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    if (widget.serverUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Preview points to the generated index folder within the level
    final url = "${widget.serverUrl}/${widget.levelId}/index/index.html";

    return InAppWebView(
      key: _key,
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: kDebugMode,
      ),
    );
  }

  void reloadPreview(String userRole) {
    setState(() {
      _key = UniqueKey();
    });
  }
}

