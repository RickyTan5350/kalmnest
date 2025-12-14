import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_codelab/api/game_api.dart';

/// Opens the create game dialog
void showCreateGamePage({
  required BuildContext context,
  required String userRole, // Pass the current logged-in user role here
  required void Function(BuildContext context, String message, Color color)
      showSnackBar,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return CreateGamePage(
        showSnackBar: showSnackBar,
        parentContext: context,
        userRole: userRole,
      );
    },
  );
}

class CreateGamePage extends StatefulWidget {
  final void Function(BuildContext context, String message, Color color)
      showSnackBar;
  final BuildContext parentContext;
  final String userRole; // Current user role

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
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(),

                Text(
                  "Create Game",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.cyan),
                ),

                const SizedBox(height: 16),

                /// Level Name
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Enter level name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    levelName = value;
                  },
                ),

                const SizedBox(height: 16),

                /// Dropdown + Create Button
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedValue,
                      items: ['HTML', 'CSS', 'JS', 'PHP', 'Quiz']
                          .map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => selectedValue = newValue);
                        }
                      },
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

                        Navigator.of(context).pop();

                        final ApiResponse response = await GameAPI.createLevel(
                          levelName: levelName,
                          levelTypeName: selectedValue,
                        );

                        if (response.success) {
                          print(response.success);
                          print(response.message);

                          widget.showSnackBar(
                            widget.parentContext,
                            "Level created!",
                            Colors.green,
                          );
                        } else {
                          print(response.success);
                          print(response.message);

                          widget.showSnackBar(
                            widget.parentContext,
                            "Failed to create level: ${response.message}",
                            Colors.red,
                          );
                        }

                        previewKey.currentState
                            ?.reloadPreview(widget.userRole);
                      },
                      child: const Text('Create Level'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Unity WebView
                Center(
                  child: SizedBox(
                    height: 1000,
                    width: 1250,
                    child: LaravelWebView(userRole: widget.userRole),
                  ),
                ),

                const SizedBox(height: 16),

                /// Reload Preview Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        previewKey.currentState
                            ?.reloadPreview(widget.userRole);
                      },
                      child: const Text("Reload Preview"),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Preview Box
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

/// WebView showing Unity WebGL build
class LaravelWebView extends StatefulWidget {
  final String userRole;

  const LaravelWebView({super.key, required this.userRole});

  @override
  State<LaravelWebView> createState() => _LaravelWebViewState();
}

class _LaravelWebViewState extends State<LaravelWebView> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    final unityUrl =
        "https://backend_services.test/unity_build/index.html?role=${widget.userRole}";

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(unityUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        debugPrint("Started loading: $url");
      },
      onLoadStop: (controller, url) async {
        debugPrint("Finished loading: $url");
      },
      onLoadError: (controller, url, code, message) {
        debugPrint("Failed to load $url: $message");
      },
    );
  }
}

/// Preview of index.html file
class IndexFilePreview extends StatefulWidget {
  final String userRole;

  const IndexFilePreview({super.key, required this.userRole});

  @override
  State<IndexFilePreview> createState() => _IndexFilePreviewState();
}

class _IndexFilePreviewState extends State<IndexFilePreview> {
  late InAppWebViewController _webViewController;

  void reloadPreview(String userRole) {
    final url =
        "https://backend_services.test/unity_build/StreamingAssets/html/index.html";

    _webViewController.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url =
        "https://backend_services.test/unity_build/StreamingAssets/html/index.html";

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onLoadStart: (controller, url) {
        debugPrint("Started loading: $url");
      },
      onLoadStop: (controller, url) async {
        debugPrint("Finished loading: $url");
      },
      onLoadError: (controller, url, code, message) {
        debugPrint("Failed to load: $message");
      },
    );
  }
}
