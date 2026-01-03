import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:code_play/services/local_level_storage.dart';

class IndexFilePreview extends StatefulWidget {
  final String userRole;
  final String serverUrl;
  final String levelId;
  final String? userId;

  const IndexFilePreview({
    super.key,
    required this.userRole,
    required this.serverUrl,
    required this.levelId,
    this.userId,
  });

  @override
  State<IndexFilePreview> createState() => IndexFilePreviewState();
}

class IndexFilePreviewState extends State<IndexFilePreview> {
  Key _key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && widget.serverUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb) {
      // On Web, we load the content directly from storage because we can't serve local files
      return FutureBuilder<Map<String, String>>(
        future: LocalLevelStorage().readIndexFiles(
          levelId: widget.levelId,
          userId: widget.userId,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!['html'] == null) {
            return const Center(child: Text("Generating Preview..."));
          }
          final html = snapshot.data!['html'] ?? '';
          final css = snapshot.data!['css'] ?? '';
          final js = snapshot.data!['js'] ?? '';

          // Construct full HTML with proper viewport interaction
          final fullHtml =
              """
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
$css
</style>
</head>
<body>
$html
<script>
$js
</script>
</body>
</html>
""";
          return InAppWebView(
            key: _key,
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              isInspectable: kDebugMode,
            ),
            onWebViewCreated: (controller) {
              controller.loadData(data: fullHtml);
            },
          );
        },
      );
    }

    // Native implementation
    // Preview points to the generated index folder within the level
    // Add timestamp to bust cache
    final url =
        "${widget.serverUrl}/${widget.levelId}/Index/index.html?t=${DateTime.now().millisecondsSinceEpoch}";

    return InAppWebView(
      key: _key,
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: kDebugMode,
        cacheEnabled: false,
        clearCache: true,
      ),
    );
  }

  void reloadPreview(String userRole) {
    setState(() {
      _key = UniqueKey();
    });
  }
}
