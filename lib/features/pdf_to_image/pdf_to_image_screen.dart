import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_picker_helper.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class PdfToImageScreen extends ConsumerStatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  ConsumerState<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends ConsumerState<PdfToImageScreen> {
  String? _filePath;
  List<String> _imagePaths = [];
  bool _isProcessing = false;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Future<void> _pickFile() async {
    final path = await AppFilePicker.pickPdfFile(
      context,
      ref: ref,
      title: 'Select PDF to Convert to Images',
    );
    if (path == null) return;
    setState(() {
      _filePath = path;
      _imagePaths = [];
    });
  }

  Future<void> _extractImages() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _imagePaths = [];
    });

    try {
      final result = await ref.read(pdfServiceProvider).pdfToImages(
            pdfPath: _filePath!,
          );

      if (!mounted) return;

      if (result.isEmpty) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not extract images from this PDF'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      setState(() {
        _imagePaths = result;
        _isProcessing = false;
      });

      // Show rewarded ad or interstitial after completing the task
      try {
        await ref.read(adServiceProvider).showInterstitialAfterTask();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAllAsDocument() async {
    if (_imagePaths.isEmpty) return;

    final base = _filePath!
        .split(RegExp(r'[\\/]'))
        .last
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final name = '${base}_images';

    final firstImage = File(_imagePaths.first);
    final doc = DocumentModel(
      id: const Uuid().v4(),
      name: name,
      filePath: _imagePaths.first,
      type: DocumentType.other,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      fileSizeBytes: firstImage.existsSync() ? firstImage.lengthSync() : 0,
      pageCount: _imagePaths.length,
    );

    await ref.read(documentsProvider.notifier).addDocument(doc);

    if (mounted) {
      HapticFeedback.mediumImpact();
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        builder: (sheetCtx) => SuccessSheet(
          title: 'Images Saved!',
          subtitle: '${_imagePaths.length} pages converted to images',
          path: _imagePaths.first,
          gradient: _gradient,
          onDone: () {
            Navigator.pop(sheetCtx);
            context.pop();
          },
        ),
      );
    }
  }

  Future<void> _shareAll() async {
    if (_imagePaths.isEmpty) return;
    await Share.shareXFiles(
      _imagePaths.map((p) => XFile(p)).toList(),
      text: 'Extracted images from PDF',
    );
  }

  Future<void> _shareSingle(String path) async {
    await Share.shareXFiles([XFile(path)]);
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
                title: 'PDF to Images',
                subtitle: 'Convert PDF pages to high-quality images',
                icon: Icons.photo_library_rounded,
                gradient: _gradient,
                actions: _imagePaths.isNotEmpty
                    ? [
                        IconButton(
                          tooltip: 'Share all images',
                          icon: const Icon(Icons.share_rounded,
                              color: Colors.white),
                          onPressed: _shareAll,
                        ),
                      ]
                    : null,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FilePickerZone(
                      selectedPath: _filePath,
                      hint: 'Tap to select a PDF',
                      accept: 'Device or Google Drive',
                      gradient: _gradient,
                      onTap: _pickFile,
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    const SizedBox(height: 12),
                    const NativeAdWidget(maxHeight: 110),
                    const SizedBox(height: 12),

                    if (_imagePaths.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _ResultsHeader(
                        count: _imagePaths.length,
                        onShareAll: _shareAll,
                        onSaveAll: _saveAllAsDocument,
                      ).animate().fadeIn(delay: 50.ms),
                      const SizedBox(height: 12),
                      _ImageGrid(
                        imagePaths: _imagePaths,
                        onShare: _shareSingle,
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
                    ] else if (_filePath != null) ...[
                      const SizedBox(height: 24),
                      _ExtractHint().animate().fadeIn(delay: 150.ms),
                    ],
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: _imagePaths.isNotEmpty ? 'Save to Files' : 'Extract Images',
            primaryIcon: _imagePaths.isNotEmpty ? Icons.save_rounded : Icons.photo_library_rounded,
            enabled: _filePath != null && !_isProcessing,
            isLoading: _isProcessing,
            onPrimary: _imagePaths.isNotEmpty ? _saveAllAsDocument : _extractImages,
          ),
        ),
        if (_isProcessing)
          const ProcessingOverlay(message: 'Extracting Images...'),
      ],
    );
  }
}

// ─── Results Header ────────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.onShareAll,
    required this.onSaveAll,
  });

  final int count;
  final VoidCallback onShareAll;
  final VoidCallback onSaveAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'Image' : 'Images'} Extracted',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onShareAll,
          icon: const Icon(Icons.share_rounded,
              size: 16, color: Color(0xFFEC4899)),
          label: const Text(
            'Share All',
            style: TextStyle(
                color: Color(0xFFEC4899),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─── Image Grid ───────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.imagePaths, required this.onShare});

  final List<String> imagePaths;
  final void Function(String path) onShare;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.fileGridColumns(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: imagePaths.length,
      itemBuilder: (context, index) {
        return _ImageThumbnailCard(
          path: imagePaths[index],
          pageNumber: index + 1,
          onShare: () => onShare(imagePaths[index]),
        )
            .animate(delay: Duration(milliseconds: 60 * index))
            .fadeIn()
            .scale(begin: const Offset(0.92, 0.92));
      },
    );
  }
}

// ─── Image Thumbnail Card ─────────────────────────────────────────────────

class _ImageThumbnailCard extends StatelessWidget {
  const _ImageThumbnailCard({
    required this.path,
    required this.pageNumber,
    required this.onShare,
  });

  final String path;
  final int pageNumber;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white30, size: 40),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                Text(
                  'Page $pageNumber',
                  style: TextStyle(
                    color: AppTheme.textColor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Extract Hint ──────────────────────────────────────────────────────────

class _ExtractHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF9333EA).withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
            ).createShader(bounds),
            child: const Icon(Icons.photo_library_rounded,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to Extract',
            style: TextStyle(
              color: AppTheme.textColor(isDark),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Each page of your PDF will be converted to a high-quality image.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(isDark),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
