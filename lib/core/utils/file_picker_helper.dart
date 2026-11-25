import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

/// Centralized, robust file picker optimized for Google Drive, Cloud Storage,
/// and local device files across all tools.
class AppFilePicker {
  AppFilePicker._();

  /// Pick a single PDF file with full Google Drive & Cloud content URI caching.
  static Future<String?> pickPdfFile(
    BuildContext context, {
    WidgetRef? ref,
    String title = 'Select PDF Document',
  }) async {
    // Show selection sheet: Drive/Device or In-App Documents
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FileSourceSheet(title: title, ref: ref),
    );

    if (source == null) return null;

    if (source == 'evergreen' && ref != null) {
      if (!context.mounted) return null;
      return await _showEvergreenDocPicker(context, ref);
    }

    return await _pickFromStorageOrDrive();
  }

  /// Pick multiple PDF files with Google Drive support and local caching.
  static Future<List<String>> pickMultiplePdfFiles(
    BuildContext context, {
    WidgetRef? ref,
    String title = 'Select PDF Documents',
  }) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FileSourceSheet(
        title: title,
        ref: ref,
        isMultiple: true,
      ),
    );

    if (source == null) return [];

    if (source == 'evergreen' && ref != null) {
      if (!context.mounted) return [];
      return await _showEvergreenMultipleDocPicker(context, ref);
    }

    return await _pickMultipleFromStorageOrDrive();
  }

  /// Native file picker with full Google Drive & Cloud content URI caching.
  /// Note: withData MUST be false on Android to prevent Binder IPC TransactionTooLargeException (>1MB).
  static Future<String?> _pickFromStorageOrDrive() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'PDF'],
          withData: false,
          allowMultiple: false,
        );
      } catch (e) {
        // Fallback: If custom extensions failed or were blocked by Drive SAF filter
        result = await FilePicker.pickFiles(
          type: FileType.any,
          withData: false,
          allowMultiple: false,
        );
      }

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      return await _cacheFileIfNeeded(file);
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> _pickMultipleFromStorageOrDrive() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'PDF'],
          withData: false,
        );
      } catch (e) {
        result = await FilePicker.pickFiles(
          allowMultiple: true,
          type: FileType.any,
          withData: false,
        );
      }

      if (result == null || result.files.isEmpty) return [];

      final paths = <String>[];
      for (final file in result.files) {
        final path = await _cacheFileIfNeeded(file);
        if (path != null && !paths.contains(path)) {
          paths.add(path);
        }
      }
      return paths;
    } catch (_) {
      return [];
    }
  }

  /// Ensures cloud storage files (Google Drive, OneDrive, etc.) are cached
  /// to a valid local file path even if `file.path` is null.
  static Future<String?> _cacheFileIfNeeded(PlatformFile file) async {
    // If local file path exists and is readable, use it directly (standard Android SAF cache)
    if (file.path != null && File(file.path!).existsSync()) {
      return file.path;
    }

    // If file came from Google Drive / Cloud and only has stream or bytes
    try {
      final tempDir = await getTemporaryDirectory();
      final rawName = file.name.isNotEmpty
          ? file.name
          : 'cloud_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final cleanName = rawName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final targetPath = '${tempDir.path}/$cleanName';
      final targetFile = File(targetPath);

      if (file.readStream != null) {
        final sink = targetFile.openWrite();
        await sink.addStream(file.readStream!);
        await sink.close();
        return targetPath;
      }

      if (file.bytes != null && file.bytes!.isNotEmpty) {
        await targetFile.writeAsBytes(file.bytes!);
        return targetPath;
      }
    } catch (_) {
      return file.path;
    }

    return file.path;
  }

  /// Allows picking from existing saved documents in the app
  static Future<String?> _showEvergreenDocPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final docs = ref.read(documentsProvider);
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No documents saved in Evergreen yet.')),
      );
      return null;
    }

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Select from Evergreen Files',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.red),
                      title: Text(d.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${d.fileSizeFormatted} • ${d.pageCount} pages'),
                      onTap: () => Navigator.pop(ctx, d.filePath),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<List<String>> _showEvergreenMultipleDocPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final docs = ref.read(documentsProvider);
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No documents saved in Evergreen yet.')),
      );
      return [];
    }

    final selected = <String>{};

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Documents (${selected.length})',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, selected),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final d = docs[i];
                        final isSel = selected.contains(d.filePath);
                        return CheckboxListTile(
                          value: isSel,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                selected.add(d.filePath);
                              } else {
                                selected.remove(d.filePath);
                              }
                            });
                          },
                          secondary: const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.red),
                          title: Text(d.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              '${d.fileSizeFormatted} • ${d.pageCount} pages'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result?.toList() ?? [];
  }
}

class _FileSourceSheet extends StatelessWidget {
  final String title;
  final WidgetRef? ref;
  final bool isMultiple;

  const _FileSourceSheet({
    required this.title,
    this.ref,
    this.isMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasEvergreenDocs =
        ref != null && ref!.read(documentsProvider).isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.borderColor(isDark)),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_upload_rounded, color: Colors.blue),
            ),
            title: const Text('Browse Storage & Google Drive'),
            subtitle: const Text('Device files, Google Drive, Downloads, SD card'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => Navigator.pop(context, 'drive'),
          ),
          if (hasEvergreenDocs) ...[
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.borderColor(isDark)),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_special_rounded,
                    color: Color(0xFF10B981)),
              ),
              title: const Text('Evergreen My Files'),
              subtitle: Text(
                  '${ref!.read(documentsProvider).length} saved documents'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => Navigator.pop(context, 'evergreen'),
            ),
          ],
        ],
      ),
    );
  }
}
