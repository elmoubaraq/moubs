import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class CompressPdfScreen extends ConsumerStatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  ConsumerState<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends ConsumerState<CompressPdfScreen> {
  String? _filePath;
  int _fileSize = 0;
  int _level = 1; // 0=max, 1=balanced, 2=light
  bool _isProcessing = false;

  // level → quality value
  static const _qualityMap = {0: 25, 1: 50, 2: 75};

  int get _quality => _qualityMap[_level]!;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    final size = File(path).existsSync() ? File(path).lengthSync() : 0;
    setState(() {
      _filePath = path;
      _fileSize = size;
    });
  }

  Future<void> _compress() async {
    if (_filePath == null) return;
    final name =
        ref.read(pdfServiceProvider).generateFileName('compressed');
    setState(() => _isProcessing = true);
    try {
      final result = await ref.read(pdfServiceProvider).compressPdf(
            inputPath: _filePath!,
            outputName: name,
            quality: _quality,
          );
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Operation failed');
      }
      final outputPath = result.outputPath!;

      final compressedSize =
          File(outputPath).existsSync() ? File(outputPath).lengthSync() : 0;

      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: name,
        filePath: outputPath,
        type: DocumentType.compressedPdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: compressedSize,
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);
      await ref.read(adServiceProvider).showInterstitialAfterTask();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CompressionResultSheet(
          originalSize: _fileSize,
          compressedSize: compressedSize,
          document: doc,
          gradient: _gradient,
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compression failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _fmt(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
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
                icon: Icons.compress_rounded,
                title: 'Compress PDF',
                subtitle: _filePath == null
                    ? 'Reduce file size'
                    : _fmt(_fileSize),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File picker
                      FilePickerZone(
                        selectedPath: _filePath,
                        hint: 'Tap to select a PDF',
                        accept: 'PDF files only',
                        gradient: _gradient,
                        onTap: _pickFile,
                      ),
                      const SizedBox(height: 24),

                      // Quality selector
                      const _SectionLabel('Compression Level'),
                      const SizedBox(height: 12),
                      ..._buildLevelCards(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: 'Compress PDF',
            primaryIcon: Icons.compress_rounded,
            enabled: _filePath != null && !_isProcessing,
            isLoading: _isProcessing,
            onPrimary: _compress,
          ),
        ),
        if (_isProcessing)
          ProcessingOverlay(
            gradient: _gradient,
            message: 'Compressing PDF…',
          ),
      ],
    );
  }

  List<Widget> _buildLevelCards() {
    const levels = [
      _LevelInfo(
        index: 0,
        label: 'Maximum',
        description: 'Smallest file size',
        badge: '25% quality',
        icon: Icons.rocket_launch_rounded,
      ),
      _LevelInfo(
        index: 1,
        label: 'Balanced',
        description: 'Good quality & size',
        badge: '50% quality',
        icon: Icons.balance_rounded,
      ),
      _LevelInfo(
        index: 2,
        label: 'Light',
        description: 'Best quality kept',
        badge: '75% quality',
        icon: Icons.high_quality_rounded,
      ),
    ];

    return levels
        .map(
          (l) => _LevelCard(
            info: l,
            isSelected: _level == l.index,
            gradient: _gradient,
            onTap: () => setState(() => _level = l.index),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (l.index * 60).ms)
              .slideX(begin: 0.1, curve: Curves.easeOut),
        )
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _LevelInfo {
  const _LevelInfo({
    required this.index,
    required this.label,
    required this.description,
    required this.badge,
    required this.icon,
  });
  final int index;
  final String label;
  final String description;
  final String badge;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.info,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  final _LevelInfo info;
  final bool isSelected;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEA580C).withValues(alpha: isDark ? 0.2 : 0.1)
              : AppTheme.cardColor(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEA580C)
                : AppTheme.borderColor(isDark),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                info.icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppTheme.textSecondary),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFEA580C)
                          : AppTheme.textColor(isDark),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                color: isSelected ? null : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                info.badge,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFFEA580C), size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.01, 1.01)),
    );
  }
}

// ---------------------------------------------------------------------------
// Compression Result Sheet
// ---------------------------------------------------------------------------

class _CompressionResultSheet extends StatelessWidget {
  const _CompressionResultSheet({
    required this.originalSize,
    required this.compressedSize,
    required this.document,
    required this.gradient,
  });

  final int originalSize;
  final int compressedSize;
  final DocumentModel document;
  final LinearGradient gradient;

  String _fmt(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  double get _reduction {
    if (originalSize <= 0) return 0;
    return ((originalSize - compressedSize) / originalSize * 100)
        .clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.borderColor(isDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Success icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 16),
          const Text(
            'Compression Complete!',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _StatCard(
                label: 'Original',
                value: _fmt(originalSize),
                gradient: null,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Compressed',
                value: _fmt(compressedSize),
                gradient: gradient,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reduction badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_reduction.toStringAsFixed(1)}% reduced',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Share.shareXFiles([XFile(document.filePath)],
                  subject: document.name),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                elevation: WidgetStateProperty.all(0),
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share Compressed PDF',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Done',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.gradient,
  });
  final String label;
  final String value;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Theme.of(context).colorScheme.surface : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: gradient != null
                    ? Colors.white70
                    : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
