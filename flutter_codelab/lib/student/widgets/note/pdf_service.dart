import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:printing/printing.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:markdown/markdown.dart' as md;

class PdfService {
  Future<void> generateAndDownloadPdf({
    required String title,
    required String content,
    Map<String, int> quizStates = const {},
  }) async {
    try {
      final pdf = pw.Document();

      // 1. Load Fonts
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

      // 3. Pre-process Large Code Blocks (to avoid TooManyPagesException)
      processedContent = _splitLargeCodeBlocks(processedContent);

      // 3. Convert Markdown -> HTML
      String htmlContent = md.markdownToHtml(
        processedContent,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );

      // 4. Rename Tags to remove red highlights
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

      // 5. Convert HTML -> PDF Widgets
      // FIX: Removed the outer <div> wrapper to allow better pagination splitting.
      // We still try-catch this specific part just in case, but the outer catch handles everything too.
      final List<pw.Widget> widgets = await HTMLToPdf().convert(htmlContent);

      // 7. Create the PDF Page
      pdf.addPage(
        pw.MultiPage(
          maxPages: 500, // Increase limit
          theme: pw.ThemeData.withFont(
            base: font,
            bold: fontBold,
          ), // Font size defaults to 12, which is fine
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

      // 8. Generate Safe Filename
      String safeFilename = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (!safeFilename.toLowerCase().endsWith('.pdf')) {
        safeFilename += '.pdf';
      }

      // 9. Save and Share
      await Printing.sharePdf(bytes: await pdf.save(), filename: safeFilename);
    } catch (e) {
      // FALLBACK: Generate simple text PDF
      try {
        final fallbackPdf = pw.Document();
        final font =
            await PdfGoogleFonts.openSansRegular(); // Re-load just in case

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
        // If even fallback fails, we can't do much.
        print("Critical error generating fallback PDF: $fallbackError");
      }
    }
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
