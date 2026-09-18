import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class EncryptPdfScreen extends ConsumerStatefulWidget {
  const EncryptPdfScreen({super.key});

  @override
  ConsumerState<EncryptPdfScreen> createState() => _EncryptPdfScreenState();
}

class _EncryptPdfScreenState extends ConsumerState<EncryptPdfScreen> {
  String? _filePath;
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _allowPrinting = true;
  bool _allowCopy = false;
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  static const _gradient = LinearGradient(
    colors: [Color(0xFF374151), Color(0xFF4B5563)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Returns a strength score: 0=empty, 1=weak, 2=medium, 3=strong
  int _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9!@#\$&*~]').hasMatch(password)) score++;
    if (score == 0 && password.length >= 4) score = 1;
    return score;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _filePath = result.files.single.path;
    });
  }

  Future<void> _encrypt() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isProcessing = true);
    try {
      final base = _filePath!
          .split(RegExp(r'[\\/]'))
          .last
          .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      final name = '${base}_protected';
      final result = await ref
          .read(pdfServiceProvider)
          .encryptPdf(
            inputPath: _filePath!,
            password: _passCtrl.text,
            outputName: name,
            allowPrinting: _allowPrinting,
            allowCopy: _allowCopy,
          );
      if (!result.isSuccess || result.outputPath == null) {
        throw Exception(result.error ?? 'Operation failed');
      }
      final outputPath = result.outputPath!;

      final doc = DocumentModel(
        id: const Uuid().v4(),
        name: name,
        filePath: outputPath,
        type: DocumentType.encryptedPdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        fileSizeBytes: File(outputPath).existsSync()
            ? File(outputPath).lengthSync()
            : 0,
      );

      await ref.read(documentsProvider.notifier).addDocument(doc);

      if (mounted) {
        setState(() => _isProcessing = false);
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          builder: (_) => SuccessSheet(
            title: 'Encryption Complete!',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_passCtrl.text);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                ToolSliverHeader(
                  title: 'Encrypt PDF',
                  icon: Icons.lock_rounded,
                  gradient: _gradient,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Warning card
                      _WarningCard()
                          .animate()
                          .fadeIn(delay: 80.ms)
                          .slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      FilePickerZone(
                        selectedPath: _filePath,
                        hint: 'Select PDF File',
                        accept: 'PDF files only',
                        gradient: _gradient,
                        onTap: _pickFile,
                      ).animate().fadeIn(delay: 130.ms).slideY(begin: 0.1),

                      const SizedBox(height: 20),

                      // Password fields
                      _EncryptCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Password',
                              style: TextStyle(
                                color: AppTheme.textColor(
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Password field
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: !_showPass,
                              style: TextStyle(
                                color: AppTheme.textColor(
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(
                                context: context,
                                hint: 'Enter password',
                                prefixIcon: Icons.key_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _showPass
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _showPass = !_showPass),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 4) return 'Minimum 4 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Password strength bar
                            if (_passCtrl.text.isNotEmpty) ...[
                              _PasswordStrengthBar(strength: strength),
                              const SizedBox(height: 12),
                            ],

                            // Confirm password field
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: !_showConfirm,
                              style: TextStyle(
                                color: AppTheme.textColor(
                                  Theme.of(context).brightness ==
                                      Brightness.dark,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(
                                context: context,
                                hint: 'Confirm password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _showConfirm
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _showConfirm = !_showConfirm,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (v != _passCtrl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),

                      // Permissions
                      _EncryptCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Control what others can do with the encrypted file',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PermissionTile(
                              icon: Icons.print_rounded,
                              label: 'Allow Printing',
                              subtitle: 'Recipients can print the document',
                              value: _allowPrinting,
                              onChanged: (v) =>
                                  setState(() => _allowPrinting = v),
                            ),
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                              height: 1,
                            ),
                            _PermissionTile(
                              icon: Icons.copy_rounded,
                              label: 'Allow Copy',
                              subtitle: 'Recipients can copy text content',
                              value: _allowCopy,
                              onChanged: (v) => setState(() => _allowCopy = v),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.1),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: 'Encrypt PDF',
            primaryIcon: Icons.lock_rounded,
            enabled: _filePath != null && !_isProcessing,
            isLoading: _isProcessing,
            onPrimary: _encrypt,
          ),
        ),
        if (_isProcessing)
          const ProcessingOverlay(message: 'Encrypting PDF...'),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : AppTheme.textTertiary,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? Colors.white60 : AppTheme.textTertiary,
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B7280), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }
}

// ─── Warning Card ──────────────────────────────────────────────────────────

class _WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(
            0xFFF59E0B,
          ).withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Remember your password — encrypted files cannot be recovered without it.',
              style: TextStyle(
                color: Color(0xFFD97706),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Encrypt Card ──────────────────────────────────────────────────────────

class _EncryptCard extends StatelessWidget {
  const _EncryptCard({required this.child});
  final Widget child;

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
      child: child,
    );
  }
}

// ─── Password Strength Bar ─────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final labels = ['', 'Weak', 'Medium', 'Strong'];
    final colors = [
      Colors.transparent,
      Colors.redAccent,
      Colors.orange,
      const Color(0xFF22C55E),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final filled = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: 300.ms,
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled
                      ? colors[strength]
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: 200.ms,
          child: Text(
            strength > 0 ? labels[strength] : '',
            key: ValueKey(strength),
            style: TextStyle(
              color: colors[strength.clamp(0, 3)],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Permission Tile ───────────────────────────────────────────────────────

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      secondary: Icon(
        icon,
        color: isDark ? Colors.white70 : AppTheme.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: AppTheme.textColor(isDark),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.white38 : AppTheme.textTertiary,
          fontSize: 12,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF4B5563),
      activeTrackColor: const Color(0xFF6B7280).withValues(alpha: 0.5),
    );
  }
}
