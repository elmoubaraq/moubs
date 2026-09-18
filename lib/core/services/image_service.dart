import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/app_result.dart';

/// Image processing service for cropping, enhancing, and ID photos
class ImageService {
  /// Crop image to passport/ID photo dimensions
  Future<FileOperationResult> cropIdPhoto({
    required String imagePath,
    required IdPhotoType photoType,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return const FileOperationResult(error: 'Image not found');
      }

      final bytes = await file.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) {
        return const FileOperationResult(error: 'Could not decode image');
      }

      // Get target aspect ratio based on photo type
      final ratio = photoType.aspectRatio;
      final targetWidth = (original.height * ratio).round();
      final targetHeight = original.height;

      // Center crop
      final x = ((original.width - targetWidth) / 2).round().clamp(0, original.width);
      final y = 0;
      final cropWidth = targetWidth.clamp(1, original.width - x);

      final cropped = img.copyCrop(
        original,
        x: x,
        y: y,
        width: cropWidth,
        height: targetHeight,
      );

      // Resize to standard dimensions
      final resized = img.copyResize(
        cropped,
        width: photoType.widthPx,
        height: photoType.heightPx,
        interpolation: img.Interpolation.cubic,
      );

      final outputDir = await _getOutputDirectory();
      final outputPath =
          '$outputDir/id_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputBytes = img.encodeJpg(resized, quality: 95);
      await File(outputPath).writeAsBytes(outputBytes);

      stopwatch.stop();
      return FileOperationResult(
        outputPath: outputPath,
        fileSizeBytes: outputBytes.length,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return FileOperationResult(error: 'Failed to crop ID photo: $e');
    }
  }

  /// Enhance image for document scanning
  Future<String?> enhanceForScanning(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      // Enhance contrast and brightness for document readability
      var enhanced = img.adjustColor(
        original,
        contrast: 1.3,
        brightness: 1.05,
      );

      // Sharpen
      enhanced = img.convolution(
        enhanced,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
      );

      final outputDir = await _getOutputDirectory();
      final outputPath =
          '$outputDir/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outputPath)
          .writeAsBytes(img.encodeJpg(enhanced, quality: 92));

      return outputPath;
    } catch (e) {
      return null;
    }
  }

  /// Resize image for compression
  Future<Uint8List?> compressImage(
    String imagePath, {
    int maxWidth = 1920,
    int quality = 80,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      img.Image resized;
      if (original.width > maxWidth) {
        resized = img.copyResize(original, width: maxWidth);
      } else {
        resized = original;
      }

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      return null;
    }
  }

  Future<String> _getOutputDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/evergreen_images');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir.path;
  }
}

/// Standard ID photo types with dimensions
enum IdPhotoType {
  passport(35, 45, 413, 531, 'Passport (35×45mm)'),
  usVisa(51, 51, 600, 600, 'US Visa (2×2 inch)'),
  euId(35, 45, 413, 531, 'EU ID (35×45mm)'),
  driverLicense(25, 31, 295, 366, 'Driver License (25×31mm)');

  final int widthMm;
  final int heightMm;
  final int widthPx;
  final int heightPx;
  final String label;

  const IdPhotoType(
      this.widthMm, this.heightMm, this.widthPx, this.heightPx, this.label);

  double get aspectRatio => widthMm / heightMm;
}
