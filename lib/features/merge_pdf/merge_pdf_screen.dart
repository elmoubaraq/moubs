import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_picker_helper.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  final List<String> _files = [];
  bool _isProcessing = false;
  late final TextEditingController _nameCtrl;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: ref.read(pdfServiceProvider).generateFileName('merged'),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final paths = await AppFilePicker.pickMultiplePdfFiles(
      context,
      ref: ref,
      title: 'Select PDFs to Merge',
    );
    if (paths.isEmpty) return;
    setState(() {
      for (final path in paths) {
        if (!_files.contains(path)) {
          _files.add(path);
        }
      }
    });
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _files.removeAt(oldIndex);
      _files.insert(newIndex, item);
    });
  }

  String _fileName(String path) => path.split(RegExp(r'[/\\]')).last;

  String _fileSizeBadge(String path) {
    try {
      final f = File(path);
      final bytes = f.existsSync() ? f.lengthSync() : 0;
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } catch (_) {
      return '';
    }
  }

  Future<void> _merge() async {
    if (_files.length < 2) return;
    final outputName = _nameCtrl.text.trim().isEmpty
        ? ref.read(pdfServiceProvider).generateFileName('merged')
        : _nameCtrl.text.trim();

    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(pdfServiceProvider)
          .mergePdfs(pdfPaths: _files, outputName: outputName);

      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Merge failed');
      }
      final outputPath = result.outputPath!;

      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: outputName,
        filePath: outputPath,
        type: DocumentType.mergedPdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: result.fileSizeBytes ??
            (File(outputPath).existsSync()
                ? File(outputPath).lengthSync()
                : 0),
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);
      try {
        await ref.read(adServiceProvider).showInterstitialAfterTask();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isProcessing = false);

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SuccessSheet(
          title: 'Merge Complete!',
          subtitle:
              'Your ${_files.length} PDFs have been merged into one file.',
          path: doc.filePath,
          gradient: _gradient,
          onDone: () {
            Navigator.pop(context);
          },
        ),
      );

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Merge failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              ToolSliverHeader(
                gradient: _gradient,
                icon: Icons.merge_rounded,
                title: 'Merge PDFs',
                subtitle:
                    '${_files.length} file${_files.length == 1 ? '' : 's'} selected',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File picker zone
                      _PickerZone(onTap: _pickFiles, gradient: _gradient),
                      const SizedBox(height: 12),
                      const NativeAdWidget(maxHeight: 110),
                      const SizedBox(height: 12),

                      if (_files.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'Files to Merge',
                          trailing: Text(
                            'Drag to reorder',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFileList(),
                        const SizedBox(height: 20),
                      ],

                      // Output name field
                      _SectionLabel(label: 'Output File Name'),
                      const SizedBox(height: 8),
                      _OutputNameField(controller: _nameCtrl),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: 'Merge PDFs',
            primaryIcon: Icons.merge_rounded,
            enabled: _files.length >= 2 && !_isProcessing,
            isLoading: _isProcessing,
            onPrimary: _merge,
          ),
        ),
        if (_isProcessing)
          ProcessingOverlay(message: 'Merging ${_files.length} PDFs…'),
      ],
    );
  }

  Widget _buildFileList() {
    return SizedBox(
      height: (_files.length * 72.0).clamp(0, 360),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        itemCount: _files.length,
        onReorder: _reorder,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) => Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: child,
        ),
        itemBuilder: (context, index) {
          final path = _files[index];
          final name = _fileName(path);
          final size = _fileSizeBadge(path);
          return _FileTile(
                key: ValueKey(path),
                index: index,
                name: name,
                sizeBadge: size,
                gradient: _gradient,
                onDelete: () => _removeFile(index),
              )
              .animate()
              .fadeIn(duration: 250.ms, delay: (index * 40).ms)
              .slideX(begin: 0.15, curve: Curves.easeOut);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _PickerZone extends StatelessWidget {
  const _PickerZone({required this.onTap, required this.gradient});
  final VoidCallback onTap;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to select PDFs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You can select multiple files at once',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    super.key,
    required this.index,
    required this.name,
    required this.sizeBadge,
    required this.gradient,
    required this.onDelete,
  });

  final int index;
  final String name;
  final String sizeBadge;
  final LinearGradient gradient;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: sizeBadge.isNotEmpty
            ? Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sizeBadge,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: onDelete,
              splashRadius: 20,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle_rounded,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _OutputNameField extends StatelessWidget {
  const _OutputNameField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'merged_document',
        hintStyle: TextStyle(color: AppTheme.textSecondary),
        suffixText: '.pdf',
        suffixStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
      ),
    );
  }
}
