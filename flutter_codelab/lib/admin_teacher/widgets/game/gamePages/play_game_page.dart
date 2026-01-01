import 'package:flutter/material.dart';
import 'dart:async'; // Import Timer
import 'dart:convert'; // Import jsonEncode

import 'package:code_play/models/level.dart';
import 'package:code_play/api/game_api.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:code_play/utils/local_asset_server.dart';
import 'package:code_play/services/local_level_storage.dart';
import 'package:code_play/api/auth_api.dart';

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
  // Timer state
  int? _timeLeft;
  bool _isTimerActive = false;
  Timer? _timer;

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
    levelName = widget.level.levelName ?? '';
    selectedValue = widget.level.levelTypeName ?? 'HTML';

    // Initialize Timer if Quiz
    if (selectedValue == 'Quiz' &&
        widget.level.timer != null &&
        widget.level.timer! > 0) {
      _timeLeft = widget.level.timer; // Start with full time
      // If we wanted to load saved time, we'd need to fetch level data first.
      // For now, let's start fresh or rely on what Unity sends?
      // Actually, user requirement says "timer.. stores remaining time left".
      // So checking if we have saved progress might be good, but synchronous initState can't await.
      // We will handle saved time when we load student progress?
      // For now, start ticking.
      _startTimer();
    }

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

      // Clear index files for this level to ensure a fresh preview
      if (widget.level.levelId != null) {
        await _levelStorage.clearIndexFiles(
          levelId: widget.level.levelId!,
          userId: userId,
        );
      }

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
    _timer?.cancel();
    _server?.stop();
    _previewServer?.stop();
    super.dispose();
  }

  void _startTimer() {
    if (_timeLeft == null || _timeLeft! <= 0) return;

    _isTimerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft! > 0) {
          _timeLeft = _timeLeft! - 1;
        } else {
          _isTimerActive = false;
          timer.cancel();
          // Optionally auto-submit or notify unity?
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
                const SizedBox(height: 8),
                // Beautiful Level Name Display
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
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

                // Premium Timer Display (Only for Quiz)
                if (selectedValue == 'Quiz' && _timeLeft != null)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_timeLeft! < 60)
                              ? [Colors.red.shade400, Colors.red.shade700]
                              : [Colors.cyan.shade400, Colors.cyan.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (_timeLeft! < 60)
                                ? Colors.red.withOpacity(0.3)
                                : Colors.cyan.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "TIME REMAINING",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                _formatTime(_timeLeft!),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                          "$_serverUrl/unity/index.html?role=${widget.userRole}&level_Id=${widget.level.levelId}&user_Id=$_userId&level_Type=${widget.level.levelTypeName}",
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

                              print(
                                "levelId : $levelId, type: $type, dataType: $dataType, useProgress: $useProgress",
                              );

                              final content = await _levelStorage
                                  .getFileContent(
                                    levelId: levelId,
                                    type: type,
                                    dataType: dataType,
                                    useProgress: useProgress,
                                    userId: _userId,
                                  );

                              // Check if we need to set initial timer from saved progress?
                              // The API.fetchLevelById already did this by saving to storage if it fetched progress.
                              // But here we are just reading content.
                              // If we wanted to sync timer from backend, we might need a separate call or pass it in LevelModel.
                              // For now, assuming timer starts fresh or from LevelModel.
                              // IMPROVEMENT: If we fetched progress from backend, we should update _timeLeft.

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

                              // Save locally first (standard save)
                              final localSuccess = await _levelStorage
                                  .saveStudentProgress(
                                    levelId: levelId,
                                    savedDataJson: savedDataJson,
                                    userId: _userId,
                                  );

                              // Capture index files for persistence
                              final indexFilesMap = await _levelStorage
                                  .readIndexFiles(
                                    levelId: levelId,
                                    userId: _userId,
                                  );
                              final indexFilesJson = jsonEncode(indexFilesMap);
                              if (kDebugMode) {
                                print(
                                  'DEBUG: [play_game_page] index_files captured: ${indexFilesMap.keys.toList()}',
                                );
                                indexFilesMap.forEach(
                                  (k, v) => print(
                                    'DEBUG: [play_game_page] $k length: ${v.length}',
                                  ),
                                );
                              }

                              // Quiz Bundle Logic (Legacy support or internal requirements)
                              if (selectedValue == 'Quiz') {
                                // For quizes, we still send the bundle as savedData for compatibility
                                // But now we also send it officially as indexFiles
                                if (syncToServer) {
                                  try {
                                    await GameAPI.saveStudentProgress(
                                      levelId: levelId,
                                      savedData:
                                          indexFilesJson, // Bundle as savedData
                                      indexFiles:
                                          indexFilesJson, // Also as indexFiles
                                      timer: _timeLeft,
                                    );
                                  } catch (e) {
                                    if (kDebugMode)
                                      print('Failed to sync quiz: $e');
                                  }
                                }
                                return localSuccess;
                              }

                              // Standard Sync (Non-Quiz)
                              if (syncToServer && savedDataJson != null) {
                                try {
                                  await GameAPI.saveStudentProgress(
                                    levelId: levelId,
                                    savedData: savedDataJson,
                                    indexFiles:
                                        indexFilesJson, // Official index persistence
                                  );
                                } catch (e) {
                                  if (kDebugMode)
                                    print('Failed to sync progress: $e');
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
                            if (args.isNotEmpty) {
                              final levelId =
                                  args[0] as String? ??
                                  widget.level.levelId ??
                                  '';

                              String? userId = args.length >= 2
                                  ? args[1] as String?
                                  : null;

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
                                    print(
                                      'Level completion synced to server: ${response['message']}',
                                    );
                                  }

                                  // Return true if the backend says it's a success
                                  return response['success'] != false;
                                } catch (e) {
                                  if (kDebugMode) {
                                    print(
                                      'Failed to sync level completion: $e',
                                    );
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
    final url = "${widget.serverUrl}/${widget.levelId}/Index/index.html";

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
