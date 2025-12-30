import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:code_play/constants/api_constants.dart';

class FileApi {
  // Use 10.0.2.2 for Android Emulator, or your machine's IP for real devices.
  // kalmnest.test works if you have host mapping set up.
  static String get _domain => ApiConstants.domain;
  final String _baseUrl = '$_domain/api';

  /// 1. IMMEDIATE UPLOAD: Uploads a single file and returns ID + URL
  /// Returns a Map: {'id': 'uuid...', 'url': 'http://.../storage/img.png'}
  Future<Map<String, dynamic>?> uploadSingleAttachment(
    PlatformFile file,
  ) async {
    if (file.path == null) return null;

    var uri = Uri.parse('$_baseUrl/files/upload-independent');
    var request = http.MultipartRequest('POST', uri);

    // --- FIX: Tell the server we want JSON, not HTML ---
    request.headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path!,
        filename: file.name,
      ),
    );

    try {
      print('DEBUG: Uploading ${file.name} immediately...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        print('SUCCESS: File saved. JSON: $json');

        // Handle URL Construction
        String rawUrl = json['file_url'];
        String fullUrl;

        // If Laravel returns a relative path (e.g. /storage/...), prepend the domain
        if (!rawUrl.startsWith('http')) {
          fullUrl = '$_domain$rawUrl';
        } else {
          fullUrl = rawUrl;
        }

        return {'id': json['file_id'], 'url': fullUrl};
      } else {
        // Now you will see the REAL error message here (e.g. "File too large")
        print('FAILED: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ERROR: $e');
      return null;
    }
  }

  /// 2. FINAL SUBMIT: Sends Note Data + Markdown File + List of Attachment IDs
  Future<bool> createNoteWithLinkedFiles({
    required String title,
    required bool visibility,
    required String topic,
    required File markdownFile,
    required List<String> attachmentIds,
  }) async {
    var uri = Uri.parse('$_baseUrl/notes/new');
    var request = http.MultipartRequest('POST', uri);

    // --- FIX: Add header here too for consistency ---
    request.headers['Accept'] = 'application/json';

    request.fields['title'] = title;
    request.fields['topic'] = topic;
    request.fields['visibility'] = visibility ? '1' : '0';

    for (int i = 0; i < attachmentIds.length; i++) {
      request.fields['attachment_ids[$i]'] = attachmentIds[i];
    }

    if (await markdownFile.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('file', markdownFile.path),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Create Note Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}

