import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_codelab/models/level.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_codelab/utils/local_asset_server.dart';
import 'package:flutter_codelab/api/auth_api.dart';
import 'package:flutter_codelab/services/local_level_storage.dart';
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

  final GlobalKey<_IndexFilePreviewState> previewKey =
      GlobalKey<_IndexFilePreviewState>();

  final List<String> levelTypes = ['HTML', 'CSS', 'JS', 'PHP', 'Quiz'];

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
    _initServer().then((_) => _loadLevelDetails());
  }

  Future<void> _loadLevelDetails() async {
    if (widget.level.levelId != null) {
      await GameAPI.fetchLevelById(widget.level.levelId!, userRole: widget.userRole);
    }
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

      // Start preview server for local storage base path
      final storageBasePath = await _levelStorage.getBasePath(userId: userId);
      await _previewServer!.start(path: storageBasePath);

      setState(() {
        _serverUrl = 'http://localhost:${_server!.port}';
        _previewServerUrl = 'http://localhost:${_previewServer!.port}';
      });
    } catch (e) {
      print("Error starting local server: $e");
    }
  }

  @override
  void dispose() {
    _server?.stop();
    _previewServer?.stop();
    _nameController.dispose();
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
                  "Edit Level",
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.cyan),
                ),
                const SizedBox(height: 16),

                // Level Name TextField
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter level name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => levelName = value,
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
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (levelName.isEmpty) {
                                widget.showSnackBar(
                                  widget.parentContext,
                                  "Level name is required",
                                  Colors.red,
                                );
                                return;
                              }

                              setState(() => _saving = true);

                              if (kDebugMode) {
                                final storage = LocalLevelStorage();
                                final basePath = await storage.getBasePath(userId: _userId);
                                print('--- Edit Save Started ---');
                                print('Target Level ID: ${widget.level.levelId}');
                                print('Current _userId: $_userId');
                                print('Local Storage Path: $basePath');
                              }

                              // Sync Unity data from local storage back to server
                              final storage = LocalLevelStorage();
                              final levelTypes = ['html', 'css', 'js', 'php'];
                              
                              Map<String, String?> currentLevelData = {};
                              Map<String, String?> currentWinData = {};

                              final originalLevelData = widget.level.levelData != null ? jsonDecode(widget.level.levelData!) : {};
                              final originalWinData = widget.level.winCondition != null ? jsonDecode(widget.level.winCondition!) : {};

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
                                  print('Type $type: localLevel=${localLevel != null}, localWin=${localWin != null}');
                                }
                                currentLevelData[type] = localLevel ?? originalLevelData[type]?.toString();
                                currentWinData[type] = localWin ?? originalWinData[type]?.toString();
                              }

                               if (kDebugMode) {
                                 print('Syncing level data to server:');
                                 print('LevelData: ${jsonEncode(currentLevelData)}');
                                 print('WinCondition: ${jsonEncode(currentWinData)}');
                               }

                               final ApiResponse response =
                                   await GameAPI.updateLevel(
                                     levelId: widget.level.levelId!,
                                     levelName: levelName,
                                     levelTypeName: selectedValue,
                                     levelData: jsonEncode(currentLevelData),
                                     winCondition: jsonEncode(currentWinData),
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
                        // Handler for saving level data (triggered by Unity)
                        controller.addJavaScriptHandler(
                          handlerName: 'saveLevelFile',
                          callback: (args) async {
                            // Unity calls: window.flutter_inappwebview.callHandler('saveLevelFile', levelId, type, dataType, content)
                            if (args.length >= 4) {
                              final levelId = args[0] as String? ?? widget.level.levelId ?? '';
                              final type = (args[1] as String? ?? 'html').toLowerCase();
                              final dataType = args[2] as String? ?? 'levelData';
                              final content = args[3] as String? ?? '';

                              final storage = LocalLevelStorage();
                              return await storage.saveDataFile(
                                levelId: levelId,
                                userId: _userId, // Pass userId
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
                            // Unity calls: window.flutter_inappwebview.callHandler('saveIndexFile', levelId, type, content)
                            if (args.length >= 3) {
                              final levelId = args[0] as String? ?? widget.level.levelId ?? '';
                              final type = (args[1] as String? ?? 'html').toLowerCase();
                              final content = args[2] as String? ?? '';

                              final storage = LocalLevelStorage();
                              return await storage.saveIndexFile(
                                levelId: levelId,
                                userId: _userId, // Pass userId
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
                            // Unity calls: window.flutter_inappwebview.callHandler('getLevelFile', levelId, type, dataType, useProgress)
                            if (args.length >= 3) {
                              final levelId = args[0] as String? ?? widget.level.levelId ?? '';
                              final type = (args[1] as String? ?? 'html').toLowerCase();
                              final dataType = args[2] as String? ?? 'level'; // levelData or winData
                              final useProgress = args.length >= 4 
                                  ? (args[3] as bool? ?? false) 
                                  : false;

                              if (kDebugMode) {
                                print("EditMode -> getLevelFile: levelId=$levelId, type=$type, dataType=$dataType, useProgress=$useProgress");
                              }

                              final storage = LocalLevelStorage();
                              final content = await storage.getFileContent(
                                levelId: levelId,
                                userId: _userId, // Pass userId
                                type: type,
                                dataType: dataType,
                                useProgress: useProgress,
                                userRole: widget.userRole, // Added userRole
                              );

                              if (kDebugMode) {
                                print("EditMode -> content found: ${content != null}");
                              }
                              
                              return content ?? '';
                            }
                            return '';
                          },
                        );
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

    final url =
        "${widget.serverUrl}/${widget.levelId}/index/index.html";

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
