import 'dart:io';
import 'package:flutter/material.dart';
import 'package:code_play/models/uploaded_attachment.dart'; // Import the model

class AttachmentList extends StatelessWidget {
  final List<UploadedAttachment> attachments;
  final Function(int index) onRemove;
  final Function(String name, String url, bool isImage) onInsert;

  const AttachmentList({
    super.key,
    required this.attachments,
    required this.onRemove,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'New Attachments',
          style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attachments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = attachments[index];
            final file = item.localFile;
            final isImage = ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif']
                .contains(file.extension?.toLowerCase());

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: item.isFailed
                        ? colorScheme.error
                        : colorScheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(4)),
                  clipBehavior: Clip.hardEdge,
                  child: isImage && file.path != null
                      ? Image.file(File(file.path!), fit: BoxFit.cover)
                      : Icon(Icons.insert_drive_file,
                          color: colorScheme.primary),
                ),
                title: Text(file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: colorScheme.onSurface, fontSize: 14)),
                subtitle: item.isUploading
                    ? LinearProgressIndicator(
                        minHeight: 4, borderRadius: BorderRadius.circular(2))
                    : item.isFailed
                        ? Text('Failed',
                            style: TextStyle(
                                color: colorScheme.error, fontSize: 12))
                        : Text('Ready',
                            style: TextStyle(
                                color: colorScheme.primary, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // INSERT BUTTON
                    if (!item.isUploading &&
                        !item.isFailed &&
                        item.publicUrl != null)
                      IconButton(
                        icon: const Icon(Icons.add_link),
                        color: colorScheme.primary,
                        tooltip: 'Insert into text',
                        onPressed: () => onInsert(
                            file.name, item.publicUrl!, isImage),
                      ),
                    // REMOVE BUTTON
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: colorScheme.error,
                      onPressed: () => onRemove(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
