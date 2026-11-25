import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/widgets/ad_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Large App Bar ────────────────────────────────────────────────
          SliverAppBar.large(title: const Text('Settings')),

          SliverToBoxAdapter(
            child: ResponsiveCenter(
              maxWidth: Responsive.maxToolFormWidth,
              child: Column(
                children: [
                // ── Profile Card ─────────────────────────────────────────
                _buildProfileCard(context, isDark),

                const SizedBox(height: 24),

                // ── Appearance ───────────────────────────────────────────
                _SectionLabel(label: 'Appearance'),
                _buildThemePicker(context, ref, themeMode, isDark),

                const SizedBox(height: 20),

                // ── Storage ──────────────────────────────────────────────
                _SectionLabel(label: 'Storage & Data'),
                _buildStorageCard(context, ref, isDark),

                const SizedBox(height: 20),

                // ── About ────────────────────────────────────────────────
                _SectionLabel(label: 'About'),
                _buildAboutSection(context, isDark),

                const SizedBox(height: 20),

                // ── Banner Ad ────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: BannerAdWidget()),
                ),

                // ── Footer ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Evergreen v2.0.0',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Made with 🌿 by MoubsCorps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, bool isDark) {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow(AppTheme.primary),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evergreen User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Free Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ── Theme Picker ──────────────────────────────────────────────────────────
  Widget _buildThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          _ThemeModeItem(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            subtitle: 'Always use light theme',
            selected: themeMode == ThemeMode.light,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.light);
            },
            color: AppTheme.warning,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          _ThemeModeItem(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            subtitle: 'Always use dark theme',
            selected: themeMode == ThemeMode.dark,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
            color: AppTheme.secondary,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          _ThemeModeItem(
            icon: Icons.brightness_auto_rounded,
            label: 'System',
            subtitle: 'Follow device setting',
            selected: themeMode == ThemeMode.system,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(ThemeMode.system);
            },
            color: AppTheme.primary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  // ── Storage Card ──────────────────────────────────────────────────────────
  Widget _buildStorageCard(BuildContext context, WidgetRef ref, bool isDark) {
    final docs = ref.watch(documentsProvider);
    final totalBytes = docs.fold<int>(0, (s, d) => s + d.fileSizeBytes);
    final maxBytes = 500 * 1024 * 1024; // 500MB display reference
    final ratio = (totalBytes / maxBytes).clamp(0.0, 1.0);

    String fmt(int b) {
      if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
      return '${(b / 1048576).toStringAsFixed(1)} MB';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storage_rounded,
                        color: AppTheme.info,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage Used',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${fmt(totalBytes)} • ${docs.length} documents',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Animated storage bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: isDark
                        ? AppTheme.borderDark
                        : AppTheme.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio > 0.8 ? AppTheme.warning : AppTheme.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(ratio * 100).toInt()}% of 500 MB used',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          _SettingsTile(
            icon: Icons.cleaning_services_rounded,
            label: 'Clear All Documents',
            subtitle: 'Remove all local files',
            color: AppTheme.error,
            onTap: () => _confirmClearAll(context, ref),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  // ── About Section ─────────────────────────────────────────────────────────
  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.star_rounded,
            label: 'Rate Evergreen',
            subtitle: 'Leave a review on Google Play',
            color: AppTheme.warning,
            onTap: () => _launchUrl(
              'https://play.google.com/store/apps/details?id=com.moubscorps.evergreen',
            ),
          ),
          _divider(isDark),
          _SettingsTile(
            icon: Icons.mail_rounded,
            label: 'Send Feedback',
            subtitle: 'support@moubscorps.com',
            color: AppTheme.primary,
            onTap: () => _launchUrl(
              'mailto:support@moubscorps.com?subject=Evergreen%20Feedback',
            ),
          ),
          _divider(isDark),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            label: 'Privacy Policy',
            subtitle: 'How we handle your data',
            color: AppTheme.info,
            onTap: () => _launchUrl('https://moubscorps.com/privacy'),
          ),
          _divider(isDark),
          _SettingsTile(
            icon: Icons.description_rounded,
            label: 'Terms of Service',
            subtitle: 'Usage terms & conditions',
            color: AppTheme.textSecondary,
            onTap: () => _launchUrl('https://moubscorps.com/terms'),
          ),
          _divider(isDark),
          _SettingsTile(
            icon: Icons.info_rounded,
            label: 'About',
            subtitle: 'App info & licenses',
            color: AppTheme.secondary,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Evergreen',
              applicationVersion: '2.0.0',
              applicationIcon: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              applicationLegalese: '© 2024 MoubsCorps. All rights reserved.',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
  );

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Documents?'),
        content: const Text(
          'This will permanently delete all your documents from the app. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final docs = ref.read(documentsProvider);
      for (final doc in docs) {
        ref.read(documentsProvider.notifier).deleteDocument(doc.id);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All documents cleared')));
    }
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

// ── Theme Mode Item ────────────────────────────────────────────────────────────
class _ThemeModeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _ThemeModeItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? color : AppTheme.textTertiary,
          size: 18,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? color : null,
          fontSize: 14,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 20,
                key: const ValueKey('selected'),
              )
            : const Icon(
                Icons.circle_outlined,
                size: 20,
                key: ValueKey('unselected'),
              ),
      ),
      onTap: onTap,
    );
  }
}
