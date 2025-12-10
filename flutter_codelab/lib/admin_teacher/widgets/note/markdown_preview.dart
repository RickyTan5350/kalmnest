import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// Import path package


// Markdown Preview Widget (Completely Unchanged)
class MarkdownPreview extends StatelessWidget {
  final String markdownText;
  final ColorScheme colorScheme;

  const MarkdownPreview({
    super.key,
    required this.markdownText,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
      ),
      child: markdownText.isEmpty
          ? Text(
              'Type markdown above to see the live preview here.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            )
          : MarkdownBody(
              data: markdownText,
              // Handles interactive elements like links
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href)); // Opens link in external browser
                }
              },
              styleSheet: MarkdownStyleSheet(
                // Example of custom styling for code blocks
                code: TextStyle(
                  backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  color: colorScheme.primary,
                ),
                p: TextStyle(color: colorScheme.onSurface),
                h1: TextStyle(color: colorScheme.primary),
                // Add more styles as needed
              ),
            ),
    );
  }
}
