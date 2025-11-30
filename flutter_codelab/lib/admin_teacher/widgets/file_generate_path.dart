import 'package:file_picker/file_picker.dart';
import 'dart:io';

class FilePathGenerator{
  // Method to open the file picker and return the path
  Future<String?> pickFileAndGetPath() async {
    // 1. Open the file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'jpg', 'png'], // Specify file types
    );
    // 2. Check if a file was selected
    if (result != null) {
      // 3. Get the PlatformFile object (the first file if multiple selection is off)
      PlatformFile platformFile = result.files.first;
      // The path of the selected file on the local device
      String? absolutePath = platformFile.path;
      
      // If you need the directory and filename separately:
      if (absolutePath != null) {
        // 'directory' will be the folder the file is in
        String directoryPath = Directory(absolutePath).parent.path;
        // 'filename' will be the name and extension
        String filename = platformFile.name; 

        // The path structure you asked for (e.g., /User/documents/file.pdf)
        String generatedPath = '$directoryPath/$filename';
        
        print('Selected File Path: $generatedPath');
        return generatedPath;
      }
    } else {
      // User canceled the picker
      print('File picking canceled by the user.');
      return null;
    }
    return null;
  }

}