import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:code_play/services/local_level_storage.dart';
import 'package:code_play/utils/web_utils.dart';

/// WebView preview for Unity build's generated index.html/js/css files.
/// This widget handles both native (LocalAssetServer) and web (Blob URLs) previews.
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
  String? _webUrl;
  Map<String, String>? _indexFiles; // Store all index files for serving

  @override
  void initState() {
    super.initState();
    _initWebPreview();
  }

  @override
  void didUpdateWidget(IndexFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverUrl != widget.serverUrl ||
        oldWidget.levelId != widget.levelId ||
        oldWidget.userId != widget.userId) {
      _initWebPreview();
    }
  }

  Future<void> _initWebPreview() async {
    if (!kIsWeb) return;

    // Revoke old URL if it exists to prevent memory leaks
    if (_webUrl != null) {
      WebUtils.revokeBlobUrl(_webUrl!);
    }

    final storage = LocalLevelStorage();
    
    // Load all index files (html, css, js, php)
    final htmlContent = await storage.getFileContent(
      levelId: widget.levelId,
      type: 'html',
      dataType: 'index',
      userId: widget.userId,
    );

    if (htmlContent == null) {
      return;
    }

    // Load CSS, JS, and PHP files and store them
    final cssContent = await storage.getFileContent(
      levelId: widget.levelId,
      type: 'css',
      dataType: 'index',
      userId: widget.userId,
    ) ?? '';

    final jsContent = await storage.getFileContent(
      levelId: widget.levelId,
      type: 'js',
      dataType: 'index',
      userId: widget.userId,
    ) ?? '';

    final phpContent = await storage.getFileContent(
      levelId: widget.levelId,
      type: 'php',
      dataType: 'index',
      userId: widget.userId,
    ) ?? '';

    // Store index files for serving via WebView intercept
    _indexFiles = {
      'index.html': htmlContent,
      'index.css': cssContent,
      'index.js': jsContent,
      'index.php': phpContent,
    };

    // Process HTML: Keep original references (link/script tags) intact
    // We'll use shouldInterceptRequest to serve the files when requested
    // Also inject inline versions as fallback
    String processedHtml = htmlContent;
    
    // Inject CSS as <style> tag if it exists (as fallback, but keep <link> tags)
    if (cssContent.isNotEmpty) {
      // Add <style> tag with CSS content in <head> (keep existing <link> tags)
      if (processedHtml.contains('</head>')) {
        processedHtml = processedHtml.replaceFirst(
          '</head>',
          '<style>\n$cssContent\n</style>\n</head>',
        );
      } else if (processedHtml.contains('<head>')) {
        processedHtml = processedHtml.replaceFirst(
          '<head>',
          '<head>\n<style>\n$cssContent\n</style>',
        );
      } else {
        // No <head> tag, add at the beginning
        processedHtml = '<head><style>\n$cssContent\n</style></head>\n$processedHtml';
      }
    }

    // Inject JS as <script> tag if it exists (as fallback, but keep <script src> tags)
    if (jsContent.isNotEmpty) {
      // Add <script> tag with JS content before </body> or at the end
      if (processedHtml.contains('</body>')) {
        processedHtml = processedHtml.replaceFirst(
          '</body>',
          '<script>\n$jsContent\n</script>\n</body>',
        );
      } else {
        // No </body> tag, add at the end
        processedHtml = '$processedHtml\n<script>\n$jsContent\n</script>';
      }
    }

    // Handle PHP - for preview, we can't execute PHP, but we can show it as a comment
    // or replace PHP tags with a comment indicating PHP code
    if (phpContent.isNotEmpty) {
      // Replace PHP references in HTML (like action="index.php") with a note
      // For now, we'll just add a comment at the top
      final phpComment = '<!-- PHP file content (not executed in preview):\n$phpContent\n-->';
      if (processedHtml.contains('<head>')) {
        processedHtml = processedHtml.replaceFirst(
          '<head>',
          '<head>\n$phpComment\n',
        );
      } else {
        processedHtml = '$phpComment\n$processedHtml';
      }
    }

    if (mounted) {
      setState(() {
        _webUrl = WebUtils.createBlobUrl(processedHtml, 'text/html');
      });
    }
  }

  @override
  void dispose() {
    if (_webUrl != null) {
      WebUtils.revokeBlobUrl(_webUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (_webUrl == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return InAppWebView(
        key: ValueKey('preview_webview_${widget.levelId}_$_webUrl'),
        initialUrlRequest: URLRequest(url: WebUri(_webUrl!)),
        initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
        shouldInterceptRequest: (controller, request) async {
          // Intercept requests for index.css, index.js, and index.php
          final url = request.url.toString();
          final urlLower = url.toLowerCase();
          
          // Check if this is a request for one of our index files (check URL contains the filename)
          String? fileName;
          String? mimeType;
          
          if (urlLower.contains('index.css')) {
            fileName = 'index.css';
            mimeType = 'text/css';
          } else if (urlLower.contains('index.js')) {
            fileName = 'index.js';
            mimeType = 'application/javascript';
          } else if (urlLower.contains('index.php')) {
            fileName = 'index.php';
            mimeType = 'application/x-httpd-php';
          }
          
          if (fileName != null && _indexFiles != null && _indexFiles!.containsKey(fileName)) {
            final content = _indexFiles![fileName]!;
            
            // Return the content as a response
            return WebResourceResponse(
              data: Uint8List.fromList(utf8.encode(content)),
              contentType: mimeType,
              statusCode: 200,
              headers: {'Content-Type': mimeType ?? 'text/plain'},
            );
          }
          
          return null; // Let default handling continue
        },
      );
    }

    if (widget.serverUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Preview points to the generated index folder within the level
    final url = "${widget.serverUrl}/${widget.levelId}/Index/index.html";

    return InAppWebView(
      key: ValueKey('preview_webview_${widget.levelId}'),
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: kDebugMode,
      ),
    );
  }

  void reloadPreview(String userRole) async {
    if (kIsWeb) {
      await _initWebPreview();
    }
    if (mounted) {
      setState(() {
        // Force rebuild if needed
      });
    }
  }
}
