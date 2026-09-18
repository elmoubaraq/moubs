import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/state_widgets.dart';
import '../../core/models/document_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _fabPulse;

  @override
  void initState() {
    super.initState();
    _fabPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(filteredDocumentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          _buildAppBar(context, isDark),

          // ── Hero / Header ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHero(context, isDark, size)),

          // ── Stats Row ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStats(context, documents, isDark)),

          // ── Core Tools ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader(context, 'Core Tools', null)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildListDelegate(_buildCoreTools(context, isDark)),
            ),
          ),

          // ── Advanced Tools ───────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSectionHeader(context, 'Advanced Tools', null)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildListDelegate(_buildAdvancedTools(context, isDark)),
            ),
          ),

          // ── Ad Banner ────────────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(child: BannerAdWidget()),
            ),
          ),

          // ── Recent Documents ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context,
              'Recent Documents',
              documents.isNotEmpty ? () => context.go('/files') : null,
            ),
          ),

          if (documents.isEmpty)
            SliverToBoxAdapter(
              child: EmptyStateWidget(
                icon: Icons.description_outlined,
                title: 'No Documents Yet',
                subtitle: 'Scan a document or convert an image to PDF to get started',
                actionLabel: 'Quick Scan',
                onAction: () => context.push('/scanner'),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= documents.length || index >= 6) return null;
                  return _DocumentTile(
                    doc: documents[index],
                    isDark: isDark,
                    onDelete: () {
                      ref.read(documentsProvider.notifier).deleteDocument(documents[index].id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('${documents[index].name} deleted'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onToggleFavorite: () =>
                        ref.read(documentsProvider.notifier).toggleFavorite(documents[index].id),
                    onTap: () {
                      final doc = documents[index];
                      if (doc.filePath.endsWith('.pdf')) {
                        context.push('/pdf-viewer', extra: {'filePath': doc.filePath, 'title': doc.name});
                      }
                    },
                  );
                },
                childCount: documents.length.clamp(0, 6),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      expandedHeight: _isSearching ? 120 : 64,
      titleSpacing: 16,
      title: _isSearching
          ? null
          : Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Evergreen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'v2',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).set('');
              }
            });
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).set('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => ref.read(searchQueryProvider.notifier).set(v),
                ),
              ),
            )
          : null,
    );
  }

  // ── Hero Section ─────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, bool isDark, Size size) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 180,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow(AppTheme.primary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background orbs
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Your Document\nSuper App 🌿',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan · Merge · Compress · Sign',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/scanner');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.document_scanner_rounded, size: 16, color: AppTheme.primaryDark),
                              SizedBox(width: 6),
                              Text(
                                'Quick Scan',
                                style: TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Decorative icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: const Icon(Icons.eco_rounded, size: 38, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  // ── Stats Row ─────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context, List<DocumentModel> docs, bool isDark) {
    final total = docs.length;
    final bytes = docs.fold<int>(0, (s, d) => s + d.fileSizeBytes);
    final favorites = docs.where((d) => d.isFavorite).length;

    String fmt(int b) {
      if (b < 1024) return '$b B';
      if (b < 1048576) return '${(b / 1024).toStringAsFixed(0)} KB';
      return '${(b / 1048576).toStringAsFixed(1)} MB';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatPill(label: '$total', sub: 'Docs', icon: Icons.description_rounded, color: AppTheme.primary),
          const SizedBox(width: 10),
          _StatPill(label: fmt(bytes), sub: 'Size', icon: Icons.storage_rounded, color: AppTheme.info),
          const SizedBox(width: 10),
          _StatPill(label: '$favorites', sub: 'Starred', icon: Icons.star_rounded, color: AppTheme.warning),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Tool Cards ────────────────────────────────────────────────────────────
  List<Widget> _buildCoreTools(BuildContext context, bool isDark) {
    const tools = [
      _Tool('Scan', Icons.document_scanner_rounded, '/scanner', 0),
      _Tool('Image\nto PDF', Icons.image_rounded, '/image-to-pdf', 1),
      _Tool('Merge\nPDF', Icons.merge_rounded, '/merge-pdf', 2),
      _Tool('Compress', Icons.compress_rounded, '/compress-pdf', 3),
      _Tool('Split\nPDF', Icons.content_cut_rounded, '/split-pdf', 4),
      _Tool('Sign\nDoc', Icons.draw_rounded, '/sign-document', 5),
      _Tool('OCR\nText', Icons.text_fields_rounded, '/ocr', 6),
      _Tool('Text\nto PDF', Icons.notes_rounded, '/text-to-pdf', 7),
    ];
    return tools.map((t) => _buildToolCard(context, t, isDark)).toList();
  }

  List<Widget> _buildAdvancedTools(BuildContext context, bool isDark) {
    const tools = [
      _Tool('Watermark', Icons.water_drop_rounded, '/watermark-pdf', 8),
      _Tool('Encrypt\nPDF', Icons.lock_rounded, '/encrypt-pdf', 9),
      _Tool('PDF to\nImage', Icons.photo_library_rounded, '/pdf-to-image', 10),
      _Tool('ID\nPhoto', Icons.badge_rounded, '/id-photo', 11),
    ];
    return tools.map((t) => _buildToolCard(context, t, isDark)).toList();
  }

  Widget _buildToolCard(BuildContext context, _Tool tool, bool isDark) {
    final gradient = AppTheme.toolGradients[tool.gradientIndex];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(tool.route);
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (gradient.colors.first).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(tool.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                tool.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withValues(alpha: 0.85) : AppTheme.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 + tool.gradientIndex * 35), duration: 400.ms)
        .scale(
          delay: Duration(milliseconds: 80 + tool.gradientIndex * 35),
          begin: const Offset(0.75, 0.75),
          end: const Offset(1, 1),
          duration: 450.ms,
          curve: Curves.easeOutBack,
        );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFab(BuildContext context) {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3 + 0.15 * _fabPulse.value),
                blurRadius: 20 + 8 * _fabPulse.value,
                spreadRadius: 2 * _fabPulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickActions(context);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
    ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut);
  }

  // ── Quick Actions Sheet ───────────────────────────────────────────────────
  void _showQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _QuickActionsSheet(isDark: isDark),
    );
  }
}

// ── Stats Pill ───────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;

  const _StatPill({required this.label, required this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.15), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                Text(sub, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document Tile ─────────────────────────────────────────────────────────────
class _DocumentTile extends StatelessWidget {
  final DocumentModel doc;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTap;

  const _DocumentTile({
    required this.doc,
    required this.isDark,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Document?'),
            content: Text('Are you sure you want to delete "${doc.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight, width: 1),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(doc.type.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                doc.type.label,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(doc.fileSizeFormatted,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                            if (doc.pageCount > 1) ...[
                              const SizedBox(width: 6),
                              Text('${doc.pageCount} pg',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Favorite
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggleFavorite();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: doc.isFavorite ? AppTheme.warning : AppTheme.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Actions Sheet ───────────────────────────────────────────────────────
class _QuickActionsSheet extends StatelessWidget {
  final bool isDark;
  const _QuickActionsSheet({required this.isDark});

  static const _actions = [
    _QAction('Scan Document', 'Camera scan & auto-enhance', Icons.document_scanner_rounded, '/scanner', 0),
    _QAction('Image to PDF', 'Convert photos to PDF', Icons.image_rounded, '/image-to-pdf', 1),
    _QAction('Merge PDFs', 'Combine multiple PDFs', Icons.merge_rounded, '/merge-pdf', 2),
    _QAction('Extract Text (OCR)', 'Get text from images', Icons.text_fields_rounded, '/ocr', 6),
    _QAction('Text to PDF', 'Type & export as PDF', Icons.notes_rounded, '/text-to-pdf', 7),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 4),
                Text('Create New', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            ..._actions.asMap().entries.map((e) {
              final action = e.value;
              final gradient = AppTheme.toolGradients[action.gradientIndex];
              return ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
                  child: Icon(action.icon, color: Colors.white, size: 20),
                ),
                title: Text(action.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(action.sub, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  context.push(action.route);
                },
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 50), duration: 300.ms)
                  .slideX(begin: -0.1, end: 0, delay: Duration(milliseconds: e.key * 50), duration: 300.ms);
            }),
          ],
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────
class _Tool {
  final String label;
  final IconData icon;
  final String route;
  final int gradientIndex;
  const _Tool(this.label, this.icon, this.route, this.gradientIndex);
}

class _QAction {
  final String label;
  final String sub;
  final IconData icon;
  final String route;
  final int gradientIndex;
  const _QAction(this.label, this.sub, this.icon, this.route, this.gradientIndex);
}
