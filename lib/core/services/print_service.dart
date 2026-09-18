import 'dart:io';
import 'package:printing/printing.dart';

/// Sends PDFs to the system print dialog.
class PrintService {
  PrintService._();

  /// Opens the print dialog for [path]. Returns an error message on
  /// failure, or null on success/cancel.
  static Future<String?> printFile(String path, String jobName) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 'File not found';
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: jobName);
      return null;
    } catch (e) {
      return 'Couldn\'t print: $e';
    }
  }
}
