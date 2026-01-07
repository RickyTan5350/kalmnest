import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter/services.dart';
import 'dart:typed_data';

class PdfService {
  Future<void> generateAndDownloadPdf({
    required String title,
    required String content,
    Map<String, int> quizStates = const {},
    String topic = '',
  }) async {
    try {
      final pdf = pw.Document();

      // 1. Load Fonts
      late pw.Font font;
      late pw.Font fontBold;
      try {
        font = await PdfGoogleFonts.openSansRegular();
        fontBold = await PdfGoogleFonts.openSansBold();
      } catch (e) {
        print("Error loading Google Fonts: $e. Using fallback fonts.");
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      // 2. Pre-process Quiz Blocks
      String processedContent = _processQuizBlocks(content, quizStates);

      // 3. Pre-process Large Code Blocks
      processedContent = _splitLargeCodeBlocks(processedContent);

      // 4. Convert Markdown -> HTML
      String htmlContent = md.markdownToHtml(
        processedContent,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );

      // 5. Pre-process HTML (Resolve Images & Add Table Styles)
      htmlContent = await _preprocessHtml(htmlContent, topic);

      // 6. Rename Tags to remove red highlights (Legacy cleanup)
      htmlContent = htmlContent.replaceAllMapped(
        RegExp(r'<pre[^>]*>'),
        (match) =>
            '<div style="background-color: #f5f5f5; padding: 10px; border: 1px solid #cccccc; margin-bottom: 10px;">',
      );
      htmlContent = htmlContent.replaceAll('</pre>', '</div>');

      htmlContent = htmlContent.replaceAllMapped(
        RegExp(r'<code[^>]*>'),
        (match) =>
            '<span style="background-color: #f5f5f5; font-family: courier; color: #000000;">',
      );
      htmlContent = htmlContent.replaceAll('</code>', '</span>');

      htmlContent = htmlContent.replaceAllMapped(
        RegExp(r'<a [^>]*>'),
        (match) => '<a style="color: #000000; text-decoration: underline;">',
      );

      // 7. Convert HTML -> PDF Widgets
      final List<pw.Widget> widgets = await HTMLToPdf().convert(htmlContent);

      // 8. Create the PDF Page
      pdf.addPage(
        pw.MultiPage(
          maxPages: 500,
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: fontBold,
                  ),
                ),
              ),
              ...widgets,
            ];
          },
        ),
      );

      // 9. Generate Safe Filename
      String safeFilename = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (!safeFilename.toLowerCase().endsWith('.pdf')) {
        safeFilename += '.pdf';
      }

      // 10. Save and Share
      await Printing.sharePdf(bytes: await pdf.save(), filename: safeFilename);
    } catch (e) {
      // FALLBACK: Generate simple text PDF
      try {
        final fallbackPdf = pw.Document();
        final font = await PdfGoogleFonts.openSansRegular();

        fallbackPdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
              pw.Paragraph(
                text: "PDF Generation Error (Fallback Mode)",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 18,
                  color: PdfColors.red,
                ),
              ),
              pw.Paragraph(
                text:
                    "The complex formatting could not be rendered. Probaly due to TooManyPagesException from large code blocks.",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey,
                ),
              ),
              pw.Paragraph(
                text: "Error Details: $e",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey,
                ),
              ),
              pw.Divider(),
              pw.Paragraph(
                text: content, // Raw markdown
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
        );

        String safeFilename =
            "Fallback_${title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.pdf";
        await Printing.sharePdf(
          bytes: await fallbackPdf.save(),
          filename: safeFilename,
        );
      } catch (fallbackError) {
        print("Critical error generating fallback PDF: $fallbackError");
      }
    }
  }

  Future<String> _preprocessHtml(String htmlContent, String topic) async {
    // 1. Resolve Images to Base64
    final imgRegExp = RegExp(r'<img[^>]+src="([^">]+)"');
    final matches = imgRegExp.allMatches(htmlContent);

    String processed = htmlContent;
    Set<String> srcs = matches.map((m) => m.group(1)!).toSet();

    for (final src in srcs) {
      if (src.startsWith('data:')) continue;
      if (src.startsWith('http')) continue;

      String? base64Str = await _resolveLocalImageToBase64(src, topic);
      if (base64Str != null) {
        // Use replaceAll to replace all instances of this specific src
        processed = processed.replaceAll(
          'src="$src"',
          'src="data:image/png;base64,$base64Str"',
        );
      }
    }

    // 2. Inject CSS for Tables via Inline Styles
    // Global style blocks can be unreliable in some PDF converters,
    // so we inject explicit inline styles for better compatibility.

    // A. Use a unique marker temporarily for the first cell of each row
    processed = processed.replaceAllMapped(
      RegExp(r'<tr>(\s*)<(th|td)'),
      (match) => '<tr>${match.group(1)}<${match.group(2)} data-first="true"',
    );

    const baseStyle =
        'border: 1px solid #333333; padding: 10px; text-align: left; vertical-align: top;';

    processed = processed.replaceAll(
      '<table',
      '<table style="width: 100%; border-collapse: collapse; margin-bottom: 20px; border: 1px solid #333333;"',
    );

    // B. Style the first cells (often row headers) with more width
    processed = processed.replaceAll(
      '<th data-first="true"',
      '<th style="$baseStyle background-color: #eeeeee; font-weight: bold; width: 25%; min-width: 100px;"',
    );
    processed = processed.replaceAll(
      '<td data-first="true"',
      '<td style="$baseStyle background-color: #f9f9f9; font-weight: bold; width: 25%; min-width: 100px;"',
    );

    // C. Style all other cells
    processed = processed.replaceAll(
      '<th',
      '<th style="$baseStyle background-color: #eeeeee; font-weight: bold;"',
    );
    processed = processed.replaceAll('<td', '<td style="$baseStyle"');

    return processed;
  }

  Future<String?> _resolveLocalImageToBase64(String src, String topic) async {
    final fileName = src.split('/').last;

    List<String> candidates = [];

    // If it looks like a full asset path already
    if (src.startsWith('assets/')) {
      candidates.add(src);
    } else {
      // 1. Flattened
      candidates.add('assets/www/pictures/$fileName');
      // 2. Topic specific
      if (topic.isNotEmpty) {
        candidates.add('assets/www/pictures/$topic/$fileName');
      }
      // 3. Known folders
      final folders = ['HTML', 'CSS', 'JS', 'PHP', 'General'];
      for (var f in folders) {
        candidates.add('assets/www/pictures/$f/$fileName');
      }
    }

    for (final path in candidates) {
      try {
        final ByteData data = await rootBundle.load(path);
        final Uint8List bytes = data.buffer.asUint8List();
        return base64Encode(bytes);
      } catch (e) {
        // continue
      }
    }
    return null;
  }

  String _processQuizBlocks(String content, Map<String, int> quizStates) {
    // Regex to match ```quiz ... ```
    final RegExp quizRegex = RegExp(r'```quiz\s*([\s\S]*?)\s*```');

    return content.replaceAllMapped(quizRegex, (match) {
      String jsonString = match.group(1) ?? "{}";
      try {
        final Map<String, dynamic> quizData = jsonDecode(jsonString);
        String question = quizData['question'] ?? "No Question";
        List<dynamic> options = quizData['options'] ?? [];
        int correctIndex = quizData['correctIndex'] ?? -1;

        // CHECK STUDENT SELECTION
        bool isAnswered = quizStates.containsKey(question);
        int? selectedIndex = quizStates[question];

        // Build HTML for the Quiz
        // We use a table for structural layout to simulate the card/box look
        StringBuffer htmlBuffer = StringBuffer();

        htmlBuffer.writeln(
          '<div style="margin-bottom: 20px; padding: 15px; border: 1px solid #cccccc; background-color: #fafafa; border-radius: 8px;">',
        );

        // Question
        htmlBuffer.writeln(
          '<p style="font-weight: bold; font-size: 14pt; margin-bottom: 15px;">$question</p>',
        );

        // Options
        for (int i = 0; i < options.length; i++) {
          String optionText = options[i];

          // DETERMINE STYLES BASED ON SELECTION
          String borderColor = "#e0e0e0";
          String bgColor = "#ffffff";
          String textColor = "#000000";
          String icon = "( )";

          if (isAnswered) {
            if (i == correctIndex) {
              // Correct Answer -> GREEN
              borderColor = "#4caf50";
              bgColor = "#e8f5e9";
              textColor = "#2e7d32";
              icon = "( / )"; // Checked
            } else if (i == selectedIndex && i != correctIndex) {
              // Selected Wrong Answer -> RED
              borderColor = "#f44336";
              bgColor = "#ffebee";
              textColor = "#c62828";
              icon = "( X )"; // Cross
            } else {
              // Unselected, Uncorrect -> Greyed out
              textColor = "#9e9e9e"; // Grey text
              // icon stays empty
            }
          }

          htmlBuffer.writeln(
            '<div style="margin-bottom: 8px; padding: 10px; border: 1px solid $borderColor; background-color: $bgColor; border-radius: 5px;">',
          );
          htmlBuffer.writeln(
            '<span style="color: $textColor;">$icon $optionText</span>',
          );
          htmlBuffer.writeln('</div>');
        }

        // Answer Key Footer (Optional, mimicking app)
        if (isAnswered) {
          htmlBuffer.writeln(
            '<div style="margin-top: 10px; font-size: 10pt;">',
          );
          if (selectedIndex == correctIndex) {
            htmlBuffer.writeln(
              '<span style="color: #4caf50; font-weight: bold;">Betul! Tahniah.</span>',
            );
          } else {
            String correctText =
                (correctIndex >= 0 && correctIndex < options.length)
                ? options[correctIndex]
                : "Unknown";
            htmlBuffer.writeln(
              '<span style="color: #f44336; font-weight: bold;">Salah. Jawapan betul ialah: $correctText</span>',
            );
          }
          htmlBuffer.writeln('</div>');
        }

        htmlBuffer.writeln('</div>'); // Close main container

        return htmlBuffer.toString();
      } catch (e) {
        // Fallback if JSON parsing fails
        return '<div style="color: red;">Error parsing quiz: $e</div>';
      }
    });
  }

  String _splitLargeCodeBlocks(String content) {
    // Regex to match code blocks: ```language ... ```
    // We capture language to preserve it in splits
    final RegExp codeBlockRegex = RegExp(r'```(\w*)\s*([\s\S]*?)```');

    return content.replaceAllMapped(codeBlockRegex, (match) {
      String language = match.group(1) ?? '';
      String code = match.group(2) ?? '';

      // If the code block is actually a pre-processed HTML div (from quizzes or other logic), skip it.
      // Although _processQuizBlocks replaces ```quiz``` with <div>, so this regex shouldn't match quizzes.
      if (language.trim() == 'quiz') return match.group(0)!;

      List<String> lines = const LineSplitter().convert(code);
      const int maxLines =
          45; // Tuned for A4 page with default margins & font size

      if (lines.length <= maxLines) {
        return match.group(0)!; // No change needed
      }

      StringBuffer buffer = StringBuffer();
      for (int i = 0; i < lines.length; i += maxLines) {
        int end = (i + maxLines < lines.length) ? i + maxLines : lines.length;
        List<String> chunk = lines.sublist(i, end);

        // Re-wrap in code block
        buffer.writeln('```$language');
        buffer.writeln(chunk.join('\n'));
        buffer.writeln('```');

        // Add a small spacer text/div to force a potential break point if needed
        // Markdown treats double newlines as paragraph break.
        if (i + maxLines < lines.length) {
          buffer.writeln('\n');
        }
      }
      return buffer.toString();
    });
  }
}
