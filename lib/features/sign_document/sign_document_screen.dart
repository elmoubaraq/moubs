import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/file_picker_helper.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class SignDocumentScreen extends ConsumerStatefulWidget {
  const SignDocumentScreen({super.key});

  @override
  ConsumerState<SignDocumentScreen> createState() => _SignDocumentScreenState();
}

class _SignDocumentScreenState extends ConsumerState<SignDocumentScreen> {
  static const _gradient = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final GlobalKey<SfSignaturePadState> _signaturePadKey =
      GlobalKey<SfSignaturePadState>();

  int _step = 0; // 0: Pick PDF, 1: Sign, 2: Place, 3: Done
  String? _pdfPath;
  int _pageCount = 1;
  int _selectedPageIndex = 0;
  Uint8List? _signatureBytes;
  Uint8List? _pagePreviewBytes;
  bool _isLoadingPreview = false;

  // Normalized placement on page (0.0 to 1.0)
  double _posX = 0.55;
  double _posY = 0.80;
  double _sigScale = 0.30; // 30% of page width

  bool _processing = false;
  Color _inkColor = Colors.black;
  String? _signedFilePath;

  static const _inkColors = [
    Colors.black,
    Colors.blue,
    Colors.green,
    Colors.red,
  ];

  Future<void> _pickPdf() async {
    final path = await AppFilePicker.pickPdfFile(
      context,
      ref: ref,
      title: 'Select PDF to Sign',
    );
    if (path == null) return;

    final count = await ref.read(pdfServiceProvider).getPageCount(path);
    setState(() {
      _pdfPath = path;
      _pageCount = (count == null || count < 1) ? 1 : count;
      _selectedPageIndex = 0;
      _step = 1;
    });
  }

  Future<void> _captureSignatureAndProceed() async {
    final padState = _signaturePadKey.currentState;
    if (padState == null) return;

    setState(() => _processing = true);
    try {
      final image = await padState.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not capture signature');
      }
      final bytes = byteData.buffer.asUint8List();

      setState(() {
        _signatureBytes = bytes;
        _step = 2;
      });

      await _loadPagePreview(_selectedPageIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _loadPagePreview(int pageIndex) async {
    if (_pdfPath == null) return;
    setState(() => _isLoadingPreview = true);
    try {
      final pdfBytes = await File(_pdfPath!).readAsBytes();
      await for (final page in Printing.raster(pdfBytes, pages: [pageIndex], dpi: 150)) {
        final png = await page.toPng();
        if (mounted && _selectedPageIndex == pageIndex) {
          setState(() {
            _pagePreviewBytes = png;
            _isLoadingPreview = false;
          });
          break;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  Future<void> _applySignature() async {
    if (_pdfPath == null || _signatureBytes == null) return;

    setState(() => _processing = true);
    try {
      final outputName = 'Signed_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(pdfServiceProvider).addSignatureToPdf(
            pdfPath: _pdfPath!,
            signatureBytes: _signatureBytes!,
            outputName: outputName,
            pageIndex: _selectedPageIndex,
            normalizedX: _posX,
            normalizedY: _posY,
            normalizedWidth: _sigScale,
            normalizedHeight: _sigScale * 0.45,
          );

      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Signing failed');
      }

      final filePath = result.outputPath!;
      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: outputName,
        filePath: filePath,
        type: DocumentType.signedPdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: File(filePath).existsSync()
            ? File(filePath).lengthSync()
            : 0,
        pageCount: _pageCount,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      await ref.read(adServiceProvider).showInterstitialAfterTask();

      setState(() {
        _signedFilePath = filePath;
        _step = 3;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _shareSignedPdf() async {
    if (_signedFilePath == null) return;
    await Share.shareXFiles([XFile(_signedFilePath!)], text: 'Signed Document');
  }

  void _reset() {
    setState(() {
      _step = 0;
      _pdfPath = null;
      _signatureBytes = null;
      _pagePreviewBytes = null;
      _signedFilePath = null;
      _selectedPageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: CustomScrollView(
            slivers: [
              ToolSliverHeader(
                gradient: _gradient,
                icon: Icons.draw_rounded,
                title: 'Sign Document',
                subtitle: 'Place your signature directly on any page',
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStepContent(),
                    const SizedBox(height: 16),
                    const NativeAdWidget(maxHeight: 110),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (_processing) const ProcessingOverlay(),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildPickStep();
      case 1:
        return _buildSignStep();
      case 2:
        return _buildPlacementStep();
      case 3:
        return _buildDoneStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPickStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a PDF to Sign',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        FilePickerZone(
          selectedPath: _pdfPath,
          hint: 'Tap to pick from Device or Google Drive',
          accept: 'PDF documents',
          gradient: _gradient,
          onTap: _pickPdf,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildSignStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFileBadge(),
        const SizedBox(height: 20),
        Text(
          'Create Your Signature',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SfSignaturePad(
                  key: _signaturePadKey,
                  strokeColor: _inkColor,
                  minimumStrokeWidth: 1.5,
                  maximumStrokeWidth: 4.0,
                  backgroundColor: Colors.white,
                ),
                Positioned(
                  bottom: 8,
                  left: 16,
                  child: Text(
                    'Sign with finger or stylus',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Ink Color:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            ..._inkColors.map(
              (color) => _ColorCircle(
                color: color,
                isSelected: _inkColor == color,
                onTap: () => setState(() => _inkColor = color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _signaturePadKey.currentState?.clear(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _captureSignatureAndProceed,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                label: const Text(
                  'Next: Place on PDF',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7490),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlacementStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFileBadge(),
        const SizedBox(height: 16),

        // Page selector header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Position Signature',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _selectedPageIndex > 0
                      ? () {
                          setState(() => _selectedPageIndex--);
                          _loadPagePreview(_selectedPageIndex);
                        }
                      : null,
                ),
                Text(
                  'Page ${_selectedPageIndex + 1} of $_pageCount',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _selectedPageIndex < _pageCount - 1
                      ? () {
                          setState(() => _selectedPageIndex++);
                          _loadPagePreview(_selectedPageIndex);
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Interactive Page Placement Canvas
        Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 380, maxWidth: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0E7490).withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _isLoadingPreview
                  ? const Center(
                      child: SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        final canvasWidth = constraints.maxWidth;
                        final canvasHeight = constraints.maxHeight > 0
                            ? constraints.maxHeight
                            : 360.0;

                        final sigPixelWidth = canvasWidth * _sigScale;
                        final sigPixelHeight = sigPixelWidth * 0.45;

                        final pixelX = (_posX * (canvasWidth - sigPixelWidth))
                            .clamp(0.0, canvasWidth - sigPixelWidth);
                        final pixelY = (_posY * (canvasHeight - sigPixelHeight))
                            .clamp(0.0, canvasHeight - sigPixelHeight);

                        return Stack(
                          children: [
                            // Page background
                            if (_pagePreviewBytes != null)
                              Image.memory(
                                _pagePreviewBytes!,
                                width: canvasWidth,
                                height: canvasHeight,
                                fit: BoxFit.contain,
                              )
                            else
                              Container(
                                width: canvasWidth,
                                height: canvasHeight,
                                color: Colors.white,
                                child: Center(
                                  child: Text('Page ${_selectedPageIndex + 1}'),
                                ),
                              ),

                            // Draggable Signature Box
                            Positioned(
                              left: pixelX,
                              top: pixelY,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    final newPixelX = pixelX + details.delta.dx;
                                    final newPixelY = pixelY + details.delta.dy;
                                    final maxX = canvasWidth - sigPixelWidth;
                                    final maxY = canvasHeight - sigPixelHeight;

                                    if (maxX > 0) {
                                      _posX = (newPixelX / maxX).clamp(0.0, 1.0);
                                    }
                                    if (maxY > 0) {
                                      _posY = (newPixelY / maxY).clamp(0.0, 1.0);
                                    }
                                  });
                                },
                                child: Container(
                                  width: sigPixelWidth,
                                  height: sigPixelHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF0E7490),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: const Color(0xFF0E7490)
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_signatureBytes != null)
                                        Center(
                                          child: Image.memory(
                                            _signatureBytes!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      const Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Icon(
                                          Icons.open_with_rounded,
                                          size: 14,
                                          color: Color(0xFF0E7490),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Drag signature box to place it anywhere on this page',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),

        // Quick position presets
        Text(
          'Quick Placement:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _PresetChip(
              label: 'Bottom Right',
              onTap: () => setState(() {
                _posX = 0.65;
                _posY = 0.85;
              }),
            ),
            _PresetChip(
              label: 'Bottom Left',
              onTap: () => setState(() {
                _posX = 0.05;
                _posY = 0.85;
              }),
            ),
            _PresetChip(
              label: 'Center',
              onTap: () => setState(() {
                _posX = 0.35;
                _posY = 0.50;
              }),
            ),
            _PresetChip(
              label: 'Top Right',
              onTap: () => setState(() {
                _posX = 0.65;
                _posY = 0.10;
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Size slider
        Row(
          children: [
            const Icon(Icons.aspect_ratio_rounded, size: 20),
            const SizedBox(width: 8),
            const Text('Size:'),
            Expanded(
              child: Slider(
                value: _sigScale,
                min: 0.15,
                max: 0.60,
                divisions: 9,
                label: '${(_sigScale * 100).round()}%',
                onChanged: (v) => setState(() => _sigScale = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back to Pad'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _applySignature,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: const Text(
                  'Apply Signature',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7490),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Document Signed!',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Signature applied to page ${_selectedPageIndex + 1}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            if (_signedFilePath != null) {
              context.push('/pdf-viewer', extra: {
                'filePath': _signedFilePath,
                'title': 'Signed Document',
              });
            }
          },
          icon: const Icon(Icons.visibility_rounded, color: Colors.white),
          label: const Text(
            'Open Signed PDF',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E7490),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _shareSignedPdf,
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share Document'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _reset,
          child: const Text('Sign Another PDF'),
        ),
      ],
    );
  }

  Widget _buildFileBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E7490).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0E7490).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: Color(0xFF0E7490),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pdfPath!.split('/').last.split('\\').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0E7490),
                  ),
            ),
          ),
          GestureDetector(
            onTap: _reset,
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF0E7490),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
