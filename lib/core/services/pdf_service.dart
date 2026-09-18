import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import '../models/app_result.dart';

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
            return [
              pw.Text(
                text,
                style: pw.TextStyle(fontSize: fontSize),
              ),
            ];
          },
        ),
      );

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$fileName.pdf';
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
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$fileName.pdf';
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
      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';

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

  /// Compress a PDF using native pdf_manipulator
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


      // Map quality 0-100 to imageScale 0.1-1.0
      // Lower quality = more compression = smaller scale
      final imageScale = quality / 100.0;
      final imageQuality = quality;

      final compressedPath = await PdfManipulator().pdfCompressor(
        params: PDFCompressorParams(
          pdfPath: inputPath,
          imageQuality: imageQuality,
          imageScale: imageScale,
        ),
      );

      if (compressedPath == null) {
        return const FileOperationResult(error: 'Compression returned null');
      }

      // Copy to our output directory with the desired name
      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';
      await File(compressedPath).copy(outputPath);

      final outputSize = await File(outputPath).length();
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to compress PDF: $e');
    }
  }

  /// Split PDF by page ranges using pdf_manipulator
  Future<List<FileOperationResult>> splitPdf({
    required String inputPath,
    required List<String> pageRanges,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = <FileOperationResult>[];

      final splitPaths = await PdfManipulator().splitPDF(
        params: PDFSplitterParams(
          pdfPath: inputPath,
          pageRanges: pageRanges,
        ),
      );

      if (splitPaths != null) {
        for (final path in splitPaths) {
          final file = File(path);
          final size = await file.length();
          results.add(FileOperationResult(
            outputPath: path,
            fileSizeBytes: size,
            processingTime: stopwatch.elapsed,
          ));
        }
      }

      stopwatch.stop();
      return results;
    } catch (e) {
      stopwatch.stop();
      return [FileOperationResult(error: 'Failed to split PDF: $e')];
    }
  }

  /// Rotate PDF pages using pdf_manipulator
  Future<FileOperationResult> rotatePdfPages({
    required String inputPath,
    required List<PageRotationInfo> rotations,
    required String outputName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final rotatedPath = await PdfManipulator().pdfPageRotator(
        params: PDFPageRotatorParams(
          pdfPath: inputPath,
          pagesRotationInfo: rotations,
        ),
      );

      if (rotatedPath == null) {
        return const FileOperationResult(error: 'Rotation returned null');
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';
      await File(rotatedPath).copy(outputPath);

      final outputSize = await File(outputPath).length();
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to rotate pages: $e');
    }
  }

  /// Add watermark to PDF using pdf_manipulator
  Future<FileOperationResult> watermarkPdf({
    required String inputPath,
    required String watermarkText,
    required String outputName,
    double fontSize = 50,
    double opacity = 0.3,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final watermarkedPath = await PdfManipulator().pdfWatermark(
        params: PDFWatermarkParams(
          pdfPath: inputPath,
          text: watermarkText,
          fontSize: fontSize,
          opacity: opacity,
          watermarkLayer: WatermarkLayer.overContent,
          positionType: PositionType.center,
        ),
      );

      if (watermarkedPath == null) {
        return const FileOperationResult(error: 'Watermarking returned null');
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';
      await File(watermarkedPath).copy(outputPath);

      final outputSize = await File(outputPath).length();
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to watermark PDF: $e');
    }
  }

  /// Encrypt PDF with password using pdf_manipulator
  Future<FileOperationResult> encryptPdf({
    required String inputPath,
    required String password,
    required String outputName,
    bool allowPrinting = true,
    bool allowCopy = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final encryptedPath = await PdfManipulator().pdfEncryption(
        params: PDFEncryptionParams(
          pdfPath: inputPath,
          ownerPassword: password,
          userPassword: password,
          encryptionAES256: true,
          allowPrinting: allowPrinting,
          allowCopy: allowCopy,
        ),
      );

      if (encryptedPath == null) {
        return const FileOperationResult(error: 'Encryption returned null');
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';
      await File(encryptedPath).copy(outputPath);

      final outputSize = await File(outputPath).length();
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to encrypt PDF: $e');
    }
  }

  /// Convert PDF pages to images using pdf_combiner
  Future<List<String>> pdfToImages({
    required String pdfPath,
  }) async {
    try {
      final outputDir = await _getOutputDirectory();
      final imagesDir = '$outputDir/pdf_images_${DateTime.now().millisecondsSinceEpoch}';
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

  /// Delete specific pages from PDF using pdf_manipulator
  Future<FileOperationResult> deletePages({
    required String inputPath,
    required List<int> pageNumbers,
    required String outputName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final resultPath = await PdfManipulator().pdfPageDeleter(
        params: PDFPageDeleterParams(
          pdfPath: inputPath,
          pageNumbers: pageNumbers,
        ),
      );

      if (resultPath == null) {
        return const FileOperationResult(error: 'Page deletion returned null');
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';
      await File(resultPath).copy(outputPath);

      final outputSize = await File(outputPath).length();
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to delete pages: $e');
    }
  }

  /// Reorder PDF pages using pdf_manipulator
  Future<FileOperationResult> reorderPages({
    required String inputPath,
    required List<int> newPageOrder,
    required String outputName,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final resultPath = await PdfManipulator().pdfPageReorder(
        params: PDFPageReorderParams(
          pdfPath: inputPath,
          pageNumbers: newPageOrder,
        ),
      );

      if (resultPath == null) {
        return const FileOperationResult(error: 'Page reorder returned null');
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$outputName.pdf';
      await File(resultPath).copy(outputPath);

      final outputSize = await File(outputPath).length();
      stopwatch.stop();

      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputSize,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to reorder pages: $e');
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
            imageBytes = Uint8List.fromList(img.encodeJpg(adjusted, quality: 90));
          }
        }

        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (context) => pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }

      final outputDir = await _getOutputDirectory();
      final outputPath = '$outputDir/$fileName.pdf';
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
      final tempSignaturePath = '$outputDir/_temp_signature_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final signaturePageBytes = await signaturePdf.save();
      await File(tempSignaturePath).writeAsBytes(signaturePageBytes);

      // Merge original PDF + signature page using pdf_combiner
      final outputPath = '$outputDir/$outputName.pdf';
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

  String generateFileName(String prefix) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$timestamp';
  }
}
