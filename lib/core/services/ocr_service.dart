import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/app_result.dart';

/// On-device OCR service using Google ML Kit
class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Perform OCR on a single image
  Future<AppResult<OcrResult>> recognizeText(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return AppResult.failure('Image file not found');
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage);

      if (recognized.text.isEmpty) {
        return AppResult.failure('No text found in the image');
      }

      final blocks = recognized.blocks.map((block) {
        double blockConfidence = 0;
        int lineCount = 0;
        for (final line in block.lines) {
          for (final element in line.elements) {
            blockConfidence += element.confidence ?? 0;
            lineCount++;
          }
        }
        return OcrBlock(
          text: block.text,
          confidence: lineCount > 0 ? blockConfidence / lineCount : 0,
        );
      }).toList();

      double totalConfidence = 0;
      int totalElements = 0;
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            totalConfidence += element.confidence ?? 0;
            totalElements++;
          }
        }
      }

      return AppResult.success(
        OcrResult(
          text: recognized.text,
          confidence: totalElements > 0 ? totalConfidence / totalElements : 0,
          blocks: blocks,
        ),
      );
    } catch (e) {
      return AppResult.failure('OCR failed: $e');
    }
  }

  /// Perform OCR on multiple images and combine results
  Future<AppResult<OcrResult>> recognizeTextFromMultiple(
    List<String> imagePaths,
  ) async {
    try {
      final allBlocks = <OcrBlock>[];
      final textParts = <String>[];
      double totalConfidence = 0;
      int totalBlocks = 0;

      for (final path in imagePaths) {
        final result = await recognizeText(path);
        result.when(
          success: (data) {
            textParts.add(data.text);
            allBlocks.addAll(data.blocks);
            totalConfidence += data.confidence;
            totalBlocks++;
          },
          failure: (_) {},
        );
      }

      if (textParts.isEmpty) {
        return AppResult.failure('No text found in any image');
      }

      return AppResult.success(
        OcrResult(
          text: textParts.join('\n\n--- Page Break ---\n\n'),
          confidence: totalBlocks > 0 ? totalConfidence / totalBlocks : 0,
          blocks: allBlocks,
        ),
      );
    } catch (e) {
      return AppResult.failure('Multi-page OCR failed: $e');
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
