import 'package:shelf/shelf.dart';
import 'dart:convert';
import 'package:code_play/services/local_level_storage.dart';
import 'package:code_play/api/game_api.dart';
import 'package:code_play/api/auth_api.dart';

/// Extended LocalAssetServer with API endpoints for Unity
/// Unity can make HTTP requests to these endpoints instead of using JavaScript bridge
class LocalAssetServerApi {
  final LocalLevelStorage _levelStorage;
  String? _userId;
  
  LocalAssetServerApi(this._levelStorage);
  
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Create API handler middleware
  Handler createApiHandler(Handler staticHandler) {
    return Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_apiMiddleware())
        .addHandler(staticHandler);
  }

  /// CORS middleware for Unity WebGL requests
  Middleware _corsMiddleware() {
    return (innerHandler) {
      return (request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders());
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders());
      };
    };
  }

  Map<String, String> _corsHeaders() {
    return {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400',
      'Content-Type': 'application/json',
    };
  }

  /// API middleware to handle Unity API requests
  Middleware _apiMiddleware() {
    return (innerHandler) {
      return (request) async {
        // Handle API endpoints
        if (request.url.path.startsWith('api/')) {
          return await _handleApiRequest(request);
        }
        // Otherwise, serve static files
        return await innerHandler(request);
      };
    };
  }

  /// Handle API requests from Unity
  Future<Response> _handleApiRequest(Request request) async {
    try {
      final path = request.url.path.replaceFirst('api/', '');

      switch (path) {
        case 'getLevelFile':
          return await _handleGetLevelFile(request);
        case 'saveLevelFile':
          return await _handleSaveLevelFile(request);
        case 'saveIndexFile':
          return await _handleSaveIndexFile(request);
        case 'saveStudentProgress':
          return await _handleSaveStudentProgress(request);
        case 'completeLevel':
          return await _handleCompleteLevel(request);
        default:
          return Response.notFound(
            jsonEncode({'error': 'Endpoint not found'}),
            headers: {'Content-Type': 'application/json'},
          );
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/getLevelFile?levelId=...&type=...&dataType=...&useProgress=...
  Future<Response> _handleGetLevelFile(Request request) async {
    final params = request.url.queryParameters;
    final levelId = params['levelId'] ?? '';
    final type = params['type'] ?? 'html';
    final dataType = params['dataType'] ?? 'level';
    final useProgress = params['useProgress'] == 'true';

    if (levelId.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'levelId is required'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    try {
      final content = await _levelStorage.getFileContent(
        levelId: levelId,
        type: type,
        dataType: dataType,
        useProgress: useProgress,
        userId: _userId,
      );

      return Response.ok(
        jsonEncode({'success': true, 'content': content ?? ''}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/saveLevelFile
  Future<Response> _handleSaveLevelFile(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final levelId = body['levelId'] as String? ?? '';
      final type = body['type'] as String? ?? 'html';
      final dataType = body['dataType'] as String? ?? 'level';
      final content = body['content'] as String? ?? '';

      if (levelId.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'levelId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _levelStorage.saveDataFile(
        levelId: levelId,
        type: type,
        dataType: dataType,
        content: content,
        userId: _userId,
      );

      return Response.ok(
        jsonEncode({'success': success}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/saveIndexFile
  Future<Response> _handleSaveIndexFile(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final levelId = body['levelId'] as String? ?? '';
      final type = body['type'] as String? ?? 'html';
      final content = body['content'] as String? ?? '';

      if (levelId.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'levelId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _levelStorage.saveIndexFile(
        levelId: levelId,
        type: type,
        content: content,
        userId: _userId,
      );

      return Response.ok(
        jsonEncode({'success': success}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/saveStudentProgress
  /// Always syncs to Laravel server after saving locally
  Future<Response> _handleSaveStudentProgress(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final levelId = body['levelId'] as String? ?? '';
      final savedDataJson = body['savedData'] as String?;

      if (levelId.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'levelId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Save locally
      final localSuccess = await _levelStorage.saveStudentProgress(
        levelId: levelId,
        savedDataJson: savedDataJson,
        userId: _userId,
      );

      // Always sync to server - call GameAPI regardless of savedDataJson being null
      try {
        final indexFilesMap = await _levelStorage.readIndexFiles(
          levelId: levelId,
          userId: _userId,
        );
        final indexFilesJson = jsonEncode(indexFilesMap);

        await GameAPI.saveStudentProgress(
          levelId: levelId,
          savedData: savedDataJson ?? indexFilesJson,
          indexFiles: indexFilesJson,
        );
      } catch (e) {
        // Continue - local save succeeded
      }

      return Response.ok(
        jsonEncode({'success': localSuccess}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/completeLevel
  Future<Response> _handleCompleteLevel(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final levelId = body['levelId'] as String? ?? '';
      String? userId = body['userId'] as String?;

      if (levelId.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'levelId is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get userId if not provided
      if (userId == null || userId.isEmpty) {
        final user = await AuthApi.getStoredUser();
        userId = user?['user_id']?.toString();
      }

      // Always call GameAPI.completeLevel regardless of userId validation
      // (userId will be validated by the backend)
      final response = await GameAPI.completeLevel(
        levelId: levelId,
        userId: userId ?? '',
      );

      return Response.ok(
        jsonEncode({'success': response['success'] != false}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}

