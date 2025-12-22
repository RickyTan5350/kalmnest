import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class FileManager extends StatefulWidget {
  final String noteTitle;

  const FileManager({super.key, required this.noteTitle});

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String? _error;
  late String _targetPath;

  @override
  void initState() {
    super.initState();
    _initPath();
  }

  Future<void> _initPath() async {
    // Determine the path to assets/www/<NoteTitle>
    // In Debug/Desktop mode, we assume CWD is project root.
    // We try to find 'assets/www'
    try {
      final cwd = Directory.current;
      final assetsWwwPath = p.join(cwd.path, 'assets', 'www');
      final assetsWww = Directory(assetsWwwPath);

      print("Debug: Checking assets path: ${assetsWww.path}");

      if (await assetsWww.exists()) {
        final cleanTitle = widget.noteTitle
            .replaceAll(RegExp(r'[\r\n]+'), ' ')
            .trim();
        final noteDir = Directory(p.join(assetsWww.path, cleanTitle));
        if (!await noteDir.exists()) {
          await noteDir.create(recursive: true);
          print("Debug: Created directory: ${noteDir.path}");
        }
        _targetPath = noteDir.path;
        _listFiles();
      } else {
        setState(() {
          _error =
              "Could not find 'assets/www' in ${cwd.path}. Ensure you are running from project root.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error initializing path: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _listFiles() async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory(_targetPath);
      final List<FileSystemEntity> files = dir.listSync();
      setState(() {
        _files = files.where((e) => e is File).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error listing files: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final destPath = p.join(_targetPath, fileName);

      try {
        await sourceFile.copy(destPath);
        print("Debug: Uploaded file to $destPath");
        _listFiles();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Uploaded $fileName")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error uploading: $e")));
      }
    }
  }

  Future<void> _createFile() async {
    String newName = "new_file.txt";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New File"),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: "Filename"),
          onChanged: (v) => newName = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              if (newName.trim().isEmpty) return;

              final file = File(p.join(_targetPath, newName));
              if (await file.exists()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File already exists")),
                );
                return;
              }

              try {
                await file.writeAsString(""); // Create empty file
                print("Debug: Created file ${file.path}");
                _listFiles();
              } catch (e) {
                print("Debug: Error creating file: $e");
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        print("Debug: Deleted file ${file.path}");
        _listFiles();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Note Assets (assets/www/...)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: "Create File",
                    onPressed: _createFile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: "Upload File",
                    onPressed: _uploadFile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: "Refresh",
                    onPressed: _listFiles,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_files.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No files found. Upload or create one."),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            final name = file.path.split(Platform.pathSeparator).last;
            return ListTile(
              leading: const Icon(Icons.description),
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _deleteFile(file),
              ),
              onTap: () {
                // Future: Open in editor?
              },
            );
          },
        ),
      ],
    );
  }
}
