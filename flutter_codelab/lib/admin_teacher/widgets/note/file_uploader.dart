// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';

// class _FileUploader extends StatefulWidget {
//   final void Function(List<String> fileNames) onFilesSelected;
//   final List<String> selectedFileNames;
//   final ColorScheme colorScheme;

//   const _FileUploader({
//     required this.onFilesSelected,
//     required this.selectedFileNames,
//     required this.colorScheme,
//   });

//   @override
//   State<_FileUploader> createState() => _FileUploaderState();
// }

// class _FileUploaderState extends State<_FileUploader> {
//   static const int _maxFileSizeInBytes = 2 * 1024 * 1024;

//   Future<void> _pickFiles() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       withData: true,
//     );

//     if (result != null) {
//       List<String> validFileNames = [];

//       for (var file in result.files) {
//         if (file.size <= _maxFileSizeInBytes) {
//           validFileNames.add(file.name);
//         } else {
//           // --- NOTE: This SnackBar will now appear on the main page's Scaffold ---
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Skipped "${file.name}": File size exceeds 2MB.'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//       widget.onFilesSelected(validFileNames);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Media Files (Optional)',
//           style: TextStyle(color: widget.colorScheme.onSurfaceVariant),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             border: Border.all(color: widget.colorScheme.outlineVariant),
//             borderRadius: BorderRadius.circular(12),
//             color: widget.colorScheme.surfaceContainerHighest.withOpacity(0.3),
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: ElevatedButton.icon(
//                   onPressed: _pickFiles,
//                   icon: const Icon(Icons.cloud_upload),
//                   label: const Text('Upload Media (max 2MB each)'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: widget.colorScheme.secondary,
//                     foregroundColor: widget.colorScheme.onSecondary,
//                   ),
//                 ),
//               ),
//               if (widget.selectedFileNames.isNotEmpty)
//                 ...widget.selectedFileNames.map(
//                   (name) => ListTile(
//                     dense: true,
//                     leading: Icon(
//                       Icons.insert_drive_file,
//                       color: widget.colorScheme.secondary,
//                     ),
//                     title: Text(
//                       name,
//                       style: TextStyle(color: widget.colorScheme.onSurface),
//                     ),
//                     trailing: const Icon(
//                       Icons.check_circle,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ),
//               if (widget.selectedFileNames.isEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 16.0),
//                   child: Text(
//                     'No files selected.',
//                     style: TextStyle(
//                       color: widget.colorScheme.onSurfaceVariant.withOpacity(
//                         0.6,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
