import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart' as pm;
import 'package:pdf_manipulator/io.dart' as pm;
import '../models/app_result.dart';
import '../utils/pdf_utils.dart';

/// PDF creation, merge, split, compress, watermark, encrypt service
class PdfService {
  Future<FileOperationResult> createPdfFromText({
    required String text,
    required String fileName,
    double fontSize = 12.0,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [pw.Text(text, style: pw.TextStyle(fontSize: fontSize))];
          },
        ),
      );

      final outputPath = await _uniqueOutputPath(fileName);
      final outputFile = File(outputPath);
      final pdfBytes = await pdf.save();
      await outputFile.writeAsBytes(pdfBytes);

      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: pdfBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to create PDF from text: $e');
    }
  }

  /// Create PDF from list of image paths
  Future<FileOperationResult> createPdfFromImages({
    required List<String> imagePaths,
    required String fileName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    int quality = 85,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final pdf = pw.Document();

      for (final path in imagePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      final outputPath = await _uniqueOutputPath(fileName);
      final outputFile = File(outputPath);
      final pdfBytes = await pdf.save();
      await outputFile.writeAsBytes(pdfBytes);

      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: pdfBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to create PDF: $e');
    }
  }

  /// Merge multiple PDF files using native pdf_combiner plugin
  Future<FileOperationResult> mergePdfs({
    required List<String> pdfPaths,
    required String outputName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final outputPath = await _uniqueOutputPath(outputName);

      // Build MergeInput list from file paths
      final inputs = pdfPaths.map((p) => MergeInput.path(p)).toList();

      // Real native PDF merge using pdf_combiner
      await PdfCombiner.mergeMultiplePDFs(
        inputs: inputs,
        outputPath: outputPath,
      );

      final outputFile = File(outputPath);
      final fileSize = await outputFile.length();

      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: fileSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to merge PDFs: $e');
    }
  }

  /// Compress a PDF: downsample and re-encode embedded images.
  /// [quality] 0-100 — lower means smaller files.
  Future<FileOperationResult> compressPdf({
    required String inputPath,
    required String outputName,
    int quality = 50,
  }) async {
    if (!await File(inputPath).exists()) {
      return const FileOperationResult(error: 'Input file not found');
    }
    // Map quality to a target image resolution (ppi).
    final ppi = quality <= 30 ? 72.0 : (quality <= 60 ? 150.0 : 220.0);
    final policy = pm.PdfImagePolicy(
      colorPpi: ppi,
      grayPpi: ppi,
      monoPpi: 300,
      jpegQuality: quality.clamp(10, 95),
      convertCmykToRgb: true,
      recompressJpeg: true,
    );
    return _writeWithEngine(
      outputName,
      'compress PDF',
      (pdf, sink) => pdf.compress(_source(inputPath), sink, images: policy),
    );
  }

  /// Split PDF by 1-indexed page ranges like `["1-3", "4", "5-6"]`.
  /// Returns one result per range, in order.
  Future<List<FileOperationResult>> splitPdf({
    required String inputPath,
    required List<String> pageRanges,
  }) async {
    final pageCount = await getPageCount(inputPath);
    if (pageCount == null) {
      return [const FileOperationResult(error: 'Could not open PDF')];
    }
    final baseName = File(inputPath).uri.pathSegments.last.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final results = <FileOperationResult>[];
    for (final range in pageRanges) {
      final pages = parsePageRange(range, pageCount);
      if (pages == null || pages.isEmpty) {
        results.add(
          FileOperationResult(error: 'Range "$range" is outside 1-$pageCount'),
        );
        continue;
      }
      results.add(
        await _writeWithEngine(
          '${baseName}_p$range',
          'split PDF',
          (pdf, sink) =>
              pdf.extractPages(_source(inputPath), sink, pages: pages),
        ),
      );
    }
    return results;
  }

  /// Rebuild a PDF with pages in [pageOrder] (0-based indices into the
  /// original; omitted pages are dropped), rotating each output page by
  /// [rotations] (original index → clockwise degrees, multiples of 90).
  Future<FileOperationResult> organizePages({
    required String inputPath,
    required List<int> pageOrder,
    Map<int, int> rotations = const {},
    required String outputName,
  }) async {
    if (pageOrder.isEmpty) {
      return const FileOperationResult(error: 'At least one page must be kept');
    }
    return _writeWithEngine(outputName, 'organize pages', (pdf, sink) async {
      final editor = await pdf.edit(_source(inputPath));
      try {
        await editor.selectPages(pageOrder);
        for (var i = 0; i < pageOrder.length; i++) {
          final degrees = (rotations[pageOrder[i]] ?? 0) % 360;
          if (degrees != 0) await editor.rotatePage(i, degrees: degrees);
        }
        await editor.save(sink);
      } finally {
        await editor.dispose();
      }
    });
  }

  /// Add a diagonal text watermark to every page.
  Future<FileOperationResult> watermarkPdf({
    required String inputPath,
    required String watermarkText,
    required String outputName,
    double fontSize = 50,
    double opacity = 0.3,
  }) {
    return _writeWithEngine(
      outputName,
      'watermark PDF',
      (pdf, sink) => pdf.watermark(
        _source(inputPath),
        sink,
        text: watermarkText,
        style: pm.PdfWatermarkStyle(fontSize: fontSize, opacity: opacity),
      ),
    );
  }

  /// Encrypt PDF with an AES-256 password.
  Future<FileOperationResult> encryptPdf({
    required String inputPath,
    required String password,
    required String outputName,
    bool allowPrinting = true,
    bool allowCopy = false,
  }) {
    return _writeWithEngine(
      outputName,
      'encrypt PDF',
      (pdf, sink) => pdf.encrypt(
        _source(inputPath),
        sink,
        encryption: pm.PdfEncryptionConfig(
          ownerPassword: password,
          userPassword: password,
          permissions: pm.PdfPermissions(
            print: allowPrinting,
            printHq: allowPrinting,
            copy: allowCopy,
          ),
        ),
      ),
    );
  }

  /// Remove password protection, given the correct password.
  Future<FileOperationResult> decryptPdf({
    required String inputPath,
    required String password,
    required String outputName,
  }) {
    return _writeWithEngine(
      outputName,
      'unlock PDF',
      (pdf, sink) => pdf.decrypt(_source(inputPath), sink, password: password),
    );
  }

  /// Whether the PDF needs a password to open.
  Future<bool> isPasswordProtected(String path) async {
    try {
      final doc = await _engine.open(_source(path));
      await doc.dispose();
      return false;
    } on pm.PdfPasswordRequired {
      return true;
    } on pm.PdfWrongPassword {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Number of pages, or null if the file can't be opened.
  Future<int?> getPageCount(String path) async {
    try {
      final doc = await _engine.open(_source(path));
      try {
        return doc.pageCount;
      } finally {
        await doc.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  /// Streams PNG thumbnails of every page, in page order.
  Stream<Uint8List> renderThumbnails(String path, {int size = 320}) async* {
    final doc = await _engine.open(_source(path));
    try {
      await for (final page in doc.render(
        pages: const pm.PdfPages.all(),
        size: pm.PdfRenderSize.thumbnail(size),
      )) {
        yield page.data;
      }
    } finally {
      await doc.dispose();
    }
  }

  static pm.Pdf? _pdfEngine;
  static pm.Pdf get _engine => _pdfEngine ??= pm.Pdf();

  static pm.FileSource _source(String path) => pm.FileSource(File(path));

  /// Runs a pdf_manipulator operation that writes into a new output file.
  Future<FileOperationResult> _writeWithEngine(
    String outputName,
    String action,
    Future<void> Function(pm.Pdf pdf, pm.DataSink sink) op,
  ) async {
    final stopwatch = Stopwatch()..start();
    final outputPath = await _uniqueOutputPath(outputName);
    final outFile = File(outputPath);
    try {
      final sink = await pm.FileSink.create(outFile);
      try {
        await op(_engine, sink);
      } finally {
        await sink.close();
      }
      final size = await outFile.length();
      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: size,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      if (await outFile.exists()) await outFile.delete();
      final reason = switch (e) {
        pm.PdfWrongPassword() => 'Incorrect password',
        pm.PdfPasswordRequired() => 'This PDF is password-protected',
        pm.PdfError(:final message) => message,
        _ => '$e',
      };
      return FileOperationResult(error: 'Failed to $action: $reason');
    }
  }

  /// Convert PDF pages to images using pdf_combiner
  Future<List<String>> pdfToImages({required String pdfPath}) async {
    try {
      final outputDir = await _getOutputDirectory();
      final imagesDir =
          '$outputDir/pdf_images_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(imagesDir).create(recursive: true);

      final input = MergeInput.path(pdfPath);
      final imagePaths = await PdfCombiner.createImageFromPDF(
        input: input,
        outputDirPath: imagesDir,
      );

      return imagePaths;
    } catch (e) {
      return [];
    }
  }

  /// Create PDF from scanned document images with optional enhancement
  Future<FileOperationResult> createScannedPdf({
    required List<String> scannedImagePaths,
    required String fileName,
    bool enhanceContrast = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final pdf = pw.Document();

      for (final path in scannedImagePaths) {
        final file = File(path);
        if (!await file.exists()) continue;

        Uint8List imageBytes = await file.readAsBytes();

        if (enhanceContrast) {
          // Basic contrast enhancement
          final decoded = img.decodeImage(imageBytes);
          if (decoded != null) {
            final adjusted = img.adjustColor(decoded, contrast: 1.2);
            imageBytes = Uint8List.fromList(
              img.encodeJpg(adjusted, quality: 90),
            );
          }
        }

        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (context) =>
                pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        );
      }

      final outputPath = await _uniqueOutputPath(fileName);
      final pdfBytes = await pdf.save();
      await File(outputPath).writeAsBytes(pdfBytes);

      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: pdfBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to create scanned PDF: $e');
    }
  }

  /// Add a signature image to an existing PDF.
  /// Creates a new document by merging original + signature page.
  Future<FileOperationResult> addSignatureToPdf({
    required String pdfPath,
    required Uint8List signatureBytes,
    required String outputName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      // Create a separate signature page PDF
      final signaturePdf = pw.Document();
      final signatureImage = pw.MemoryImage(signatureBytes);

      signaturePdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Spacer(),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  padding: const pw.EdgeInsets.only(right: 40, bottom: 60),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 180,
                        height: 80,
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Signature',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save signature page to temp file
      final outputDir = await _getOutputDirectory();
      final tempSignaturePath =
          '$outputDir/_temp_signature_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final signaturePageBytes = await signaturePdf.save();
      await File(tempSignaturePath).writeAsBytes(signaturePageBytes);

      // Merge original PDF + signature page using pdf_combiner
      final outputPath = await _uniqueOutputPath(outputName);
      final inputs = [
        MergeInput.path(pdfPath),
        MergeInput.path(tempSignaturePath),
      ];

      await PdfCombiner.mergeMultiplePDFs(
        inputs: inputs,
        outputPath: outputPath,
      );

      // Clean up temp file
      try {
        await File(tempSignaturePath).delete();
      } catch (_) {}

      final outputFile = File(outputPath);
      final fileSize = await outputFile.length();

      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: fileSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to sign PDF: $e');
    }
  }

  Future<String> _getOutputDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/evergreen_pdfs');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir.path;
  }

  /// `<docs>/evergreen_pdfs/<name>.pdf`, suffixed " (n)" if taken.
  Future<String> _uniqueOutputPath(String name) async {
    final dir = await _getOutputDirectory();
    final safe = sanitizeFileName(name);
    var path = '$dir/$safe.pdf';
    for (var n = 1; await File(path).exists(); n++) {
      path = '$dir/$safe ($n).pdf';
    }
    return path;
  }

  String generateFileName(String prefix) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$timestamp';
  }
}
