import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  String? _filePath;
  final _rangesCtrl = TextEditingController(text: '1-3, 4-6');
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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() {
      _filePath = path;
      _results = [];
      _rangeError = null;
    });
  }

  /// Parses "1-3, 4-6, 7" → [[1,3],[4,6],[7,7]]
  List<String>? _parseRanges(String input) {
    final parts = input
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isEmpty) return null;

    for (final part in parts) {
      if (part.contains('-')) {
        final halves = part.split('-');
        if (halves.length != 2) return null;
        final start = int.tryParse(halves[0].trim());
        final end = int.tryParse(halves[1].trim());
        if (start == null || end == null || start < 1 || end < start) {
          return null;
        }
      } else {
        final page = int.tryParse(part);
        if (page == null || page < 1) return null;
      }
    }
    return parts;
  }

  Future<void> _split() async {
    if (_filePath == null) return;

    final rangeInput = _rangesCtrl.text.trim();
    final ranges = _parseRanges(rangeInput);

    if (ranges == null) {
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
          .splitPdf(inputPath: _filePath!, pageRanges: ranges);

      final docs = <DocumentModel>[];
      final errors = <String>[];
      for (int i = 0; i < results.length; i++) {
        final res = results[i];
        if (!res.isSuccess || res.outputPath == null) {
          if (res.error != null) errors.add(res.error!);
          continue;
        }
        final path = res.outputPath!;
        final rangeStr = i < ranges.length ? ranges[i] : '${i + 1}';
        final name = 'split_pages_$rangeStr';
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

      await ref.read(adServiceProvider).showInterstitialAfterTask();

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _results = docs;
      });
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.join('\n')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }

      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
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
                    ? 'Extract page ranges'
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
                        selectedPath: _filePath,
                        hint: 'Tap to select a PDF',
                        accept: 'PDF files only',
                        gradient: _gradient,
                        onTap: _pickFile,
                      ),

                      const SizedBox(height: 20),

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
        color: const Color(0xFFB91C1C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB91C1C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB91C1C),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter page ranges separated by commas. '
              'Example: 1-3, 4-6, 7 creates 3 separate files.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: AppTheme.textColor(isDark), fontSize: 15),
      decoration: InputDecoration(
        hintText: '1-3, 4-6, 7',
        hintStyle: TextStyle(color: AppTheme.textSecondaryColor(isDark)),
        helperText: 'Use commas to separate ranges (e.g. 1-3, 4-6, 7)',
        helperStyle: TextStyle(
          color: AppTheme.textSecondaryColor(isDark),
          fontSize: 12,
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFDB2777)),
        prefixIcon: Icon(
          Icons.numbers_rounded,
          color: AppTheme.textSecondaryColor(isDark),
          size: 20,
        ),
        filled: true,
        fillColor: AppTheme.cardColor(isDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(isDark)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(isDark)),
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
                  style: TextStyle(
                    color: AppTheme.textColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sizeLabel,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(isDark),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Share button
          GestureDetector(
            onTap: () => SharePlus.instance.share(
              ShareParams(files: [XFile(doc.filePath)], subject: doc.name),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.share_rounded,
                color: AppTheme.textSecondaryColor(isDark),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
