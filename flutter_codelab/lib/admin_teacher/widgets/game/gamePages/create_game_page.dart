import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_codelab/api/game_api.dart';
import 'package:flutter_codelab/constants/api_constants.dart';

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
}) {
  showDialog(
    context: context,
    builder: (_) => CreateGamePage(
      showSnackBar: showSnackBar,
      parentContext: context,
      userRole: userRole,
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

  const CreateGamePage({
    super.key,
    required this.showSnackBar,
    required this.parentContext,
    required this.userRole,
  });

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  String selectedValue = 'HTML';
  String levelName = '';

  final GlobalKey<_IndexFilePreviewState> previewKey =
      GlobalKey<_IndexFilePreviewState>();

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(
                    labelText: 'Enter level name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => levelName = v,
                ),

                const SizedBox(height: 16),

                /// Dropdown + Create button
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedValue,
                      items: ['HTML', 'CSS', 'JS', 'PHP', 'Quiz']
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
                    ElevatedButton(
                      onPressed: () async {
                        if (levelName.isEmpty) {
                          widget.showSnackBar(
                            widget.parentContext,
                            "Level name is required",
                            Colors.red,
                          );
                          return;
                        }

                        Navigator.pop(context);

                        final response = await GameAPI.createLevel(
                          levelName: levelName,
                          levelTypeName: selectedValue,
                        );

                        widget.showSnackBar(
                          widget.parentContext,
                          response.success
                              ? "Level created!"
                              : "Failed to create level: ${response.message}",
                          response.success ? Colors.green : Colors.red,
                        );

                        previewKey.currentState?.reloadPreview(widget.userRole);
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
                          "${ApiConstants.domain}/unity_build/index.html?role=${widget.userRole}",
                        ),
                      ),
                      initialSettings: InAppWebViewSettings(
                        // Cross-platform settings
                        javaScriptEnabled: true,
                        isInspectable: kDebugMode,
                      ),
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

/// ===============================================================
/// index.html Preview WebView (Windows + Mobile)
/// ===============================================================
class IndexFilePreview extends StatefulWidget {
  final String userRole;

  const IndexFilePreview({super.key, required this.userRole});

  @override
  State<IndexFilePreview> createState() => _IndexFilePreviewState();
}

class _IndexFilePreviewState extends State<IndexFilePreview> {
  // Key to force rebuild on reload
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final url =
        "${ApiConstants.domain}/unity_build/StreamingAssets/html/index.html";

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
