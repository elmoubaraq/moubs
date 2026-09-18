import 'package:hive_flutter/hive_flutter.dart';

/// Core document model for all saved files
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime modifiedAt;

  @HiveField(5)
  final int fileSizeBytes;

  @HiveField(6)
  final DocumentType type;

  @HiveField(7)
  final int pageCount;

  @HiveField(8)
  final String? thumbnailPath;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final bool isFavorite;

  DocumentModel({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.modifiedAt,
    required this.fileSizeBytes,
    required this.type,
    this.pageCount = 1,
    this.thumbnailPath,
    this.tags = const [],
    this.isFavorite = false,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? filePath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? fileSizeBytes,
    DocumentType? type,
    int? pageCount,
    String? thumbnailPath,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      type: type ?? this.type,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension {
    return filePath.split('.').last.toUpperCase();
  }
}

enum DocumentType {
  scannedPdf,
  imagePdf,
  mergedPdf,
  compressedPdf,
  signedPdf,
  importedPdf,
  ocrResult,
  idPhoto,
  splitPdf,
  watermarkedPdf,
  encryptedPdf,
  textPdf,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.scannedPdf:
        return 'Scanned';
      case DocumentType.imagePdf:
        return 'Image PDF';
      case DocumentType.mergedPdf:
        return 'Merged';
      case DocumentType.compressedPdf:
        return 'Compressed';
      case DocumentType.signedPdf:
        return 'Signed';
      case DocumentType.importedPdf:
        return 'Imported';
      case DocumentType.ocrResult:
        return 'OCR';
      case DocumentType.idPhoto:
        return 'ID Photo';
      case DocumentType.splitPdf:
        return 'Split';
      case DocumentType.watermarkedPdf:
        return 'Watermarked';
      case DocumentType.encryptedPdf:
        return 'Encrypted';
      case DocumentType.textPdf:
        return 'Text PDF';
      case DocumentType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DocumentType.scannedPdf:
        return '📄';
      case DocumentType.imagePdf:
        return '🖼️';
      case DocumentType.mergedPdf:
        return '📑';
      case DocumentType.compressedPdf:
        return '📦';
      case DocumentType.signedPdf:
        return '✍️';
      case DocumentType.importedPdf:
        return '📁';
      case DocumentType.ocrResult:
        return '🔤';
      case DocumentType.idPhoto:
        return '🪪';
      case DocumentType.splitPdf:
        return '✂️';
      case DocumentType.watermarkedPdf:
        return '💧';
      case DocumentType.encryptedPdf:
        return '🔒';
      case DocumentType.textPdf:
        return '📝';
      case DocumentType.other:
        return '📋';
    }
  }
}
