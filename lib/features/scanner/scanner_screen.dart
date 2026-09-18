import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  List<String> _pages = [];
  bool _enhanceContrast = true;
  bool _isProcessing = false;
  late TextEditingController _nameCtrl;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: ref.read(pdfServiceProvider).generateFileName('scan'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    try {
      HapticFeedback.mediumImpact();
      final images =
          await CunningDocumentScanner.getPictures(
            noOfPages: 50,
            scannerSource: ScannerSource.cameraAndGallery,
          ) ??
          [];
      if (mounted && images.isNotEmpty) {
        setState(() => _pages = [..._pages, ...images]);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_pages.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    try {
      final svc = ref.read(pdfServiceProvider);
      final result = await svc.createScannedPdf(
        scannedImagePaths: _pages,
        fileName: _nameCtrl.text.trim().isEmpty
            ? 'scan'
            : _nameCtrl.text.trim(),
        enhanceContrast: _enhanceContrast,
      );
      if (result.isSuccess && mounted) {
        final name = '${_nameCtrl.text.trim()}.pdf';
        final doc = DocumentModel(
          id: const Uuid().v4(),
          name: name,
          filePath: result.outputPath!,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          fileSizeBytes: result.fileSizeBytes ?? 0,
          type: DocumentType.scannedPdf,
          pageCount: _pages.length,
          thumbnailPath: null,
          tags: ['scanned'],
          isFavorite: false,
        );
        ref.read(documentsProvider.notifier).addDocument(doc);
        await ref.read(adServiceProvider).showInterstitialAfterTask();
        HapticFeedback.heavyImpact();
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isDismissible: false,
            builder: (_) => SuccessSheet(
              title: 'PDF Created!',
              subtitle: name,
              path: result.outputPath!,
              gradient: _gradient,
              onDone: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              ToolSliverHeader(
                title: 'Document Scanner',
                subtitle:
                    '${_pages.length} page${_pages.length != 1 ? 's' : ''} ready',
                gradient: _gradient,
                icon: Icons.document_scanner_rounded,
              ),

              // Options
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File Name',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter file name',
                          suffixText: '.pdf',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SurfaceCard(
                        child: SwitchListTile(
                          title: const Text(
                            'Enhance Contrast',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text('Auto-clean and sharpen scans'),
                          value: _enhanceContrast,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _enhanceContrast = v);
                          },
                          secondary: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_fix_high_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pages
              if (_pages.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Pages (${_pages.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add More'),
                          onPressed: _startScan,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _pages.length,
                      itemBuilder: (context, i) {
                        return Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      _pages[i],
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 160,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 110,
                                        height: 160,
                                        color: isDark
                                            ? AppTheme.cardDark2
                                            : const Color(0xFFF3F4F6),
                                        child: const Icon(
                                          Icons.image_outlined,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _pages.removeAt(i));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 50))
                            .scale(begin: const Offset(0.85, 0.85));
                      },
                    ),
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.document_scanner_outlined,
                    title: 'No Pages Yet',
                    subtitle: 'Tap Start Scanning to begin',
                    actionLabel: 'Start Scanning',
                    onAction: _startScan,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomActionBar(
              gradient: _gradient,
              primaryLabel: 'Create PDF',
              primaryIcon: Icons.picture_as_pdf_rounded,
              enabled: _pages.isNotEmpty && !_isProcessing,
              isLoading: _isProcessing,
              onPrimary: _save,
              secondaryLabel: 'Add Pages',
              secondaryIcon: Icons.add_photo_alternate_rounded,
              onSecondary: _startScan,
            ),
          ),

          if (_isProcessing)
            const ProcessingOverlay(message: 'Creating your PDF...'),
        ],
      ),
    );
  }
}
