import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen> {
  static const _gradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final List<String> _images = [];
  late TextEditingController _nameCtrl;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: 'ImagePDF_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.map((f) => f.path));
    });
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() => _images.add(picked.path));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _clearAll() {
    setState(() => _images.clear());
  }

  Future<void> _createPdf() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    final name = _nameCtrl.text.trim().isEmpty
        ? 'ImagePDF_${DateTime.now().millisecondsSinceEpoch}'
        : _nameCtrl.text.trim();

    setState(() => _processing = true);
    try {
      final result = await ref.read(pdfServiceProvider).createPdfFromImages(
            imagePaths: _images,
            fileName: name,
          );
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Operation failed');
      }
      final filePath = result.outputPath!;
      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: name,
        filePath: filePath,
        type: DocumentType.imagePdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: File(filePath).existsSync() ? File(filePath).lengthSync() : 0,
      );
      await ref.read(documentsProvider.notifier).addDocument(doc);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processing = false);
    }
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
                icon: Icons.image_rounded,
                title: 'Image to PDF',
                subtitle: 'Convert images into a PDF document',
                
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // File name input
                    _buildNameInput(),
                    const SizedBox(height: 20),

                    // Source buttons
                    _buildSourceButtons(),
                    const SizedBox(height: 20),

                    // Image grid or empty state
                    if (_images.isEmpty)
                      _buildEmptyState()
                    else ...[
                      _buildGridHeader(),
                      const SizedBox(height: 10),
                      _buildImageGrid(),
                    ],
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _images.isNotEmpty
              ? BottomActionBar(
                  gradient: _gradient,
                  primaryLabel: 'Create PDF (${_images.length} image${_images.length == 1 ? '' : 's'})',
                  primaryIcon: Icons.picture_as_pdf_rounded,
                  enabled: !_processing,
                  isLoading: _processing,
                  onPrimary: _createPdf,
                )
              : null,
        ),
        if (_processing) const ProcessingOverlay(),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Name',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
            hintText: 'Enter file name…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSourceButtons() {
    return Row(
      children: [
        Expanded(
          child: _SourceButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            description: 'Select multiple',
            gradient: _gradient,
            onTap: _pickFromGallery,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SourceButton(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            description: 'Take a photo',
            gradient: _gradient,
            onTap: _pickFromCamera,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No images selected',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick images from gallery or camera',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildGridHeader() {
    return Row(
      children: [
        Text(
          '${_images.length} Image${_images.length == 1 ? '' : 's'}',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _clearAll,
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Clear All'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return _ImageGridItem(
          path: _images[index],
          pageNumber: index + 1,
          onRemove: () => _removeImage(index),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).scale(
              begin: const Offset(0.85, 0.85),
              duration: 300.ms,
              delay: (index * 50).ms,
            );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SourceButton extends StatelessWidget {
  const _SourceButton({
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageGridItem extends StatelessWidget {
  const _ImageGridItem({
    required this.path,
    required this.pageNumber,
    required this.onRemove,
  });

  final String path;
  final int pageNumber;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
            ),
          ),
        ),
        // Page number badge
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'p$pageNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
