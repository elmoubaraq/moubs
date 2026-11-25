import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helper.dart';

export '../../core/widgets/glass_card.dart';

/// Gradient sliver app bar for all tool screens
class ToolSliverHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;
  final List<Widget>? actions;

  const ToolSliverHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.gradient,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        collapseMode: CollapseMode.parallax,
      ),
      backgroundColor: gradient.colors.first,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

/// Bottom action bar with gradient primary CTA
class BottomActionBar extends StatelessWidget {
  final LinearGradient gradient;
  final String primaryLabel;
  final IconData primaryIcon;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  const BottomActionBar({
    super.key,
    required this.gradient,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.enabled,
    required this.isLoading,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            ),
          ),
        ),
        child: ResponsiveCenter(
          maxWidth: Responsive.maxToolFormWidth,
          child: SizedBox(
            height: 52,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (secondaryLabel != null && onSecondary != null) ...[
                OutlinedButton.icon(
                  icon: Icon(secondaryIcon, size: 18),
                  label: Text(secondaryLabel!),
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: enabled ? gradient : null,
                    color: enabled
                        ? null
                        : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: gradient.colors.first.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: enabled && !isLoading
                          ? () {
                              HapticFeedback.mediumImpact();
                              onPrimary();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    primaryIcon,
                                    color: enabled
                                        ? Colors.white
                                        : AppTheme.textTertiary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    primaryLabel,
                                    style: TextStyle(
                                      color: enabled
                                          ? Colors.white
                                          : AppTheme.textTertiary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// File picker drop zone
class FilePickerZone extends StatelessWidget {
  final String? selectedPath;
  final String hint;
  final String accept;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final IconData? icon;

  const FilePickerZone({
    super.key,
    String? selectedPath,
    String? filePath,
    String hint = 'Tap to select a PDF',
    String? emptyLabel,
    String accept = 'PDF files only',
    String? emptySubLabel,
    required this.gradient,
    required this.onTap,
    this.icon,
  })  : selectedPath = selectedPath ?? filePath,
        hint = emptyLabel ?? hint,
        accept = emptySubLabel ?? accept;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = selectedPath != null;
    final name = hasFile
        ? selectedPath!.split('/').last.split('\\').last
        : null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: hasFile
              ? gradient.colors.first.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? AppTheme.cardDark2 : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasFile
                ? gradient.colors.first.withValues(alpha: 0.5)
                : AppTheme.borderLight,
            width: hasFile ? 1.5 : 1,
            style: hasFile ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: hasFile ? gradient : null,
                color: hasFile
                    ? null
                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_rounded
                    : (icon ?? Icons.upload_file_rounded),
                color: hasFile ? Colors.white : AppTheme.textTertiary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasFile ? (name ?? 'File selected') : hint,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: hasFile ? gradient.colors.first : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!hasFile) ...[
              const SizedBox(height: 4),
              Text(
                accept,
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Result card shown after successful operation
class ResultCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String path;
  final LinearGradient gradient;
  final String? viewRoute;
  final Map<String, dynamic>? viewExtra;
  final VoidCallback? onShare;

  const ResultCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.path,
    required this.gradient,
    this.viewRoute,
    this.viewExtra,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow(gradient.colors.first),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _btn(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap:
                          onShare ??
                          () async {
                            await Share.shareXFiles([XFile(path)]);
                          },
                      outline: true,
                    ),
                  ),
                  if (viewRoute != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _btn(
                        icon: Icons.visibility_rounded,
                        label: 'View',
                        onTap: () {
                          // Push to pdf viewer — caller must handle
                        },
                        outline: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool outline,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: outline ? Colors.white.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: outline
              ? Border.all(color: Colors.white.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: outline ? Colors.white : gradient.colors.first,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: outline ? Colors.white : gradient.colors.first,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Success bottom sheet
class SuccessSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String path;
  final LinearGradient gradient;
  final VoidCallback onDone;

  const SuccessSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.path,
    required this.gradient,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow(gradient.colors.first),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    onPressed: () async {
                      await Share.shareXFiles([XFile(path)]);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow(gradient.colors.first),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDone,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
