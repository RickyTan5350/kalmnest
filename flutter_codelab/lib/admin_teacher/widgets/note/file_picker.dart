import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<List<PlatformFile>> pickAndUploadFiles() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      return result.files;
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error picking files: $e");
    }
  }
  return [];
}