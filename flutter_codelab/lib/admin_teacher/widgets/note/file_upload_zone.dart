import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_codelab/theme.dart';

class UploadedAttachment {
  final PlatformFile localFile;
  final String? serverFileId;
  final String? publicUrl;
  final bool isUploading;
  final bool isFailed;

  UploadedAttachment({
    required this.localFile,
    this.serverFileId,
    this.publicUrl,
    this.isUploading = false,
    this.isFailed = false,
  });
}

class FileUploadZone extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final List<UploadedAttachment> attachments;
  final Function(int) onRemove;
  final Function(UploadedAttachment) onInsertLink;
  final Function(UploadedAttachment) onInsertCode;

  const FileUploadZone({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.attachments = const [],
    required this.onRemove,
    required this.onInsertLink,
    required this.onInsertCode,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final borderColor = colorScheme.outlineVariant;
    final boxColor = isDarkMode
        ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
        : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Text ---
        Text(
          'Multiple File Upload',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload files (Images, HTML, CSS, JS, PHP)',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        // --- Clickable Upload Area ---
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                  style: BorderStyle
                      .none, // Using dotted border via package if preferred, but standard is fine
                ),
              ),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop multiple files here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Max 20MB each',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAttachmentList(context, colorScheme),
        ],
      ],
    );
  }

  Widget _buildAttachmentList(BuildContext context, ColorScheme colorScheme) {
    final brandColors = Theme.of(context).extension<BrandColors>();

    return Column(
      children: attachments.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final file = item.localFile;
        final ext = file.extension?.toLowerCase() ?? '';

        final isImage = [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'bmp',
          'gif',
        ].contains(ext);
        final isCode = ['html', 'css', 'js', 'php'].contains(ext);

        Color iconColor = colorScheme.primary;
        if (isCode && brandColors != null) {
          if (ext == 'html')
            iconColor = brandColors.html;
          else if (ext == 'css')
            iconColor = brandColors.css;
          else if (ext == 'js')
            iconColor = brandColors.javascript;
          else if (ext == 'php')
            iconColor = brandColors.php;
        } else if (isCode) {
          // Fallbacks if brandColors missing but code
          if (ext == 'html')
            iconColor = Colors.orange;
          else if (ext == 'css')
            iconColor = Colors.blue;
          else if (ext == 'js')
            iconColor = Colors.yellow;
          else if (ext == 'php')
            iconColor = Colors.indigo;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: item.isFailed
                    ? colorScheme.error
                    : colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.hardEdge,
                child: isImage && file.path != null
                    ? Image.file(
                        File(file.path!),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.broken_image,
                          size: 20,
                          color: colorScheme.error,
                        ),
                      )
                    : isCode
                    ? Icon(Icons.code, color: iconColor)
                    : Icon(Icons.insert_drive_file, color: colorScheme.primary),
              ),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
              subtitle: item.isUploading
                  ? LinearProgressIndicator(
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    )
                  : item.isFailed
                  ? Text(
                      'Failed',
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    )
                  : SelectableText(
                      item.publicUrl ?? '',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!item.isUploading && !item.isFailed) ...[
                    if (isCode)
                      IconButton(
                        icon: const Icon(Icons.data_object),
                        color: colorScheme.primary,
                        tooltip: 'Insert Code Block',
                        onPressed: () => onInsertCode(item),
                      )
                    else if (isImage || item.publicUrl != null)
                      IconButton(
                        icon: const Icon(Icons.add_link),
                        color: colorScheme.primary,
                        tooltip: 'Insert',
                        onPressed: () => onInsertLink(item),
                      ),
                  ],

                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: colorScheme.error,
                    tooltip: 'Remove',
                    onPressed: () => onRemove(index),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

