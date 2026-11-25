import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_picker_helper.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  String? _filePath;
  int? _pageCount;
  final _rangesCtrl = TextEditingController(text: '1-2, 3-4');
  bool _isProcessing = false;
  List<DocumentModel> _results = [];
  String? _rangeError;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFB91C1C), Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _rangesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final path = await AppFilePicker.pickPdfFile(
      context,
      ref: ref,
      title: 'Select PDF to Split',
    );
    if (path == null) return;

    final count = await ref.read(pdfServiceProvider).getPageCount(path) ?? 1;

    setState(() {
      _filePath = path;
      _pageCount = count;
      _results = [];
      _rangeError = null;

      if (count <= 1) {
        _rangesCtrl.text = '1';
      } else if (count == 2) {
        _rangesCtrl.text = '1, 2';
      } else if (count == 3) {
        _rangesCtrl.text = '1, 2-3';
      } else {
        final mid = count ~/ 2;
        _rangesCtrl.text = '1-$mid, ${mid + 1}-$count';
      }
    });
  }

  bool _isValidRanges(List<String> parts) {
    if (parts.isEmpty) return false;
    for (final p in parts) {
      if (p.contains('-')) {
        final halves = p.split('-');
        if (halves.length != 2) return false;
        final start = int.tryParse(halves[0].trim());
        final end = int.tryParse(halves[1].trim());
        if (start == null || end == null || start < 1 || end < start) {
          return false;
        }
      } else {
        final page = int.tryParse(p);
        if (page == null || page < 1) return false;
      }
    }
    return true;
  }

  Future<void> _split() async {
    if (_filePath == null) return;

    final rangeInput = _rangesCtrl.text.trim();
    final parts = rangeInput
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (!_isValidRanges(parts)) {
      setState(() {
        _rangeError = 'Invalid format. Use "1-3, 4-6, 7" (1-indexed pages).';
      });
      return;
    }

    setState(() {
      _rangeError = null;
      _isProcessing = true;
    });

    try {
      final results = await ref
          .read(pdfServiceProvider)
          .splitPdf(inputPath: _filePath!, pageRanges: parts);

      final docs = <DocumentModel>[];
      final errors = <String>[];
      for (int i = 0; i < results.length; i++) {
        final res = results[i];
        if (!res.isSuccess || res.outputPath == null) {
          if (res.error != null) errors.add(res.error!);
          continue;
        }
        final path = res.outputPath!;
        final range = parts[i];
        final name = range.contains('-')
            ? 'split_pages_$range'
            : 'split_page_$range';
        final size =
            res.fileSizeBytes ??
            (File(path).existsSync() ? File(path).lengthSync() : 0);

        final doc = DocumentModel(
          id: const Uuid().v4(),
          name: name,
          filePath: path,
          type: DocumentType.splitPdf,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          fileSizeBytes: size,
        );
        docs.add(doc);
        await ref.read(documentsProvider.notifier).addDocument(doc);
      }

      if (docs.isEmpty) {
        throw Exception(
          errors.isNotEmpty ? errors.first : 'No pages could be extracted from specified ranges.',
        );
      }

      try {
        await ref.read(adServiceProvider).showInterstitialAfterTask();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _results = docs;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Split failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _fmt(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              ToolSliverHeader(
                gradient: _gradient,
                icon: Icons.content_cut_rounded,
                title: 'Split PDF',
                subtitle: _results.isEmpty
                    ? (_pageCount != null
                        ? '$_pageCount page${_pageCount == 1 ? '' : 's'} in document'
                        : 'Extract page ranges')
                    : '${_results.length} file${_results.length == 1 ? '' : 's'} created',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      _InfoCard(),

                      const SizedBox(height: 16),

                      // File picker
                      FilePickerZone(
                        filePath: _filePath,
                        onTap: _pickFile,
                        gradient: _gradient,
                        icon: Icons.picture_as_pdf_rounded,
                        emptyLabel: 'Tap to select a PDF',
                        emptySubLabel: 'Device or Google Drive',
                      ),

                      const SizedBox(height: 12),
                      const NativeAdWidget(maxHeight: 110),
                      const SizedBox(height: 12),

                      // Page ranges field
                      _SectionLabel('Page Ranges'),
                      const SizedBox(height: 8),
                      _RangeField(
                        controller: _rangesCtrl,
                        errorText: _rangeError,
                        gradient: _gradient,
                        onChanged: (_) => setState(() => _rangeError = null),
                      ),

                      const SizedBox(height: 24),

                      // Results
                      if (_results.isNotEmpty) ...[
                        _SectionLabel('${_results.length} Files Created'),
                        const SizedBox(height: 10),
                        ..._buildResultTiles(),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: 'Split PDF',
            primaryIcon: Icons.content_cut_rounded,
            enabled: _filePath != null && !_isProcessing,
            isLoading: _isProcessing,
            onPrimary: _split,
          ),
        ),
        if (_isProcessing)
          ProcessingOverlay(gradient: _gradient, message: 'Splitting PDF…'),
      ],
    );
  }

  List<Widget> _buildResultTiles() {
    return List.generate(_results.length, (index) {
      final doc = _results[index];
      return _ResultTile(
            doc: doc,
            index: index,
            gradient: _gradient,
            sizeLabel: _fmt(doc.fileSizeBytes),
          )
          .animate()
          .fadeIn(duration: 300.ms, delay: (index * 60).ms)
          .slideY(begin: 0.15, curve: Curves.easeOut);
    });
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB91C1C).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB91C1C).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB91C1C),
            size: 18,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enter page ranges separated by commas. '
              'Example: 1-3, 4-6, 7 creates 3 separate files.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RangeField extends StatelessWidget {
  const _RangeField({
    required this.controller,
    required this.errorText,
    required this.gradient,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final LinearGradient gradient;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: '1-3, 4-6, 7',
        hintStyle: TextStyle(color: AppTheme.textSecondary),
        helperText: 'Use commas to separate ranges (e.g. 1-3, 4-6, 7)',
        helperStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFDB2777)),
        prefixIcon: Icon(
          Icons.numbers_rounded,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.doc,
    required this.index,
    required this.gradient,
    required this.sizeLabel,
  });

  final DocumentModel doc;
  final int index;
  final LinearGradient gradient;
  final String sizeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sizeLabel,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Share button
          GestureDetector(
            onTap: () =>
                Share.shareXFiles([XFile(doc.filePath)], subject: doc.name),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.share_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
