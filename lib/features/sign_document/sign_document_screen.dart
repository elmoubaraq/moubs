import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
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

  int _step = 0;
  String? _pdfPath;
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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pdfPath = result.files.single.path;
      _step = 1;
    });
  }

  Future<void> _applySignature() async {
    final padState = _signaturePadKey.currentState;
    if (padState == null) return;

    setState(() => _processing = true);
    try {
      final image = await padState.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert signature to bytes');
      }
      final signatureBytes = byteData.buffer.asUint8List();

      final outputName = 'Signed_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref
          .read(pdfServiceProvider)
          .addSignatureToPdf(
            pdfPath: _pdfPath!,
            signatureBytes: signatureBytes,
            outputName: outputName,
          );
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Operation failed');
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
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);

      setState(() {
        _signedFilePath = filePath;
        _step = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _shareSignedPdf() async {
    if (_signedFilePath == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(_signedFilePath!)]),
    );
  }

  void _reset() {
    setState(() {
      _step = 0;
      _pdfPath = null;
      _signedFilePath = null;
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
                subtitle: 'Add your signature to a PDF',
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([_buildStepContent()]),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        FilePickerZone(
          selectedPath: _pdfPath,
          hint: 'Tap to pick a PDF file',
          accept: 'PDF files only',
          gradient: _gradient,
          onTap: _pickPdf,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSignStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected file info
        Container(
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
        ),
        const SizedBox(height: 20),

        // Signature pad
        Text(
          'Sign Here',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 16,
                  child: Text(
                    'Sign above the line',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Ink color picker
        Row(
          children: [
            Text(
              'Ink Color:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

        // Action buttons
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: _applySignature,
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text(
                    'Apply Signature',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _buildDoneStep() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: _gradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ).animate().scale(
          begin: const Offset(0, 0),
          duration: 500.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 20),
        Text(
          'Document Signed!',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Your signature has been applied successfully.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '/pdf-viewer',
                  extra: {
                    'filePath': _signedFilePath!,
                    'title': 'Signed Document',
                  },
                ),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('View PDF'),
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: _shareSignedPdf,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Sign Another Document'),
        ),
        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
