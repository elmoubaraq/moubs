import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show Offset, Rect;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;
import '../models/app_result.dart';
import '../utils/pdf_utils.dart';

/// PDF creation, merge, split, compress, watermark, encrypt, unlock service
class PdfService {
  Future<FileOperationResult> createPdfFromText({
    required String text,
    required String fileName,
    double fontSize = 12.0,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final safeText = _sanitizeForPdf(text);
      final document = spdf.PdfDocument();
      document.pageSettings.margins.all = 36;
      final font = spdf.PdfStandardFont(
        spdf.PdfFontFamily.helvetica,
        fontSize.clamp(8.0, 36.0),
      );

      final textElement = spdf.PdfTextElement(
        text: safeText,
        font: font,
        brush: spdf.PdfSolidBrush(spdf.PdfColor(17, 24, 39)),
        format: spdf.PdfStringFormat(
          alignment: spdf.PdfTextAlignment.left,
          lineAlignment: spdf.PdfVerticalAlignment.top,
          wordWrap: spdf.PdfWordWrapType.word,
        ),
      );

      final layoutFormat = spdf.PdfLayoutFormat(
        layoutType: spdf.PdfLayoutType.paginate,
        breakType: spdf.PdfLayoutBreakType.fitPage,
      );

      final page = document.pages.add();
      final clientSize = page.getClientSize();
      textElement.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 0, clientSize.width, clientSize.height),
        format: layoutFormat,
      );

      final outputPath = await _uniqueOutputPath(fileName);
      final savedBytes = document.saveSync();
      document.dispose();

      await File(outputPath).writeAsBytes(savedBytes);
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: savedBytes.length,
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

      // Native PDF merge using pdf_combiner
      try {
        await PdfCombiner.mergeMultiplePDFs(
          inputs: inputs,
          outputPath: outputPath,
        );
      } catch (_) {
        // Fallback merge using syncfusion_flutter_pdf
        final mergedDoc = spdf.PdfDocument();
        for (final p in pdfPaths) {
          final file = File(p);
          if (await file.exists()) {
            final doc = spdf.PdfDocument(inputBytes: await file.readAsBytes());
            for (int i = 0; i < doc.pages.count; i++) {
              final template = doc.pages[i].createTemplate();
              final newPage = mergedDoc.pages.add();
              newPage.graphics.drawPdfTemplate(template, Offset.zero);
            }
            doc.dispose();
          }
        }
        final bytes = mergedDoc.saveSync();
        mergedDoc.dispose();
        await File(outputPath).writeAsBytes(bytes);
      }

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

  /// Compress a PDF
  Future<FileOperationResult> compressPdf({
    required String inputPath,
    required String outputName,
    int quality = 50,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'Input file not found');
      }

      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      // 1. Try standard Syncfusion compression
      final document = spdf.PdfDocument(inputBytes: originalBytes);
      document.compressionLevel = spdf.PdfCompressionLevel.best;
      final syncfusionCompressed = document.saveSync();
      document.dispose();

      Uint8List bestBytes = Uint8List.fromList(syncfusionCompressed);

      // 2. If the document is image-heavy or syncfusion compression didn't reduce size enough
      // and quality is requested, downsample pages via raster + high-efficiency JPEG
      final bool needsDeeperCompression =
          originalSize > 500 * 1024 && syncfusionCompressed.length >= (originalSize * 0.95);

      if (needsDeeperCompression) {
        try {
          final double dpi = quality <= 25 ? 96.0 : (quality <= 50 ? 120.0 : 150.0);
          final jpgQuality = quality.clamp(20, 80);
          final newDoc = pw.Document();

          await for (final page in Printing.raster(originalBytes, dpi: dpi)) {
            final pngBytes = await page.toPng();
            final decoded = img.decodeImage(pngBytes);
            if (decoded != null) {
              final jpgBytes = img.encodeJpg(decoded, quality: jpgQuality);
              final pdfImage = pw.MemoryImage(Uint8List.fromList(jpgBytes));
              newDoc.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat(
                    page.width.toDouble(),
                    page.height.toDouble(),
                  ),
                  margin: pw.EdgeInsets.zero,
                  build: (_) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Image(pdfImage, fit: pw.BoxFit.fill),
                  ),
                ),
              );
            }
          }

          final rasterCompressed = await newDoc.save();
          if (rasterCompressed.length < bestBytes.length) {
            bestBytes = Uint8List.fromList(rasterCompressed);
          }
        } catch (_) {
          // Keep bestBytes from syncfusion
        }
      }

      final outputPath = await _uniqueOutputPath(outputName);
      await File(outputPath).writeAsBytes(bestBytes);
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: bestBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to compress PDF: $e');
    }
  }

  /// Split PDF by 1-indexed page ranges like `["1-3", "4", "5-6"]`.
  Future<List<FileOperationResult>> splitPdf({
    required String inputPath,
    required List<String> pageRanges,
  }) async {
    final pageCount = await getPageCount(inputPath);
    if (pageCount == null || pageCount <= 0) {
      return [const FileOperationResult(error: 'Could not open PDF or PDF has no pages')];
    }
    final baseName = File(inputPath).uri.pathSegments.last.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final results = <FileOperationResult>[];

    try {
      final bytes = await File(inputPath).readAsBytes();
      final sourceDoc = spdf.PdfDocument(inputBytes: bytes);

      for (final range in pageRanges) {
        final pages = parsePageRange(range, pageCount);
        if (pages == null || pages.isEmpty) {
          results.add(
            FileOperationResult(error: 'Range "$range" is outside 1-$pageCount'),
          );
          continue;
        }

        final stopwatch = Stopwatch()..start();
        final splitDoc = spdf.PdfDocument();
        for (final idx in pages) {
          if (idx >= 0 && idx < sourceDoc.pages.count) {
            final template = sourceDoc.pages[idx].createTemplate();
            final newPage = splitDoc.pages.add();
            newPage.graphics.drawPdfTemplate(template, Offset.zero);
          }
        }

        final outputName = '${baseName}_p$range';
        final outputPath = await _uniqueOutputPath(outputName);
        final savedBytes = splitDoc.saveSync();
        splitDoc.dispose();

        await File(outputPath).writeAsBytes(savedBytes);
        stopwatch.stop();
        results.add(
          FileOperationResult(
            outputPath: outputPath,
            fileSizeBytes: savedBytes.length,
            processingTime: stopwatch.elapsed,
          ),
        );
      }
      sourceDoc.dispose();
    } catch (e) {
      results.add(FileOperationResult(error: 'Failed to split PDF: $e'));
    }

    return results;
  }

  /// Rebuild a PDF with pages in [pageOrder] (0-based indices) and rotations.
  Future<FileOperationResult> organizePages({
    required String inputPath,
    required List<int> pageOrder,
    Map<int, int> rotations = const {},
    required String outputName,
  }) async {
    if (pageOrder.isEmpty) {
      return const FileOperationResult(error: 'At least one page must be kept');
    }
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'File not found');
      }

      final bytes = await file.readAsBytes();
      final sourceDoc = spdf.PdfDocument(inputBytes: bytes);
      final destDoc = spdf.PdfDocument();

      for (final idx in pageOrder) {
        if (idx >= 0 && idx < sourceDoc.pages.count) {
          final srcPage = sourceDoc.pages[idx];
          final template = srcPage.createTemplate();
          final newPage = destDoc.pages.add();

          final rot = (rotations[idx] ?? 0) % 360;
          if (rot == 90) {
            newPage.rotation = spdf.PdfPageRotateAngle.rotateAngle90;
          } else if (rot == 180) {
            newPage.rotation = spdf.PdfPageRotateAngle.rotateAngle180;
          } else if (rot == 270) {
            newPage.rotation = spdf.PdfPageRotateAngle.rotateAngle270;
          }

          newPage.graphics.drawPdfTemplate(template, Offset.zero);
        }
      }

      final outputPath = await _uniqueOutputPath(outputName);
      final savedBytes = destDoc.saveSync();
      destDoc.dispose();
      sourceDoc.dispose();

      await File(outputPath).writeAsBytes(savedBytes);
      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: savedBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to organize pages: $e');
    }
  }

  /// Add a diagonal text watermark to every page.
  Future<FileOperationResult> watermarkPdf({
    required String inputPath,
    required String watermarkText,
    required String outputName,
    double fontSize = 50,
    double opacity = 0.3,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'File not found');
      }

      final safeText = _sanitizeForPdf(watermarkText);
      final bytes = await file.readAsBytes();
      final document = spdf.PdfDocument(inputBytes: bytes);

      final font = spdf.PdfStandardFont(
        spdf.PdfFontFamily.helvetica,
        fontSize.clamp(12.0, 100.0),
        style: spdf.PdfFontStyle.bold,
      );
      final alpha = (opacity.clamp(0.05, 1.0) * 255).round();
      final brush = spdf.PdfSolidBrush(spdf.PdfColor(14, 165, 233, alpha));

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final pageSize = page.size;
        final g = page.graphics;

        final state = g.save();
        g.translateTransform(pageSize.width / 2, pageSize.height / 2);
        g.rotateTransform(-40);
        final size = font.measureString(safeText);
        g.drawString(
          safeText,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(
            -size.width / 2,
            -size.height / 2,
            size.width,
            size.height,
          ),
        );
        g.restore(state);
      }

      final outputPath = await _uniqueOutputPath(outputName);
      final savedBytes = document.saveSync();
      document.dispose();

      await File(outputPath).writeAsBytes(savedBytes);
      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: savedBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to watermark PDF: $e');
    }
  }

  /// Encrypt PDF with password and permissions.
  Future<FileOperationResult> encryptPdf({
    required String inputPath,
    required String password,
    required String outputName,
    bool allowPrinting = true,
    bool allowCopy = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'File not found');
      }

      final bytes = await file.readAsBytes();
      final document = spdf.PdfDocument(inputBytes: bytes);

      final security = document.security;
      security.userPassword = password;
      security.ownerPassword = '${password}_adm9';
      security.algorithm = spdf.PdfEncryptionAlgorithm.aesx256Bit;
      security.permissions.clear();
      if (allowPrinting) {
        security.permissions.add(spdf.PdfPermissionsFlags.print);
      }
      if (allowCopy) {
        security.permissions.add(spdf.PdfPermissionsFlags.copyContent);
      }

      final outputPath = await _uniqueOutputPath(outputName);
      final savedBytes = document.saveSync();
      document.dispose();

      await File(outputPath).writeAsBytes(savedBytes);
      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: savedBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to encrypt PDF: $e');
    }
  }

  /// Remove password protection from PDF.
  Future<FileOperationResult> decryptPdf({
    required String inputPath,
    required String password,
    required String outputName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'File not found');
      }

      final bytes = await file.readAsBytes();
      final document = spdf.PdfDocument(inputBytes: bytes, password: password);

      final cleanDoc = spdf.PdfDocument();
      for (int i = 0; i < document.pages.count; i++) {
        final template = document.pages[i].createTemplate();
        final newPage = cleanDoc.pages.add();
        newPage.graphics.drawPdfTemplate(template, Offset.zero);
      }

      final outputPath = await _uniqueOutputPath(outputName);
      final savedBytes = cleanDoc.saveSync();
      cleanDoc.dispose();
      document.dispose();

      await File(outputPath).writeAsBytes(savedBytes);
      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: savedBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('password') || errStr.contains('encrypted')) {
        return const FileOperationResult(error: 'Incorrect password');
      }
      return FileOperationResult(error: 'Failed to unlock PDF: $e');
    }
  }

  /// Whether the PDF needs a password to open.
  Future<bool> isPasswordProtected(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      final doc = spdf.PdfDocument(inputBytes: bytes);
      doc.dispose();
      return false;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('password') || errStr.contains('encrypted')) {
        return true;
      }
      return false;
    }
  }

  /// Number of pages, or null if the file can't be opened.
  Future<int?> getPageCount(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final doc = spdf.PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    } catch (_) {
      return null;
    }
  }

  /// Streams PNG thumbnails of every page in page order using Printing.raster.
  Stream<Uint8List> renderThumbnails(String path, {int size = 240}) async* {
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      await for (final raster in Printing.raster(bytes, dpi: 72)) {
        yield await raster.toPng();
      }
    } catch (_) {
      // Return empty stream if raster fails
    }
  }

  /// Convert PDF pages to high-resolution images.
  Future<List<String>> pdfToImages({required String pdfPath}) async {
    final file = File(pdfPath);
    if (!await file.exists()) return [];

    final outputDir = await _getOutputDirectory();
    final imagesDir =
        '$outputDir/pdf_images_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(imagesDir).create(recursive: true);
    final imagePaths = <String>[];

    // Priority 1: High-fidelity native raster via Printing.raster
    try {
      final bytes = await file.readAsBytes();
      int pageIndex = 1;
      await for (final page in Printing.raster(bytes, dpi: 150)) {
        final pngBytes = await page.toPng();
        final imagePath = '$imagesDir/page_$pageIndex.png';
        await File(imagePath).writeAsBytes(pngBytes);
        imagePaths.add(imagePath);
        pageIndex++;
      }
      if (imagePaths.isNotEmpty) {
        return imagePaths;
      }
    } catch (_) {}

    // Fallback: PdfCombiner native plugin
    try {
      final input = MergeInput.path(pdfPath);
      final combinerImages = await PdfCombiner.createImageFromPDF(
        input: input,
        outputDirPath: imagesDir,
      );
      if (combinerImages.isNotEmpty) {
        return combinerImages;
      }
    } catch (_) {}

    return imagePaths;
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

  /// Add a signature image to an existing PDF page at custom coordinates without appending extra pages.
  /// [pageIndex] is 0-based.
  /// [normalizedX], [normalizedY], [normalizedWidth], [normalizedHeight] are proportions (0.0 to 1.0) of page size.
  Future<FileOperationResult> addSignatureToPdf({
    required String pdfPath,
    required Uint8List signatureBytes,
    required String outputName,
    int pageIndex = 0,
    double normalizedX = 0.55,
    double normalizedY = 0.78,
    double normalizedWidth = 0.35,
    double normalizedHeight = 0.12,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'PDF file not found');
      }

      final bytes = await file.readAsBytes();
      final document = spdf.PdfDocument(inputBytes: bytes);

      if (document.pages.count == 0) {
        document.dispose();
        return const FileOperationResult(error: 'PDF has no pages');
      }

      final targetIndex = pageIndex.clamp(0, document.pages.count - 1);
      final page = document.pages[targetIndex];
      final pageSize = page.size;

      final sigBitmap = spdf.PdfBitmap(signatureBytes);

      final double width =
          (normalizedWidth * pageSize.width).clamp(20.0, pageSize.width);
      final double height =
          (normalizedHeight * pageSize.height).clamp(10.0, pageSize.height);
      final double x =
          (normalizedX * pageSize.width).clamp(0.0, pageSize.width - width);
      final double y =
          (normalizedY * pageSize.height).clamp(0.0, pageSize.height - height);

      page.graphics.drawImage(
        sigBitmap,
        Rect.fromLTWH(x, y, width, height),
      );

      final outputPath = await _uniqueOutputPath(outputName);
      final savedBytes = document.saveSync();
      document.dispose();

      await File(outputPath).writeAsBytes(savedBytes);
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: savedBytes.length,
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

  /// Converts Unicode typography (curly quotes, dashes, bullets, ellipses)
  /// into safe standard WinAnsi / Latin equivalents so standard fonts never throw.
  static String _sanitizeForPdf(String text) {
    return text
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201C', '"')
        .replaceAll('\u201D', '"')
        .replaceAll('\u2014', '--')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2022', '*')
        .replaceAll('\u2026', '...')
        .replaceAll('\u00A0', ' ');
  }
}
