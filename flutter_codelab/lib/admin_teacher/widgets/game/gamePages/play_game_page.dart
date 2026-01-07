import 'package:flutter/material.dart';
import 'dart:async'; // Import Timer
import 'dart:convert'; // Import jsonEncode

import 'package:code_play/models/level.dart';

// Conditional import for web platform - only import dart:html on web
import 'dart:html' as html show window; // For localStorage access on web
import 'package:code_play/api/game_api.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:code_play/utils/local_asset_server.dart';
import 'package:code_play/utils/local_asset_server_api.dart';
import 'package:code_play/services/local_level_storage.dart';
import 'package:code_play/api/auth_api.dart';
import 'package:code_play/admin_teacher/widgets/game/index_file_preview.dart';
import 'package:code_play/constants/api_constants.dart';

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
  // Timer state
  int? _timeLeft;
  Timer? _timer;
  Timer? _messagePollingTimer; // For polling Unity messages

  final GlobalKey<IndexFilePreviewState> previewKey =
      GlobalKey<IndexFilePreviewState>();

  final List<String> levelTypes = ['HTML', 'CSS', 'JS', 'PHP', 'Quiz'];

  LocalAssetServer? _server;
  LocalAssetServer? _previewServer;
  String? _serverUrl;
  String? _previewServerUrl;
  InAppWebViewController? _webViewController; // For web platform
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
    String? userId;
    try {
      // Fetch user ID to pass to Unity
      final user = await AuthApi.getStoredUser();
      userId = user?['user_id']?.toString();

      if (kIsWeb) {
        setState(() {
          _serverUrl =
              'assets'; // In Flutter Web, assets are served from 'assets/'
          _previewServerUrl = 'web_storage';
          _userId = userId;
        });
        return;
      }

      // Set up API handler for Unity HTTP requests (native platforms only)
      // On native, _server is LocalAssetServer (native implementation)
      final apiHandler = LocalAssetServerApi(_levelStorage);
      apiHandler.setUserId(userId);
      // Use dynamic cast to avoid type checking issues with conditional exports
      (_server as dynamic).setApiHandler(apiHandler);
      
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

      // Start preview server pointing to local storage base path
      try {
        final storageBasePath = await _levelStorage.getBasePath(userId: userId);
        await _previewServer!.start(path: storageBasePath);
      } catch (e) {
        // Try to continue with a fallback path
      }

      setState(() {
        _serverUrl = 'http://localhost:${_server!.port}';
        _previewServerUrl = 'http://localhost:${_previewServer!.port}';
        _userId = userId;
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
    // Cancel timers first (synchronous)
    _timer?.cancel();
    _messagePollingTimer?.cancel();
    
    // Stop servers (synchronous)
    try {
      _server?.stop();
      _previewServer?.stop();
    } catch (e) {
      // Silently handle error
    }
    
    // Don't manually stop WebView - Flutter will handle disposal automatically
    // Trying to stop it manually causes race conditions with Flutter's disposal
    
    super.dispose();
  }

  void _startTimer() {
    if (_timeLeft == null || _timeLeft! <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft! > 0) {
          _timeLeft = _timeLeft! - 1;
        } else {
          timer.cancel();
          // Optionally auto-submit or notify unity?
        }
      });
    });
  }

  /// Set up message polling for Unity communication
  /// Simple approach: Poll a message queue that Unity writes to
  void _setupMessagePolling(InAppWebViewController controller) {
    if (!kIsWeb) {
      return;
    }
    
    // Cancel any existing polling timer
    _messagePollingTimer?.cancel();
    
    // Poll the message queue every 50ms
    final pollInterval = const Duration(milliseconds: 50);
    
    _messagePollingTimer = Timer.periodic(pollInterval, (timer) async {
      // Check if widget is still mounted
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        // Get messages from queue
        // Try localStorage first (most reliable), then fallback to window queue
        final checkCode = '''
          (function() {
            try {
              // Method 1: Try localStorage (most reliable on web)
              var stored = localStorage.getItem('_flutter_handler_queue');
              if (stored) {
                var data = JSON.parse(stored);
                var messages = data.messages || [];
                if (messages.length > 0) {
                  // Clear localStorage after reading
                  localStorage.removeItem('_flutter_handler_queue');
                  // Also clear window queue if it exists
                  if (window._flutterMessageQueue) {
                    window._flutterMessageQueue = [];
                  }
                  return JSON.stringify({queue: messages, length: messages.length, access: 'localStorage'});
                }
              }
              
              // Method 2: Fallback to window queue
              if (window._flutterMessageQueue && window._flutterMessageQueue.length > 0) {
                var messages = window._flutterMessageQueue.slice();
                window._flutterMessageQueue = [];
                return JSON.stringify({queue: messages, length: messages.length, access: 'window'});
              }
              
              return JSON.stringify({queue: [], length: 0, access: 'empty'});
            } catch (e) {
              return JSON.stringify({queue: [], length: 0, access: 'error', error: e.message});
            }
          })();
        ''';
        
        String? result;
        try {
          // On web, evaluateJavascript returns null, so we need to use localStorage directly
          // Since we can't read return values, we'll use a workaround:
          // Read localStorage and write result to a known window variable, then check it
          
          if (kIsWeb) {
            // On web, read localStorage directly using dart:html (shared across origin)
            // Unity writes to localStorage, and we can read it from Flutter's main window
            try {
              final stored = html.window.localStorage['_flutter_handler_queue'];
              if (stored != null && stored.isNotEmpty) {
                final data = jsonDecode(stored) as Map<String, dynamic>;
                final messages = data['messages'] as List?;
                
                if (messages != null && messages.isNotEmpty) {
                  // Clear localStorage
                  html.window.localStorage.remove('_flutter_handler_queue');
                  
                  // Process each message
                  for (var message in messages) {
                    if (message is Map) {
                      await _handleWebMessage(message, controller);
                    }
                  }
                }
              }
            } catch (e) {
              // Silently handle error
            }
            // Set result to null to skip the normal processing below
            result = null;
          } else {
            result = await controller.evaluateJavascript(source: checkCode);
          }
        } catch (e) {
          result = null;
        }
        
        // Handle both string and already-parsed results
        String? jsonString = result;
        if (result != null && result.startsWith('"') && result.endsWith('"')) {
          // Result is JSON-encoded string, unquote it
          try {
            jsonString = jsonDecode(result) as String?;
          } catch (e) {
            // Not a JSON string, use as is
          }
        }
        
        if (jsonString != null && jsonString != '{"queue":[],"length":0}' && jsonString != 'null' && !jsonString.contains('"access":"none"') && !jsonString.contains('"access":"empty"')) {
          try {
            final data = jsonDecode(jsonString) as Map<String, dynamic>;
            final messages = data['queue'] as List?;
            
            if (messages != null && messages.isNotEmpty) {
              for (var message in messages) {
                if (message is Map) {
                  await _handleWebMessage(message, controller);
                }
              }
            }
          } catch (e) {
            // Silently handle error
          }
        }
      } catch (e) {
        // Silently handle error
      }
    });
  }


  /// Build UnityWidget for mobile platforms (iOS/Android)
  Widget _buildMobileUnityView() {
    return UnityWidget(
      onUnityCreated: (UnityWidgetController controller) {
        _sendUnityParameters(controller);
      },
      onUnityMessage: (message) async {
        await _handleUnityMessage(message);
      },
      fullscreen: false,
    );
  }

  /// Build InAppWebView for web platform (WebGL)
  Widget _buildWebUnityView() {
    return InAppWebView(
      key: ValueKey('unity_webview_${widget.level.levelId}'),
      initialUrlRequest: URLRequest(
        url: WebUri(
          Uri.base
              .resolve('assets/unity/index.html')
              .replace(
                queryParameters: {
                  'role': widget.userRole,
                  'level_Id': widget.level.levelId ?? '',
                  'user_Id': _userId ?? '',
                  'level_Type': widget.level.levelTypeName ?? 'HTML',
                },
              )
              .toString(),
        ),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) async {
        _webViewController = controller;
        _setupMessagePolling(controller);
      },
      onLoadStop: (controller, url) async {
        // Check if widget is still mounted before proceeding
        if (!mounted) return;
        
        // Wait a bit for Unity to initialize the bridge
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check again after delay
        if (!mounted) return;
        
        _setupMessagePolling(controller);
        
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
      onConsoleMessage: (controller, consoleMessage) async {
        // Check if widget is still mounted
        if (!mounted) return;
        
        // Listen for Unity messages sent via console.log
        final message = consoleMessage.message;
        
        // Check for messages from Unity's direct callHandler
        if (message.startsWith('__FLUTTER_HANDLER__:')) {
          try {
            if (!mounted) return;
            final jsonStr = message.substring('__FLUTTER_HANDLER__:'.length);
            final msgData = jsonDecode(jsonStr) as Map<String, dynamic>;
            await _handleWebMessage(msgData, controller);
          } catch (e) {
            // Silently handle error
          }
        }
        
        // Check for messages from polling (processed from localStorage)
        if (message.startsWith('__FLUTTER_HANDLER_MSG__:')) {
          try {
            if (!mounted) return;
            final jsonStr = message.substring('__FLUTTER_HANDLER_MSG__:'.length);
            final msgData = jsonDecode(jsonStr) as Map<String, dynamic>;
            await _handleWebMessage(msgData, controller);
          } catch (e) {
            // Silently handle error
          }
        }
      },
    );
  }

  /// Send initial parameters to Unity (mobile only)
  void _sendUnityParameters(UnityWidgetController controller) {
    if (_userId == null) return;
    
    final params = {
      'role': widget.userRole,
      'level_Id': widget.level.levelId ?? '',
      'user_Id': _userId ?? '',
      'level_Type': widget.level.levelTypeName ?? 'HTML',
    };
    
    controller.postMessage(
      'FlutterBridge',
      'onFlutterMessage',
      jsonEncode(params),
    );
  }

  /// Handle messages from Unity (works for both web and mobile)
  Future<void> _handleUnityMessage(dynamic message) async {
    try {
      if (message is String) {
        final msgData = jsonDecode(message) as Map<String, dynamic>;
        if (_webViewController != null) {
          await _handleWebMessage(msgData, _webViewController!);
        }
      } else if (message is Map) {
        if (_webViewController != null) {
          await _handleWebMessage(message, _webViewController!);
        }
      }
    } catch (e) {
      // Silently handle error
    }
  }

  /// Handle messages from Unity WebGL (web platform only)
  Future<void> _handleWebMessage(dynamic message, InAppWebViewController controller) async {
    if (!kIsWeb) {
      return;
    }
    
    // Check if widget is still mounted
    if (!mounted) return;

    try {
      Map<String, dynamic>? msg;
      if (message is String) {
        msg = jsonDecode(message) as Map<String, dynamic>;
      } else if (message is Map) {
        msg = message as Map<String, dynamic>;
      }

      if (msg == null) {
        return;
      }

      if (msg['type'] != 'FLUTTER_HANDLER_CALL') {
        return;
      }

      final handlerName = msg['handlerName'] as String?;
      final args = msg['args'] as List?;
      final callId = msg['callId'] as int?;

      if (handlerName == null || callId == null) {
        return;
      }

      dynamic result;
      String? error;

      try {
        // Check if widget is still mounted
        if (!mounted) {
          return;
        }
        
        switch (handlerName) {
          case 'getLevelFile':
            if (args != null && args.length >= 3) {
              final levelId =
                  args[0] as String? ?? widget.level.levelId ?? '';
              final type = (args[1] as String? ?? 'html').toLowerCase();
              final dataType = args[2] as String? ?? 'level';
              final useProgress =
                  args.length >= 4 ? (args[3] as bool? ?? false) : false;

              result = await _levelStorage.getFileContent(
                levelId: levelId,
                type: type,
                dataType: dataType,
                useProgress: useProgress,
                userId: _userId,
              );
              result = result ?? '';
            }
            break;

          case 'saveLevelFile':
            if (args != null && args.length >= 4) {
              final levelId =
                  args[0] as String? ?? widget.level.levelId ?? '';
              final type = (args[1] as String? ?? 'html').toLowerCase();
              final dataType = args[2] as String? ?? 'levelData';
              final content = args[3] as String? ?? '';

              result = await _levelStorage.saveDataFile(
                levelId: levelId,
                type: type,
                dataType: dataType,
                content: content,
                userId: _userId,
              );

              // After saving level file (only for level data, not win data), sync progress to server
              // Skip if user is teacher (teachers don't need to save progress)
              if (result == true && 
                  dataType.toLowerCase().contains('level') &&
                  widget.userRole.toLowerCase() != 'teacher') {
                // Don't await - let it run in background
                _syncProgressToServer(levelId);
              }
            } else {
              result = false;
            }
            break;

          case 'saveIndexFile':
            if (args != null && args.length >= 3) {
              final levelId =
                  args[0] as String? ?? widget.level.levelId ?? '';
              final type = (args[1] as String? ?? 'html').toLowerCase();
              final content = args[2] as String? ?? '';

              result = await _levelStorage.saveIndexFile(
                levelId: levelId,
                type: type,
                content: content,
                userId: _userId,
              );

              // After saving index file, sync progress to server
              // Skip if user is teacher (teachers don't need to save progress)
              if (result == true && widget.userRole.toLowerCase() != 'teacher') {
                // Don't await - let it run in background
                _syncProgressToServer(levelId);
              }
            } else {
              result = false;
            }
            break;

          case 'saveStudentProgress':
            if (args != null && args.length >= 2) {
              final levelId =
                  args[0] as String? ?? widget.level.levelId ?? '';
              final savedDataJson = args[1] as String?;
              // Handle indexFilesJson - it might be a bool (false) or null instead of string
              String? indexFilesJson;
              if (args.length >= 3 && args[2] != null) {
                if (args[2] is String) {
                  indexFilesJson = args[2] as String?;
                } else if (args[2] is bool && args[2] == false) {
                  // Unity might pass false instead of null/empty string
                  indexFilesJson = null;
                } else {
                  // Try to convert to string
                  indexFilesJson = args[2].toString();
                  if (indexFilesJson == 'false' || indexFilesJson.isEmpty) {
                    indexFilesJson = null;
                  }
                }
              } else {
                indexFilesJson = null;
              }

              // Skip if user is teacher (teachers don't need to save progress)
              if (widget.userRole.toLowerCase() == 'teacher') {
                result = true; // Return success but don't actually save
              } else {
                // Directly call GameAPI - no localStorage
                try {
                  await GameAPI.saveStudentProgress(
                    levelId: levelId,
                    savedData: savedDataJson,
                    indexFiles: indexFilesJson,
                  );
                  result = true;
                } catch (e) {
                  result = false;
                }
              }
            } else {
              result = false;
            }
            break;

          case 'completeLevel':
            if (args != null && args.isNotEmpty) {      
              final levelId =
                  args[0] as String? ?? widget.level.levelId ?? '';
              String? userId =
                  args.length >= 2 ? args[1] as String? : null;

              // Skip if user is teacher (teachers don't need to complete levels)
              if (widget.userRole.toLowerCase() == 'teacher') {
                result = true; // Return success but don't actually save
              } else {
                // Get userId if not provided
                if (userId == null || userId.isEmpty) {
                  final user = await AuthApi.getStoredUser();
                  userId = user?['user_id']?.toString();
                }

                // Directly call GameAPI - no localStorage
                try {
                  final response = await GameAPI.completeLevel(
                    levelId: levelId,
                    userId: userId ?? '',
                  );
                  result = response['success'] != false;
                } catch (e) {
                  result = false;
                }
              }
            } else {
              result = false;
            }
            break;

          default:
            error = 'Unknown handler: $handlerName';
        }
      } catch (e) {
        error = e.toString();
      }

      // Send response back to Unity via JavaScript
      final responseValue = error != null ? error : result;
      final responseJs = '''
        (function() {
          if (typeof window._flutterReceiveResponse === 'function') {
            try {
              window._flutterReceiveResponse(
                $callId,
                ${error == null},
                ${jsonEncode(responseValue)}
              );
            } catch (e) {
              // Silently handle error
            }
          }
        })();
      ''';
      
      try {
        await controller.evaluateJavascript(source: responseJs);
      } catch (e) {
        // Silently handle error
      }
    } catch (e) {
      // Silently handle error
    }
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Build savedData JSON from local storage and call GameAPI.saveStudentProgress
  /// This is a workaround since saveStudentProgress handler doesn't work reliably
  /// Skip if user is teacher (teachers don't need to save progress)
  Future<void> _syncProgressToServer(String levelId) async {
    // Skip if user is teacher
    if (widget.userRole.toLowerCase() == 'teacher') {
      return;
    }
    
    if (_userId == null || _userId!.isEmpty) {
      return;
    }

    try {

      // Build savedData JSON from progress files in local storage
      final Map<String, String> savedDataMap = {};
      final List<String> types = ['html', 'css', 'js', 'php'];

      for (final type in types) {
        try {
          final progressData = await _levelStorage.getFileContent(
            levelId: levelId,
            type: type,
            dataType: 'level',
            useProgress: true, // Get progress data
            userId: _userId,
          );
          if (progressData != null && progressData.isNotEmpty) {
            savedDataMap[type] = progressData;
          }
        } catch (e) {
          // Silently handle error
        }
      }

      // Convert to JSON string
      final savedDataJson = jsonEncode(savedDataMap);
      
      // Read index files (already in format: {"html": "...", "css": "...", "js": "...", "php": "..."})
      final indexFilesMap = await _levelStorage.readIndexFiles(
        levelId: levelId,
        userId: _userId,
      );
      final indexFilesJson = jsonEncode(indexFilesMap);

      // Call GameAPI.saveStudentProgress
      await GameAPI.saveStudentProgress(
        levelId: levelId,
        savedData: savedDataJson,
        indexFiles: indexFilesJson,
      );
    } catch (e) {
      // Don't throw - this is a background sync
    }
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
                    // Cancel timers first (synchronous, safe)
                    _timer?.cancel();
                    _messagePollingTimer?.cancel();
                    
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
                  widget.userRole.toLowerCase() == 'teacher' ? "View Level" : "Play Level",
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

                // Unity Widget (mobile) or WebView (web)
                Center(
                  child: SizedBox(
                    height: 1000,
                    width: 1250,
                    child: kIsWeb 
                      ? _buildWebUnityView() // Web: Use InAppWebView for WebGL
                      : _buildMobileUnityView(), // Mobile: Use UnityWidget
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
