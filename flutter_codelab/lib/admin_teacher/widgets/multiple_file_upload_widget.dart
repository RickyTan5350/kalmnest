// lib/widgets/multiple_file_upload_widget.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Make sure to add this dependency

class MultipleFileUploadWidget extends StatefulWidget {
  const MultipleFileUploadWidget({super.key});

  @override
  State<MultipleFileUploadWidget> createState() => _MultipleFileUploadWidgetState();
}

class _MultipleFileUploadWidgetState extends State<MultipleFileUploadWidget> {
  // Stores the list of selected files from the picker
  List<PlatformFile> _selectedFiles = [];

  // Maximum file size in bytes (2MB)
  static const int _maxFileSizeInBytes = 2 * 1024 * 1024;
  static const String _maxFileSizeLabel = '2MB';

  Future<void> _pickFiles() async {
    try {
      // Allow selecting multiple files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // Needed to check file size
      );

      if (result != null) {
        setState(() {
          // Filter out files that exceed the 2MB limit
          _selectedFiles = result.files.where((file) {
            // Check if file size is available and within the limit
            if (file.size > _maxFileSizeInBytes) {
              // Optionally show a snackbar or alert for files that are too large
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Skipped "${file.name}": File size exceeds $_maxFileSizeLabel.'),
                  backgroundColor: Colors.red,
                ),
              );
              return false;
            }
            return true;
          }).toList();
        });
      } else {
        // User canceled the picker
        // Optional: show a message if needed
      }
    } catch (e) {
      // Handle any errors during file picking
      print('Error picking files: $e');
    }
  }

  // Helper to format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    double kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    double mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title based on the image
          Text(
            "Multiple File Upload",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          // Subtitle based on the image
          Text(
            "Upload multiple files at once",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),

          // --- Drop/Click Area (The main box) ---
          GestureDetector(
            onTap: _pickFiles, // Trigger file selection on click
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
              decoration: BoxDecoration(
                // Use a border color that matches the subtle design in the image
                border: Border.all(
                  color: colors.onSurface.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8.0),
                // Use a very light background color
                color: colors.surface.withOpacity(0.9),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 40,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Drop multiple files here (max $_maxFileSizeLabel each)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'or click to browse',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.primary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // --- Display Selected Files ---
          if (_selectedFiles.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Files (${_selectedFiles.length}):',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ..._selectedFiles.map((file) {
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(file.name),
                    trailing: Text(_formatFileSize(file.size)),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

// Example usage in a parent widget:
/*
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Upload Example')),
      body: const MultipleFileUploadWidget(),
    );
  }
}
*/