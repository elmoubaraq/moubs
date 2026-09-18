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

class WatermarkPdfScreen extends ConsumerStatefulWidget {
  const WatermarkPdfScreen({super.key});

  @override
  ConsumerState<WatermarkPdfScreen> createState() => _WatermarkPdfScreenState();
}

class _WatermarkPdfScreenState extends ConsumerState<WatermarkPdfScreen> {
  String? _filePath;
  final _textCtrl = TextEditingController(text: 'CONFIDENTIAL');
  double _fontSize = 50.0;
  double _opacity = 0.3;
  bool _isProcessing = false;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

    Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _filePath = result.files.single.path;
    });
  }

Future<void> _addWatermark() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first')),
      );
      return;
    }
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final name = 'watermarked_${const Uuid().v4()}.pdf';
      final result = await ref.read(pdfServiceProvider).watermarkPdf(
            inputPath: _filePath!,
            watermarkText: _textCtrl.text,
            outputName: name,
            fontSize: _fontSize,
            opacity: _opacity,
          );
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Operation failed');
      }
      final outputPath = result.outputPath!;

      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: name,
        filePath: outputPath,
        type: DocumentType.watermarkedPdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: File(outputPath).existsSync() ? File(outputPath).lengthSync() : 0,
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);

      if (mounted) {
        setState(() => _isProcessing = false);
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          builder: (_) => SuccessSheet(
            title: 'Watermark Added!',
            subtitle: doc.name,
            path: doc.filePath,
            gradient: _gradient,
            onDone: () {
              Navigator.pop(context);
              context.pop();
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
              title: 'Watermark PDF',
              subtitle: 'Add a text watermark overlay to your PDF',
              icon: Icons.water_drop_rounded,
              gradient: _gradient,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FilePickerZone(
                    selectedPath: _filePath,
                    hint: 'Select PDF File',
                    accept: 'PDF files only',
                    gradient: _gradient,
                    onTap: _pickFile,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  _SectionCard(
                    title: 'Watermark Text',
                    child: TextFormField(
                      controller: _textCtrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. CONFIDENTIAL',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        prefixIcon: const Icon(Icons.text_fields_rounded, color: Color(0xFF0EA5E9)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Live Preview Card
                  _WatermarkPreviewCard(
                    text: _textCtrl.text,
                    fontSize: _fontSize,
                    opacity: _opacity,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Font Size',
                    trailing: Text(
                      '${_fontSize.toStringAsFixed(0)}pt',
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF0EA5E9),
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: const Color(0xFF0EA5E9),
                        overlayColor: const Color(0xFF0EA5E9).withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _fontSize,
                        min: 20,
                        max: 100,
                        divisions: 16,
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Opacity',
                    trailing: Text(
                      '${(_opacity * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFF0EA5E9),
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                        thumbColor: const Color(0xFF0EA5E9),
                        overlayColor: const Color(0xFF0EA5E9).withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _opacity,
                        min: 0.1,
                        max: 0.9,
                        divisions: 8,
                        onChanged: (v) => setState(() => _opacity = v),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          gradient: _gradient,
          primaryLabel: 'Add Watermark',
          primaryIcon: Icons.water_drop_rounded,
          enabled: _filePath != null && !_isProcessing,
          isLoading: _isProcessing,
          onPrimary: _addWatermark,
        ),
      ),
      if (_isProcessing) const ProcessingOverlay(message: 'Adding Watermark...'),
    ],
  );
}
}

// ─── Live Preview Card ─────────────────────────────────────────────────────

class _WatermarkPreviewCard extends StatelessWidget {
  const _WatermarkPreviewCard({
    required this.text,
    required this.fontSize,
    required this.opacity,
  });

  final String text;
  final double fontSize;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated page lines
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              8,
              (i) => Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Corner decoration
          Positioned(
            top: 8,
            left: 8,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Watermark text
          Transform.rotate(
            angle: -0.5236, // -30 degrees
            child: Opacity(
              opacity: opacity,
              child: Text(
                text.isEmpty ? 'WATERMARK' : text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (fontSize * 0.5).clamp(12.0, 48.0),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0EA5E9),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          // Preview label
          Positioned(
            bottom: 8,
            right: 12,
            child: Text(
              'Preview',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.3),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Section Card ─────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textColor(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
