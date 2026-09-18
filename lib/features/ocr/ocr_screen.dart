import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  static const _gradient = LinearGradient(
    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  int _step = 0;
  String? _imagePath;
  bool _processing = false;
  double _confidence = 0.0;
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _imagePath = picked.path;
      _step = 0;
    });
    await _runOcr(picked.path);
  }

  Future<void> _runOcr(String path) async {
    setState(() => _processing = true);
    try {
      final result = await ref.read(ocrServiceProvider).recognizeText(path);
      result.when(
        success: (data) {
          setState(() {
            _confidence = data.confidence;
            _textCtrl.text = data.text;
            _step = 2;
          });
        },
        failure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OCR failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _exportAsPdf() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _processing = true);
    try {
      final name = 'OCR_Export_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref
          .read(pdfServiceProvider)
          .createPdfFromText(text: text, fileName: name);
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Failed to export PDF');
      }
      final filePath = result.outputPath!;
      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: name,
        filePath: filePath,
        type: DocumentType.ocrResult,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: File(filePath).existsSync()
            ? File(filePath).lengthSync()
            : 0,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        context.push(
          '/pdf-viewer',
          extra: {'filePath': filePath, 'title': name},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _textCtrl.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareText() async {
    await SharePlus.instance.share(ShareParams(text: _textCtrl.text));
  }

  void _reset() {
    setState(() {
      _step = 0;
      _imagePath = null;
      _confidence = 0.0;
      _textCtrl.clear();
    });
  }

  Color _confidenceColor(double confidence) {
    if (confidence > 80) return Colors.green;
    if (confidence > 50) return Colors.amber;
    return Colors.red;
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
                icon: Icons.text_fields_rounded,
                title: 'OCR Text Extraction',
                subtitle: 'Extract text from images using AI',
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (_step == 0) _buildPickStep(),
                    if (_step == 2 && _imagePath != null) ...[
                      _buildImagePreview(),
                      const SizedBox(height: 16),
                      _buildResultStep(),
                    ],
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

  Widget _buildPickStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Image Source',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SourceCard(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                description: 'Pick from your photo library',
                gradient: _gradient,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceCard(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                description: 'Take a photo now',
                gradient: _gradient,
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.asset(
            _imagePath!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image_rounded, size: 48, color: Colors.grey),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: _reset,
              icon: const Icon(Icons.close_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildResultStep() {
    final color = _confidenceColor(_confidence);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Extracted Text',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _ConfidenceBadge(confidence: _confidence, color: color),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _textCtrl,
            maxLines: null,
            minLines: 6,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              hintText: 'Extracted text will appear here…',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: _copyToClipboard,
                gradient: _gradient,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Export PDF',
                onTap: _exportAsPdf,
                gradient: _gradient,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: _shareText,
                gradient: _gradient,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08);
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence, required this.color});

  final double confidence;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '${confidence.toStringAsFixed(0)}% confidence',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
