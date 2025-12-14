import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  // Keep the internal properties for cases where you don't pass a name
  final String fileName;
  final String folderName;

  FileHelper({required this.fileName, required this.folderName});

  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // New utility getter to get a File reference for a SPECIFIC filename
  Future<File> getFileReference(String specificFileName) async {
    final rootPath = await localPath;

    // 1. Construct the full path to the new directory
    final String dirPath = '$rootPath/$folderName';

    // 2. Create the Directory object
    final Directory directory = Directory(dirPath);

    // 3. IMPORTANT: Check if the folder exists and create it if it doesn't
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      if (kDebugMode) {
        print('Created new directory: $dirPath');
      }
    }

    // 4. Return the File reference within the new sub-directory
    // Use the passed-in specificFileName instead of this.fileName
    return File('$dirPath/$specificFileName');
  }

  // Keep the original localFile getter for backward compatibility
  // (it uses the filename set in the constructor)
  Future<File> get localFile async {
    return getFileReference(fileName); // Delegate to the new utility method
  }

  // MODIFIED FUNCTION: Now accepts 'String fileName' as a required argument.
  Future<File> writeStringToFile({
    required String content,
    required String fileName, // The new argument
  }) async {
    // 1. Get the File reference using the new utility method and the passed-in fileName
    final file = await getFileReference(fileName);

    // 2. Write the content to the file.
    return file.writeAsString(content);
  }
}
