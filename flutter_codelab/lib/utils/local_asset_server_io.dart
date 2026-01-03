import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

/// A simple local server to serve assets from the filesystem.
/// This is useful for Unity WebGL which requires an HTTP server (not file://)
/// to load correctly without Cross-Origin errors.
class LocalAssetServer {
  HttpServer? _server;
  int _port = 0;

  int get port => _port;

  /// Starts the local server.
  /// [path] is the directory to serve (defaults to 'assets').
  /// [port] is the port to listen on (defaults to 0 for ephemeral).
  Future<void> start({String path = 'assets', int port = 0}) async {
    // Try to locate the assets directory
    // In Debug mode on Windows, 'assets' is typically in the project root (current directory).
    // In Release mode, it might be in 'data/flutter_assets/assets'.
    String servePath = path;

    if (!Directory(servePath).existsSync()) {
      // Check common fallback locations
      if (Directory('data/flutter_assets/$path').existsSync()) {
        servePath = 'data/flutter_assets/$path';
      } else if (Directory('build/flutter_assets/$path').existsSync()) {
        servePath = 'build/flutter_assets/$path';
      } else {
        print('WARNING: Could not find assets directory at $path. Server might return 404s.');
      }
    }

    print('LocalAssetServer: Serving $servePath');

    final staticHandler = createStaticHandler(
      servePath,
      defaultDocument: 'index.html',
      listDirectories: true,
    );

    // Middleware to add CORS headers
    final handler = Pipeline().addMiddleware((innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': '*',
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        });
      };
    }).addHandler(staticHandler);

    try {
      // Listen on loopback (localhost)
      _server = await io.serve(handler, InternetAddress.loopbackIPv4, port);
      _port = _server!.port;
      print('LocalAssetServer running on http://localhost:$_port');
    } catch (e) {
      print('Failed to start LocalAssetServer: $e');
      rethrow;
    }
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    print('LocalAssetServer stopped.');
  }
}
