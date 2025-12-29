import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<void> uploadFile() async {
  // 1. Pick the file
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    // 2. Get the file details
    // On Windows, file.path will have the full path to the file
    PlatformFile file = result.files.first;
    String? filePath = file.path;
    String fileName = file.name;

    print('DEBUG: File Path is: $filePath'); // <-- ADD THIS
    print('DEBUG: File Size from Picker: ${file.size} bytes');

    if (filePath == null) {
      print("File path is null, cannot upload.");
      return;
    }

    // 3. Define your server endpoint
    // This is the URL your server is listening on
    var uri = Uri.parse('https://kalmnest.test/api/notes/upload');

    // 4. Create the multipart request
    var request = http.MultipartRequest('POST', uri);

    // 5. Add the file to the request
    // 'file' is the field name your server will look for.
    // This must match your backend (e.g., $_FILES['file'] in PHP).
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName, // Pass the original filename
      ),
    );

    // You can also add other text fields to the request
    // request.fields['user_id'] = '123';

    try {
      // 6. Send the request
      var streamedResponse = await request.send();

      // 7. Get the response from the server
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('File uploaded successfully!');
        print('Server response: ${response.body}');
      } else {
        print('File upload failed.');
        print('Status code: ${response.statusCode}');
        print('Server response: ${response.body}');
      }
    } catch (e) {
      print('An error occurred while uploading: $e');
    }
  } else {
    // User canceled the file picker
    print('No file selected.');
  }
}
