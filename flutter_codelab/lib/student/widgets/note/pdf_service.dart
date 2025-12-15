import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:markdown/markdown.dart' as md;

class PdfService {
  Future<void> generateAndDownloadPdf({
    required String title,
    required String content,
  }) async {
    final pdf = pw.Document();

    // 1. Load Fonts
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // 2. Convert Markdown -> HTML
    String htmlContent = md.markdownToHtml(
      content,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    // 3. Rename Tags to remove red highlights (Your previous fix)
    htmlContent = htmlContent.replaceAllMapped(
      RegExp(r'<pre[^>]*>'), 
      (match) => '<div style="background-color: #f5f5f5; padding: 10px; border: 1px solid #cccccc; margin-bottom: 10px;">'
    );
    htmlContent = htmlContent.replaceAll('</pre>', '</div>');
    
    htmlContent = htmlContent.replaceAllMapped(
      RegExp(r'<code[^>]*>'), 
      (match) => '<span style="background-color: #f5f5f5; font-family: courier; color: #000000;">'
    );
    htmlContent = htmlContent.replaceAll('</code>', '</span>');

    htmlContent = htmlContent.replaceAllMapped(
      RegExp(r'<a [^>]*>'), 
      (match) => '<a style="color: #000000; text-decoration: underline;">'
    );

    // 4. Wrap in a Div for Global Font Size
    String styledHtml = """
    <div style="font-size: 11pt; color: #000000;">
      $htmlContent
    </div>
    """;

    // 5. Convert HTML -> PDF Widgets
    final List<pw.Widget> widgets = await HTMLToPdf().convert(
      styledHtml,
    );

    // 6. Create the PDF Page
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
             // Custom Title Header
             pw.Header(
              level: 0,
              // FIX: Reduce bottom margin (Default is often too large)
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
            
            // FIX: Removed pw.SizedBox(height: 20) entirely!

            // Add all the converted widgets
            ...widgets,
          ];
        },
      ),
    );

    // 7. Generate a Safe Filename
    String safeFilename = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    if (!safeFilename.toLowerCase().endsWith('.pdf')) {
      safeFilename += '.pdf';
    }

    // 8. Save and Share
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: safeFilename,
    );
  }
}