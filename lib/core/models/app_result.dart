/// Result wrapper for all operations
class AppResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const AppResult._({this.data, this.error, required this.isSuccess});

  factory AppResult.success(T data) =>
      AppResult._(data: data, isSuccess: true);

  factory AppResult.failure(String error) =>
      AppResult._(error: error, isSuccess: false);

  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    }
    return failure(error ?? 'Unknown error');
  }
}

/// Processing state for async operations
enum ProcessingState {
  idle,
  processing,
  success,
  error,
}

/// File operation result
class FileOperationResult {
  final String? outputPath;
  final int? fileSizeBytes;
  final String? error;
  final Duration? processingTime;

  const FileOperationResult({
    this.outputPath,
    this.fileSizeBytes,
    this.error,
    this.processingTime,
  });

  bool get isSuccess => outputPath != null && error == null;
}

/// OCR Result
class OcrResult {
  final String text;
  final double confidence;
  final List<OcrBlock> blocks;

  const OcrResult({
    required this.text,
    required this.confidence,
    this.blocks = const [],
  });
}

class OcrBlock {
  final String text;
  final double confidence;

  const OcrBlock({
    required this.text,
    required this.confidence,
  });
}
