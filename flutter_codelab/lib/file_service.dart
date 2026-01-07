import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // Import 'path' as 'p'

// This function will:
// 1. Let the user pick a file.
// 2. Copy it to a permanent local folder.
// 3. Return the new, permanent path to be saved in your database.

Future<String?> saveFileLocally() async {
  // 1. Let user pick a file
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'mp4', 'm4a', 'mov', 'gif', 'jpg', 'png'],
  );

  if (result != null && result.files.single.path != null) {
    File pickedFile = File(result.files.single.path!);
    String fileName = p.basename(pickedFile.path); // Get the original file name

    // 2. Get the app's private documents directory
    Directory appDir = await getApplicationDocumentsDirectory();
    String appFolderPath = appDir.path;

    // 3. Create a new, permanent path in the app's folder
    String newPath = p.join(appFolderPath, fileName);

    try {
      // 4. Copy the file to the new path
      File newFile = await pickedFile.copy(newPath);

      // 5. Return the new path to be saved in your database
      print("File saved locally at: ${newFile.path}");
      return newFile.path;
    } catch (e) {
      print("Error copying file: $e");
      return null;
    }
  } else {
    // User canceled the picker
    return null;
  }
}
