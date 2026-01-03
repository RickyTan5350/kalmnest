import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/api/achievement_api.dart';
import 'package:code_play/models/achievement_data.dart';
import 'package:code_play/utils/local_asset_server.dart';
import 'package:code_play/api/auth_api.dart';

import 'package:code_play/services/local_level_storage.dart';
import 'dart:convert';
import 'package:code_play/admin_teacher/widgets/game/index_file_preview.dart';

/// ===============================================================
/// Platform helper (SAFE for Web)
/// ===============================================================
bool get isWindows =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

/// ===============================================================
/// Opens the create game dialog
/// ===============================================================
void showCreateGamePage({
  required BuildContext context,
  required String userRole,
  required void Function(BuildContext context, String message, Color color)
  showSnackBar,
  Function(String? levelId)? onLevelCreated,
}) {
  showDialog(
    context: context,
    builder: (_) => CreateGamePage(
      showSnackBar: showSnackBar,
      parentContext: context,
      userRole: userRole,
      onLevelCreated: onLevelCreated,
    ),
  );
}

/// ===============================================================
/// Create Game Page
/// ===============================================================
class CreateGamePage extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
  showSnackBar;
  final BuildContext parentContext;
  final String userRole;
  final Function(String? levelId)? onLevelCreated;

  const CreateGamePage({
    super.key,
    required this.showSnackBar,
    required this.parentContext,
    required this.userRole,
    this.onLevelCreated,
  });

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  String selectedValue = 'HTML';
  String levelName = '';
  // Validation state
  bool _nameError = false;
  // Timer state
  final TextEditingController _timerController = TextEditingController(
    text: '0',
  );

  final GlobalKey<IndexFilePreviewState> previewKey =
      GlobalKey<IndexFilePreviewState>();

  LocalAssetServer? _server;
  LocalAssetServer? _previewServer;
  String? _serverUrl;
  String? _previewServerUrl;

  String? _userId;

  @override
  void initState() {
    super.initState();
    if (widget.userRole.toLowerCase() == 'teacher') {
      selectedValue = 'Quiz';
    }
    _initServer();
  }

  Future<void> _clearTempData() async {
    if (_userId == null) return;
    final storage = LocalLevelStorage();
    await storage.clearLevelData('temp', userId: _userId);
  }

  Future<void> _initServer() async {
    _server = LocalAssetServer();
    _previewServer = LocalAssetServer();
    try {
      await _server!.start(path: 'assets');

      // Fetch user ID to pass to Unity
      final user = await AuthApi.getStoredUser();
      final userId = user?['user_id']?.toString();

      setState(() {
        _userId = userId;
      });

      // Clear any existing temp data for this user
      await _clearTempData();

      if (kIsWeb) {
        setState(() {
          _serverUrl = 'assets';
          _previewServerUrl = '';
          _userId = userId;
        });
      } else {
        // Start preview server for local storage
        final storage = LocalLevelStorage();
        final storageBasePath = await storage.getBasePath(userId: userId);
        await _previewServer!.start(path: storageBasePath);

        await _server!.start(path: 'assets');

        setState(() {
          _serverUrl = 'http://localhost:${_server!.port}';
          _previewServerUrl = 'http://localhost:${_previewServer!.port}';
          _userId = userId;
        });
      }
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
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackButton(),
                Text(
                  "Create Game",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.cyan),
                ),
                const SizedBox(height: 16),

                /// Level name
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter level name *',
                    border: const OutlineInputBorder(),
                    errorText: _nameError ? 'Level name is required' : null,
                  ),
                  onChanged: (v) {
                    levelName = v;
                    if (_nameError && v.isNotEmpty) {
                      setState(() {
                        _nameError = false;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                /// Dropdown + Create button
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedValue,
                      items:
                          (widget.userRole.toLowerCase() == 'teacher'
                                  ? ['Quiz']
                                  : ['HTML', 'CSS', 'JS', 'PHP', 'Quiz'])
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(e),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => selectedValue = v!),
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
                      onPressed: () async {
                        if (levelName.isEmpty) {
                          setState(() {
                            _nameError = true;
                          });
                          return;
                        }

                        // Call API first (keep dialog open to show loading if we wanted, but current flow pops first?
                        // Existing code popped first. We should probably keep it open until success?
                        // But to duplicate existing behavior:
                        // Actually, let's keep it open, show loading?
                        // The user request says "when the user submits... show an extra dialog".
                        // Let's stick to: Call API -> If success -> Pop Game Dialog -> Ask about Achievement.

                        // Read data from temp storage
                        final storage = LocalLevelStorage();
                        final levelTypes = ['html', 'css', 'js', 'php'];

                        Map<String, String?> tempLevelData = {};
                        Map<String, String?> tempWinData = {};

                        for (final type in levelTypes) {
                          tempLevelData[type] = await storage.getFileContent(
                            levelId: 'temp',
                            type: type,
                            dataType: 'level',
                            userId: _userId, // Added userId
                            userRole: widget.userRole,
                          );
                          tempWinData[type] = await storage.getFileContent(
                            levelId: 'temp',
                            type: type,
                            dataType: 'win',
                            userId: _userId, // Added userId
                            userRole: widget.userRole,
                          );
                        }

                        final response = await GameAPI.createLevel(
                          levelName: levelName,
                          levelTypeName: selectedValue,
                          levelData: jsonEncode(tempLevelData),
                          winCondition: jsonEncode(tempWinData),
                          timer: int.tryParse(_timerController.text) ?? 0,
                        );

                        if (!mounted) return;

                        Navigator.pop(context); // Close Create Game Dialog

                        widget.showSnackBar(
                          widget.parentContext,
                          response.success
                              ? "Level created!"
                              : "Failed to create level: ${response.message}",
                          response.success ? Colors.green : Colors.red,
                        );

                        if (response.success) {
                          // Clear temp data after successful creation
                          await _clearTempData();

                          // Extract data
                          final data = response.data;
                          // Check for different possible JSON structures
                          // 1. { "level": { "level_id": "...", "level_name": "..." } }
                          // 2. { "level_id": "...", "level_name": "..." }
                          // 3. { "data": { ... } }

                          String? newLevelId;
                          String? newLevelName;

                          if (data != null) {
                            print(
                              "Game Creation Response Data: $data",
                            ); // Debug log
                            try {
                              if (data.containsKey('level') &&
                                  data['level'] is Map) {
                                final lvl = data['level'];
                                newLevelId = lvl['level_id']?.toString();
                                newLevelName = lvl['level_name']?.toString();
                              } else if (data.containsKey('level_id')) {
                                newLevelId = data['level_id']?.toString();
                                newLevelName = data['level_name']?.toString();
                              }
                            } catch (e) {
                              print("Error parsing game data: $e");
                            }
                          }

                          // Call callback with level ID if provided
                          if (widget.onLevelCreated != null &&
                              newLevelId != null) {
                            widget.onLevelCreated!(newLevelId);
                          }

                          // --- NEW: Automatically create achievement ---
                          if (newLevelId != null) {
                            String iconStr = selectedValue.toLowerCase();
                            if (iconStr == 'js') {
                              iconStr = 'javascript';
                            }

                            try {
                              await AchievementApi().createAchievement(
                                AchievementData(
                                  achievementName: newLevelName ?? levelName,
                                  achievementTitle: newLevelName ?? levelName,
                                  achievementDescription:
                                      "completion of ${newLevelName ?? levelName}",
                                  levelId: newLevelId,
                                  icon: iconStr,
                                ),
                              );
                              if (widget.parentContext.mounted) {
                                widget.showSnackBar(
                                  widget.parentContext,
                                  "Achievement created automatically!",
                                  Colors.green,
                                );
                              }
                            } catch (e) {
                              if (widget.parentContext.mounted) {
                                widget.showSnackBar(
                                  widget.parentContext,
                                  "Level created, but failed to create automatic achievement: $e",
                                  Colors.orange,
                                );
                              }
                            }
                          }
                        }
                      },
                      child: const Text("Create Level"),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// Unity WebView
                Center(
                  child: SizedBox(
                    height: 1000,
                    width: 1250,
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(
                          "$_serverUrl/unity/index.html?role=${widget.userRole}&user_Id=$_userId&level_Id=temp&level_Type=$selectedValue",
                        ),
                      ),
                      initialSettings: InAppWebViewSettings(
                        // Cross-platform settings
                        javaScriptEnabled: true,
                        //isInspectable: kDebugMode,
                      ),
                      onWebViewCreated: (controller) {
                        // Handler for saving level data (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'saveLevelFile',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('saveLevelFile', levelId, type, dataType, content)
                            if (args.length >= 4) {
                              final levelId = args[0] as String? ?? 'temp';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final dataType =
                                  args[2] as String? ?? 'levelData';
                              final content = args[3] as String? ?? '';

                              final storage = LocalLevelStorage();
                              return await storage.saveDataFile(
                                levelId: levelId,
                                type: type,
                                dataType: dataType,
                                content: content,
                                userId: _userId,
                              );
                            }
                            return false;
                          },
                        );

                        // Handler for saving index file (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'saveIndexFile',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('saveIndexFile', levelId, type, content)
                            if (args.length >= 3) {
                              final levelId = args[0] as String? ?? 'temp';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final content = args[2] as String? ?? '';

                              final storage = LocalLevelStorage();
                              return await storage.saveIndexFile(
                                levelId: levelId,
                                type: type,
                                content: content,
                                userId: _userId,
                              );
                            }
                            return false;
                          },
                        );

                        // Handler for getting level files (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'getLevelFile',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('getLevelFile', levelId, type, dataType, useProgress)
                            if (args.length >= 3) {
                              final levelId = args[0] as String? ?? 'temp';
                              final type = (args[1] as String? ?? 'html')
                                  .toLowerCase();
                              final dataType =
                                  args[2] as String? ?? 'levelData';
                              final useProgress = args.length >= 4
                                  ? (args[3] as bool? ?? false)
                                  : false;

                              final storage = LocalLevelStorage();
                              return await storage.getFileContent(
                                levelId: levelId,
                                type: type,
                                dataType: dataType,
                                useProgress: useProgress,
                                userId: _userId,
                                userRole: widget.userRole, // Added userRole
                              );
                            }
                            return '';
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// Reload preview
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () =>
                        previewKey.currentState?.reloadPreview(widget.userRole),
                    child: const Text("Reload Preview"),
                  ),
                ),

                const SizedBox(height: 16),

                /// Index.html preview
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
                      serverUrl: _previewServerUrl ?? '',
                      levelId: 'temp',
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
