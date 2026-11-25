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

class UnlockPdfScreen extends ConsumerStatefulWidget {
  const UnlockPdfScreen({super.key});

  @override
  ConsumerState<UnlockPdfScreen> createState() => _UnlockPdfScreenState();
}

class _UnlockPdfScreenState extends ConsumerState<UnlockPdfScreen> {
  String? _filePath;
  bool? _isProtected;
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _isProcessing = false;
  String? _error;

  static final _gradient = AppTheme.toolGradients[13];

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final path = await AppFilePicker.pickPdfFile(
      context,
      ref: ref,
      title: 'Select Protected PDF to Unlock',
    );
    if (path == null) return;
    setState(() {
      _filePath = path;
      _isProtected = null;
      _error = null;
    });
    final protected = await ref
        .read(pdfServiceProvider)
        .isPasswordProtected(path);
    if (mounted && _filePath == path) {
      setState(() => _isProtected = protected);
    }
  }

  Future<void> _unlock() async {
    if (_filePath == null || _passCtrl.text.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final base = _filePath!
        .split(RegExp(r'[\\/]'))
        .last
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final name = '${base}_unlocked';
    final result = await ref
        .read(pdfServiceProvider)
        .decryptPdf(
          inputPath: _filePath!,
          password: _passCtrl.text,
          outputName: name,
        );

    if (!mounted) return;
    if (!result.isSuccess || result.outputPath == null) {
      setState(() {
        _isProcessing = false;
        _error = (result.error ?? 'Operation failed').replaceFirst(
          'Failed to unlock PDF: ',
          '',
        );
      });
      return;
    }

    final doc = DocumentModel(
      id: const Uuid().v4(),
      name: name,
      filePath: result.outputPath!,
      type: DocumentType.unlockedPdf,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      fileSizeBytes: result.fileSizeBytes ?? 0,
    );
    await ref.read(documentsProvider.notifier).addDocument(doc);
    try {
      await ref.read(adServiceProvider).showInterstitialAfterTask();
    } catch (_) {}
    if (!mounted) return;

    setState(() => _isProcessing = false);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (sheetCtx) => SuccessSheet(
        title: 'PDF Unlocked!',
        subtitle: doc.name,
        path: doc.filePath,
        gradient: _gradient,
        onDone: () {
          Navigator.pop(sheetCtx);
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUnlock =
        _filePath != null &&
        _isProtected != false &&
        _passCtrl.text.isNotEmpty &&
        !_isProcessing;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              ToolSliverHeader(
                title: 'Unlock PDF',
                subtitle: 'Remove password protection',
                icon: Icons.lock_open_rounded,
                gradient: _gradient,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _InfoBanner(
                      color: _gradient.colors.first,
                      text:
                          'You need the current password. Evergreen saves an '
                          'unprotected copy — your original stays untouched.',
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 16),
                    FilePickerZone(
                      selectedPath: _filePath,
                      hint: 'Select a protected PDF',
                      accept: 'Device or Google Drive',
                      gradient: _gradient,
                      onTap: _pickFile,
                    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    const NativeAdWidget(maxHeight: 110),
                    if (_isProtected == false) ...[
                      const SizedBox(height: 12),
                      const _InfoBanner(
                        color: AppTheme.info,
                        icon: Icons.check_circle_outline_rounded,
                        text:
                            'This PDF isn\'t password-protected — '
                            'there\'s nothing to unlock.',
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passCtrl,
                      obscureText: !_showPass,
                      enabled: _isProtected != false,
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => canUnlock ? _unlock() : null,
                      style: TextStyle(color: AppTheme.textColor(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        errorText: _error,
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPass
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                          tooltip: _showPass
                              ? 'Hide password'
                              : 'Show password',
                          onPressed: () =>
                              setState(() => _showPass = !_showPass),
                        ),
                      ),
                    ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: 'Unlock PDF',
            primaryIcon: Icons.lock_open_rounded,
            enabled: canUnlock,
            isLoading: _isProcessing,
            onPrimary: _unlock,
          ),
        ),
        if (_isProcessing)
          ProcessingOverlay(gradient: _gradient, message: 'Unlocking PDF…'),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  final Color color;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.textColor(isDark),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
