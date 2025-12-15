import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart'; // Optional: Add 'dotted_border' to pubspec.yaml if you want dots, otherwise standard border works.

class FileUploadZone extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const FileUploadZone({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Colors derived from your theme or fixed for specific look
    final borderColor = colorScheme.outlineVariant;
    final boxColor = isDarkMode 
        ? colorScheme.surfaceVariant.withOpacity(0.1) 
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
          'Upload multiple files at once',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
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
                ),
              ),
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file, // Or Icons.cloud_upload_outlined
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop multiple files here (max 2MB each)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'or click to browse',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}