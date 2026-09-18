import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class TextToPdfScreen extends ConsumerStatefulWidget {
  const TextToPdfScreen({super.key});

  @override
  ConsumerState<TextToPdfScreen> createState() => _TextToPdfScreenState();
}

class _TextToPdfScreenState extends ConsumerState<TextToPdfScreen> {
  static const _gradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late TextEditingController _nameCtrl;
  late TextEditingController _textCtrl;
  double _fontSize = 12.0;
  bool _processing = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: 'TextPDF_${DateTime.now().millisecondsSinceEpoch}',
    );
    _textCtrl = TextEditingController();
    _textCtrl.addListener(() {
      setState(() => _charCount = _textCtrl.text.length);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text first')),
      );
      return;
    }

    final name = _nameCtrl.text.trim().isEmpty
        ? 'TextPDF_${DateTime.now().millisecondsSinceEpoch}'
        : _nameCtrl.text.trim();

    setState(() => _processing = true);
    try {
      final result = await ref
          .read(pdfServiceProvider)
          .createPdfFromText(text: text, fileName: name, fontSize: _fontSize);
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Operation failed');
      }
      final filePath = result.outputPath!;
      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: name,
        filePath: filePath,
        type: DocumentType.textPdf,
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
            content: Text('Failed to generate PDF: $e'),
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
                icon: Icons.notes_rounded,
                title: 'Text to PDF',
                subtitle: 'Type content and export as PDF',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Document name
                    _buildNameInput(),
                    const SizedBox(height: 20),

                    // Font size slider
                    _buildFontSizeSection(),
                    const SizedBox(height: 20),

                    // Text editor
                    _buildTextEditor(),
                    const SizedBox(height: 8),

                    // Character counter
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_charCount characters',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            label: 'Generate PDF',
            gradient: _gradient,
            onPressed: _generatePdf,
            icon: Icons.picture_as_pdf_rounded,
          ),
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
          'Document Name',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
            hintText: 'Enter document name…',
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

  Widget _buildFontSizeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF047857).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF047857).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Font Size',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_fontSize.toInt()}pt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _fontSize,
            min: 8,
            max: 28,
            divisions: 20,
            activeColor: const Color(0xFF059669),
            onChanged: (v) => setState(() => _fontSize = v),
          ),
          // Preview text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Preview text at ${_fontSize.toInt()}pt',
              style: TextStyle(fontSize: _fontSize),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _textCtrl,
            maxLines: null,
            minLines: 10,
            style: TextStyle(fontSize: _fontSize),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(16),
              border: InputBorder.none,
              hintText:
                  'Start typing your document content here…\n\nYou can write paragraphs, notes, or any text you want to convert to a PDF.',
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}
