import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/image_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

class IdPhotoScreen extends ConsumerStatefulWidget {
  const IdPhotoScreen({super.key});

  @override
  ConsumerState<IdPhotoScreen> createState() => _IdPhotoScreenState();
}

class _IdPhotoScreenState extends ConsumerState<IdPhotoScreen> {
  IdPhotoType _selectedType = IdPhotoType.passport;
  String? _originalPath;
  String? _croppedPath;
  bool _isProcessing = false;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _picker = ImagePicker();

  /// Maps each [IdPhotoType] to its display name and dimension string.
  static const _typeInfo = {
    IdPhotoType.passport: (
      label: 'Passport',
      dims: '35 × 45 mm  •  413 × 531 px',
      icon: Icons.travel_explore_rounded,
    ),
    IdPhotoType.usVisa: (
      label: 'US Visa',
      dims: '51 × 51 mm  •  600 × 600 px',
      icon: Icons.flag_rounded,
    ),
    IdPhotoType.euId: (
      label: 'EU ID',
      dims: '35 × 45 mm  •  413 × 531 px',
      icon: Icons.euro_rounded,
    ),
    IdPhotoType.driverLicense: (
      label: 'Driver\'s License',
      dims: '25 × 31 mm  •  295 × 366 px',
      icon: Icons.drive_eta_rounded,
    ),
  };

  Future<void> _pickFromGallery() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() {
        _originalPath = xFile.path;
        _croppedPath = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile != null) {
      setState(() {
        _originalPath = xFile.path;
        _croppedPath = null;
      });
    }
  }

  Future<void> _cropPhoto() async {
    if (_originalPath == null) return;

    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(imageServiceProvider)
          .cropIdPhoto(imagePath: _originalPath!, photoType: _selectedType);
      if (mounted) {
        if (result.isSuccess && result.outputPath != null) {
          setState(() {
            _croppedPath = result.outputPath;
            _isProcessing = false;
          });

          // Show interstitial or rewarded ad after completing
          await ref.read(adServiceProvider).showInterstitialAfterTask();
        } else {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Crop failed'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sharePhoto() async {
    final path = _croppedPath ?? _originalPath;
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: 'ID Photo');
  }

  Future<void> _saveToDocuments() async {
    final path = _croppedPath ?? _originalPath;
    if (path == null) return;

    final file = File(path);
    final doc = DocumentModel(
      id: const Uuid().v4(),
      name: 'ID_Photo_${_typeInfo[_selectedType]!.label}',
      filePath: path,
      type: DocumentType.idPhoto,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      fileSizeBytes: file.existsSync() ? file.lengthSync() : 0,
      pageCount: 1,
    );

    await ref.read(documentsProvider.notifier).addDocument(doc);

    if (mounted) {
      HapticFeedback.mediumImpact();
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        builder: (sheetCtx) => SuccessSheet(
          title: 'ID Photo Saved!',
          subtitle: '${_typeInfo[_selectedType]!.label} format',
          path: path,
          gradient: _gradient,
          onDone: () {
            Navigator.pop(sheetCtx);
            context.pop();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _typeInfo[_selectedType]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              ToolSliverHeader(
                title: 'ID Photo',
                subtitle: 'Format photos for official identity cards',
                icon: Icons.badge_rounded,
                gradient: _gradient,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Format selector
                    _IdCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photo Format',
                            style: TextStyle(
                              color: AppTheme.textColor(isDark),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: IdPhotoType.values.map((type) {
                              final t = _typeInfo[type]!;
                              final selected = _selectedType == type;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedType = type;
                                  _croppedPath = null;
                                }),
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFDC2626)
                                            .withValues(alpha: isDark ? 0.25 : 0.12)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.04)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFDC2626)
                                          : AppTheme.borderColor(isDark),
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        t.icon,
                                        size: 16,
                                        color: selected
                                            ? const Color(0xFFEF4444)
                                            : AppTheme.textSecondaryColor(isDark),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.label,
                                        style: TextStyle(
                                          color: selected
                                              ? (isDark ? Colors.white : const Color(0xFFDC2626))
                                              : AppTheme.textColor(isDark),
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    const SizedBox(height: 12),

                    // Info card
                    _DimensionsCard(
                      label: info.label,
                      dims: info.dims,
                      icon: info.icon,
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    const SizedBox(height: 16),

                    // Source buttons
                    _IdCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Source',
                            style: TextStyle(
                              color: AppTheme.textColor(isDark),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SourceButton(
                                  icon: Icons.photo_library_rounded,
                                  label: 'Gallery',
                                  onTap: _pickFromGallery,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SourceButton(
                                  icon: Icons.camera_alt_rounded,
                                  label: 'Camera',
                                  onTap: _pickFromCamera,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    if (_originalPath != null) ...[
                      const SizedBox(height: 20),

                      // Original preview
                      _PhotoPreviewSection(
                        label: 'Original Photo',
                        imagePath: _originalPath!,
                        actions: [
                          _ActionButton(
                            icon: Icons.crop_rounded,
                            label: 'Crop to ID Size',
                            gradient: _gradient,
                            onTap: _cropPhoto,
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    ],

                    if (_croppedPath != null) ...[
                      const SizedBox(height: 20),

                      // Cropped result
                      _PhotoPreviewSection(
                            label: 'Cropped Result',
                            imagePath: _croppedPath!,
                            badge: _typeInfo[_selectedType]!.label,
                            actions: [
                              _ActionButton(
                                icon: Icons.share_rounded,
                                label: 'Share',
                                onTap: _sharePhoto,
                              ),
                              _ActionButton(
                                icon: Icons.save_rounded,
                                label: 'Save to Files',
                                gradient: _gradient,
                                onTap: _saveToDocuments,
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 50.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                    ],
                    const SizedBox(height: 16),
                    const NativeAdWidget(maxHeight: 110),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _originalPath != null && _croppedPath == null
              ? BottomActionBar(
                  gradient: _gradient,
                  primaryLabel: 'Crop to ID Size',
                  primaryIcon: Icons.crop_rounded,
                  enabled: !_isProcessing,
                  isLoading: _isProcessing,
                  onPrimary: _cropPhoto,
                )
              : null,
        ),
        if (_isProcessing)
          const ProcessingOverlay(message: 'Cropping Photo...'),
      ],
    );
  }
}

// ─── Info / Dimensions Card ────────────────────────────────────────────────

class _DimensionsCard extends StatelessWidget {
  const _DimensionsCard({
    required this.label,
    required this.dims,
    required this.icon,
  });

  final String label;
  final String dims;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textColor(isDark),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dims,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(isDark),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ID Card wrapper ───────────────────────────────────────────────────────

class _IdCard extends StatelessWidget {
  const _IdCard({required this.child});
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

// ─── Source Button ─────────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(isDark)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFEF4444), size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textColor(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Preview Section ────────────────────────────────────────────────

class _PhotoPreviewSection extends StatelessWidget {
  const _PhotoPreviewSection({
    required this.label,
    required this.imagePath,
    this.actions = const [],
    this.badge,
  });

  final String label;
  final String imagePath;
  final List<Widget> actions;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textColor(isDark),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white30,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: actions
                .expand((w) => [w, const SizedBox(width: 10)])
                .toList()
              ..removeLast(),
          ),
        ],
      ],
    );
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.black.withValues(alpha: 0.05))
              : null,
          borderRadius: BorderRadius.circular(12),
          border: gradient == null
              ? Border.all(color: AppTheme.borderColor(isDark))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: gradient == null
                  ? AppTheme.textColor(isDark)
                  : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: gradient == null
                    ? AppTheme.textColor(isDark)
                    : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
