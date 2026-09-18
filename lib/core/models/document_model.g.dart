// GENERATED CODE - Manually created Hive adapter
// Equivalent to what build_runner would generate

import 'package:hive/hive.dart';
import 'document_model.dart';

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 0;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }
    return DocumentModel(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String,
      createdAt: fields[3] as DateTime,
      modifiedAt: fields[4] as DateTime,
      fileSizeBytes: fields[5] as int,
      type: fields[6] as DocumentType,
      pageCount: fields[7] as int? ?? 1,
      thumbnailPath: fields[8] as String?,
      tags: (fields[9] as List?)?.cast<String>() ?? [],
      isFavorite: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(11) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.modifiedAt)
      ..writeByte(5)
      ..write(obj.fileSizeBytes)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.pageCount)
      ..writeByte(8)
      ..write(obj.thumbnailPath)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentTypeAdapter extends TypeAdapter<DocumentType> {
  @override
  final int typeId = 1;

  @override
  DocumentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentType.scannedPdf;
      case 1:
        return DocumentType.imagePdf;
      case 2:
        return DocumentType.mergedPdf;
      case 3:
        return DocumentType.compressedPdf;
      case 4:
        return DocumentType.signedPdf;
      case 5:
        return DocumentType.importedPdf;
      case 6:
        return DocumentType.ocrResult;
      case 7:
        return DocumentType.idPhoto;
      case 8:
        return DocumentType.other;
      case 9:
        return DocumentType.splitPdf;
      case 10:
        return DocumentType.watermarkedPdf;
      case 11:
        return DocumentType.encryptedPdf;
      case 12:
        return DocumentType.textPdf;
      default:
        return DocumentType.other;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentType obj) {
    switch (obj) {
      case DocumentType.scannedPdf:
        writer.writeByte(0);
        break;
      case DocumentType.imagePdf:
        writer.writeByte(1);
        break;
      case DocumentType.mergedPdf:
        writer.writeByte(2);
        break;
      case DocumentType.compressedPdf:
        writer.writeByte(3);
        break;
      case DocumentType.signedPdf:
        writer.writeByte(4);
        break;
      case DocumentType.importedPdf:
        writer.writeByte(5);
        break;
      case DocumentType.ocrResult:
        writer.writeByte(6);
        break;
      case DocumentType.idPhoto:
        writer.writeByte(7);
        break;
      case DocumentType.other:
        writer.writeByte(8);
        break;
      case DocumentType.splitPdf:
        writer.writeByte(9);
        break;
      case DocumentType.watermarkedPdf:
        writer.writeByte(10);
        break;
      case DocumentType.encryptedPdf:
        writer.writeByte(11);
        break;
      case DocumentType.textPdf:
        writer.writeByte(12);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
