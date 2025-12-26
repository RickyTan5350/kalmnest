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

  final GlobalKey<_IndexFilePreviewState> previewKey =
      GlobalKey<_IndexFilePreviewState>();

  final List<String> levelTypes = ['HTML', 'CSS', 'JS', 'PHP', 'Quiz'];

  LocalAssetServer? _server;
  String? _serverUrl;

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
    try {
      await _server!.start(path: 'assets');

      // Fetch user ID to pass to Unity
      final user = await AuthApi.getStoredUser();

      setState(() {
        _serverUrl = 'http://localhost:${_server!.port}';
        _userId = user?['id']?.toString();
      });
    } catch (e) {
      print("Error starting local server: $e");
    }
  }

  @override
  void dispose() {
    _server?.stop();
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
                  controller: TextEditingController(text: levelName),
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

                              final ApiResponse response =
                                  await GameAPI.updateLevel(
                                    levelId: widget.level.levelId!,
                                    levelName: levelName,
                                    levelTypeName: selectedValue,
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
                            if (args.length >= 3) {
                              final levelId = args[0] as String;
                              final type = args[1] as String;
                              final dataType = args[2] as String;
                              final content = args[3] as String;

                              final storage = LocalLevelStorage();
                              return await storage.saveDataFile(
                                levelId: levelId,
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
                            if (args.length >= 2) {
                              final levelId = args[0] as String;
                              final type = args[1] as String;
                              final content = args[2] as String;

                              final storage = LocalLevelStorage();
                              return await storage.saveIndexFile(
                                levelId: levelId,
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
                            if (args.length >= 3) {
                              final levelId = args[0] as String;
                              final type = args[1] as String;
                              final dataType = args[2] as String;

                              final storage = LocalLevelStorage();
                              return await storage.getFileContent(
                                levelId: levelId,
                                type: type,
                                dataType: dataType,
                              );
                            }
                            return null;
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
                      serverUrl: _serverUrl!,
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

  const IndexFilePreview({
    super.key,
    required this.userRole,
    required this.serverUrl,
  });

  @override
  State<IndexFilePreview> createState() => _IndexFilePreviewState();
}

class _IndexFilePreviewState extends State<IndexFilePreview> {
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final url =
        "${widget.serverUrl}/unity/StreamingAssets/html/index.html";

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
