import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/print_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ad_widgets.dart';
import '../../core/widgets/state_widgets.dart';

// ── Sort & Filter Providers ──────────────────────────────────────────────────

enum SortBy { date, name, size }

enum ViewMode { list, grid }

class FileManagerSortNotifier extends Notifier<SortBy> {
  @override
  SortBy build() => SortBy.date;
  @override
  set state(SortBy value) => super.state = value;
  void set(SortBy value) => super.state = value;
}

class FileManagerFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  @override
  set state(String? value) => super.state = value;
  void set(String? value) => super.state = value;
}

class FileManagerViewNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() => ViewMode.list;
  @override
  set state(ViewMode value) => super.state = value;
  void set(ViewMode value) => super.state = value;
}

class FileManagerSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  @override
  set state(Set<String> value) => super.state = value;
  void set(Set<String> value) => super.state = value;
}

class FileManagerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String value) => super.state = value;
  void set(String value) => super.state = value;
}

final fileManagerSortProvider =
    NotifierProvider<FileManagerSortNotifier, SortBy>(
      FileManagerSortNotifier.new,
    );
final fileManagerFilterProvider =
    NotifierProvider<FileManagerFilterNotifier, String?>(
      FileManagerFilterNotifier.new,
    );
final fileManagerViewProvider =
    NotifierProvider<FileManagerViewNotifier, ViewMode>(
      FileManagerViewNotifier.new,
    );
final fileManagerSelectionProvider =
    NotifierProvider<FileManagerSelectionNotifier, Set<String>>(
      FileManagerSelectionNotifier.new,
    );
final fileManagerSearchProvider =
    NotifierProvider<FileManagerSearchNotifier, String>(
      FileManagerSearchNotifier.new,
    );

final sortedFilteredDocsProvider = Provider<List<DocumentModel>>((ref) {
  final docs = ref.watch(documentsProvider);
  final sort = ref.watch(fileManagerSortProvider);
  final filter = ref.watch(fileManagerFilterProvider);
  final query = ref.watch(fileManagerSearchProvider);

  var list = [...docs];

  // Apply query
  if (query.isNotEmpty) {
    list = list
        .where((d) => d.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Apply filter
  if (filter == 'favorites') {
    list = list.where((d) => d.isFavorite).toList();
  } else if (filter != null) {
    // filter by DocumentType label
    list = list.where((d) => d.type.label == filter).toList();
  }

  // Sort
  switch (sort) {
    case SortBy.date:
      list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    case SortBy.name:
      list.sort((a, b) => a.name.compareTo(b.name));
    case SortBy.size:
      list.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
  }

  return list;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _viewToggleAnim;

  @override
  void initState() {
    super.initState();
    _viewToggleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewToggleAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(sortedFilteredDocsProvider);
    final viewMode = ref.watch(fileManagerViewProvider);
    final selection = ref.watch(fileManagerSelectionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelecting = selection.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Large App Bar ────────────────────────────────────────────────
          SliverAppBar.large(
            title: isSelecting
                ? Text('${selection.length} selected')
                : const Text('My Files'),
            actions: [
              if (isSelecting) ...[
                IconButton(
                  icon: const Icon(Icons.delete_rounded),
                  onPressed: () => _deleteSelected(context),
                  tooltip: 'Delete selected',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () =>
                      ref.read(fileManagerSelectionProvider.notifier).state =
                          {},
                ),
              ] else ...[
                // Search toggle
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref.read(fileManagerSearchProvider.notifier).state = '';
                      }
                    });
                  },
                ),
                // Grid/List toggle
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      viewMode == ViewMode.list
                          ? Icons.grid_view_rounded
                          : Icons.view_list_rounded,
                      key: ValueKey(viewMode),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(fileManagerViewProvider.notifier)
                        .state = viewMode == ViewMode.list
                        ? ViewMode.grid
                        : ViewMode.list;
                    viewMode == ViewMode.list
                        ? _viewToggleAnim.forward()
                        : _viewToggleAnim.reverse();
                  },
                ),
                // Sort
                _SortButton(),
                const SizedBox(width: 4),
              ],
            ],
          ),

          // ── Search Bar ───────────────────────────────────────────────────
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                      .read(fileManagerSearchProvider.notifier)
                                      .state =
                                  '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      ref.read(fileManagerSearchProvider.notifier).state = v,
                ),
              ),
            ),

          // ── Filter Chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildFilters(context)),

          // ── Stats Banner ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildStatsBanner(context, docs, isDark)),

          // ── Content ──────────────────────────────────────────────────────
          if (docs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: const EmptyStateWidget(
                icon: Icons.folder_open_rounded,
                title: 'No Files Yet',
                subtitle: 'Documents you create will appear here',
              ),
            )
          else if (viewMode == ViewMode.grid)
            _GridView(
              docs: docs,
              isDark: isDark,
              selection: selection,
              ref: ref,
            )
          else
            _ListView(
              docs: docs,
              isDark: isDark,
              selection: selection,
              ref: ref,
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final allDocs = ref.watch(documentsProvider);
    final filter = ref.watch(fileManagerFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get unique type labels from actual docs
    final typeLabels = allDocs.map((d) => d.type.label).toSet().toList();

    final chips = [
      _FilterChipData(null, 'All', Icons.apps_rounded),
      _FilterChipData('favorites', '⭐ Starred', Icons.star_rounded),
      ...typeLabels.map(
        (l) => _FilterChipData(l, l, Icons.description_rounded),
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: chips.length,
        itemBuilder: (context, i) {
          final chip = chips[i];
          final selected = filter == chip.value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              label: Text(chip.label),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                ref.read(fileManagerFilterProvider.notifier).state = selected
                    ? null
                    : chip.value;
              },
              backgroundColor: isDark
                  ? AppTheme.cardDark2
                  : const Color(0xFFF3F4F6),
              selectedColor: AppTheme.primary.withValues(alpha: 0.15),
              side: selected
                  ? const BorderSide(color: AppTheme.primary, width: 1.5)
                  : BorderSide(
                      color: isDark
                          ? AppTheme.borderDark
                          : AppTheme.borderLight,
                    ),
              labelStyle: TextStyle(
                color: selected
                    ? AppTheme.primary
                    : (isDark ? Colors.white70 : AppTheme.textSecondary),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBanner(
    BuildContext context,
    List<DocumentModel> docs,
    bool isDark,
  ) {
    if (docs.isEmpty) return const SizedBox.shrink();
    final totalBytes = docs.fold<int>(0, (s, d) => s + d.fileSizeBytes);
    String fmt(int b) {
      if (b < 1048576) return '${(b / 1024).toStringAsFixed(0)} KB';
      return '${(b / 1048576).toStringAsFixed(1)} MB';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.description_rounded, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            '${docs.length} document${docs.length != 1 ? 's' : ''}  •  ${fmt(totalBytes)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const Spacer(),
          Text(
            'Long-press to select',
            style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final selection = ref.read(fileManagerSelectionProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete ${selection.length} item${selection.length != 1 ? 's' : ''}?',
        ),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      for (final id in selection) {
        ref.read(documentsProvider.notifier).deleteDocument(id);
      }
      ref.read(fileManagerSelectionProvider.notifier).state = {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selection.length} item${selection.length != 1 ? 's' : ''} deleted',
          ),
        ),
      );
    }
  }
}

// ── Sort Button ───────────────────────────────────────────────────────────────
class _SortButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(fileManagerSortProvider);
    return PopupMenuButton<SortBy>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort',
      onSelected: (v) {
        HapticFeedback.selectionClick();
        ref.read(fileManagerSortProvider.notifier).state = v;
      },
      itemBuilder: (_) => [
        _sortItem(SortBy.date, 'By Date', Icons.calendar_today_rounded, sort),
        _sortItem(SortBy.name, 'By Name', Icons.sort_by_alpha_rounded, sort),
        _sortItem(SortBy.size, 'By Size', Icons.data_usage_rounded, sort),
      ],
    );
  }

  PopupMenuItem<SortBy> _sortItem(
    SortBy v,
    String label,
    IconData icon,
    SortBy current,
  ) {
    final selected = v == current;
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(icon, size: 18, color: selected ? AppTheme.primary : null),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (selected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 16, color: AppTheme.primary),
          ],
        ],
      ),
    );
  }
}

// ── List View ─────────────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final List<DocumentModel> docs;
  final bool isDark;
  final Set<String> selection;
  final WidgetRef ref;

  const _ListView({
    required this.docs,
    required this.isDark,
    required this.selection,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final doc = docs[index];
        final selected = selection.contains(doc.id);

        Widget tile = _DocListTile(
          doc: doc,
          isDark: isDark,
          selected: selected,
          isSelecting: selection.isNotEmpty,
          onTap: () {
            if (selection.isNotEmpty) {
              _toggleSelect(doc.id);
            } else if (doc.filePath.endsWith('.pdf')) {
              context.push(
                '/pdf-viewer',
                extra: {'filePath': doc.filePath, 'title': doc.name},
              );
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _toggleSelect(doc.id);
          },
          onMoreTap: () => _showOptions(context, doc),
          onToggleFavorite: () =>
              ref.read(documentsProvider.notifier).toggleFavorite(doc.id),
        );

        if (index < 10) {
          tile = tile
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 40),
                duration: 300.ms,
              )
              .slideX(
                begin: -0.05,
                end: 0,
                delay: Duration(milliseconds: index * 40),
                duration: 300.ms,
              );
        }

        // Ad every 8 items
        if (index > 0 && index % 8 == 0) {
          return Column(
            children: [
              tile,
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Center(child: BannerAdWidget()),
              ),
            ],
          );
        }
        return tile;
      }, childCount: docs.length),
    );
  }

  void _toggleSelect(String id) {
    final current = Set<String>.from(ref.read(fileManagerSelectionProvider));
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    ref.read(fileManagerSelectionProvider.notifier).state = current;
  }

  void _showOptions(BuildContext context, DocumentModel doc) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (_) => _DocOptionsSheet(doc: doc, ref: ref),
    );
  }
}

// ── Grid View ─────────────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  final List<DocumentModel> docs;
  final bool isDark;
  final Set<String> selection;
  final WidgetRef ref;

  const _GridView({
    required this.docs,
    required this.isDark,
    required this.selection,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final doc = docs[index];
          final selected = selection.contains(doc.id);
          return _DocGridCard(
                doc: doc,
                isDark: isDark,
                selected: selected,
                onTap: () {
                  if (selection.isNotEmpty) {
                    _toggleSelect(doc.id);
                  } else if (doc.filePath.endsWith('.pdf')) {
                    context.push(
                      '/pdf-viewer',
                      extra: {'filePath': doc.filePath, 'title': doc.name},
                    );
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _toggleSelect(doc.id);
                },
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: index * 40),
                duration: 300.ms,
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1, 1),
                delay: Duration(milliseconds: index * 40),
                duration: 300.ms,
              );
        }, childCount: docs.length),
      ),
    );
  }

  void _toggleSelect(String id) {
    final current = Set<String>.from(ref.read(fileManagerSelectionProvider));
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    ref.read(fileManagerSelectionProvider.notifier).state = current;
  }
}

// ── Doc List Tile ─────────────────────────────────────────────────────────────
class _DocListTile extends StatelessWidget {
  final DocumentModel doc;
  final bool isDark;
  final bool selected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMoreTap;
  final VoidCallback onToggleFavorite;

  const _DocListTile({
    required this.doc,
    required this.isDark,
    required this.selected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.onMoreTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final borderCol = selected
        ? AppTheme.primary.withValues(alpha: 0.5)
        : (isDark ? AppTheme.borderDark : AppTheme.borderLight);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.06)
            : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: selected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Selection checkbox or icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelecting
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          key: const ValueKey('check'),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textTertiary,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        )
                      : Container(
                          key: const ValueKey('icon'),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              doc.type.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              doc.type.label,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            doc.fileSizeFormatted,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isSelecting) ...[
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggleFavorite();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        doc.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: doc.isFavorite
                            ? AppTheme.warning
                            : AppTheme.textTertiary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: onMoreTap,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.more_vert_rounded, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Doc Grid Card ─────────────────────────────────────────────────────────────
class _DocGridCard extends StatelessWidget {
  final DocumentModel doc;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DocGridCard({
    required this.doc,
    required this.isDark,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.08)
          : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        doc.type.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  doc.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                doc.fileSizeFormatted,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Doc Options Sheet ─────────────────────────────────────────────────────────
class _DocOptionsSheet extends StatelessWidget {
  final DocumentModel doc;
  final WidgetRef ref;

  const _DocOptionsSheet({required this.doc, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      doc.type.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          _option(context, Icons.open_in_new_rounded, 'Open With', () {
            Navigator.pop(context);
            OpenFile.open(doc.filePath);
          }),
          _option(context, Icons.share_rounded, 'Share', () async {
            Navigator.pop(context);
            await SharePlus.instance.share(
              ShareParams(files: [XFile(doc.filePath)], subject: doc.name),
            );
          }),
          _option(
            context,
            Icons.drive_file_rename_outline_rounded,
            'Rename',
            () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              _showRenameDialog(context, messenger);
            },
          ),
          if (doc.filePath.toLowerCase().endsWith('.pdf'))
            _option(context, Icons.print_rounded, 'Print', () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final error = await PrintService.printFile(
                doc.filePath,
                doc.name,
              );
              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text(error)));
              }
            }),
          _option(
            context,
            Icons.star_border_rounded,
            doc.isFavorite ? 'Remove from Starred' : 'Add to Starred',
            () {
              ref.read(documentsProvider.notifier).toggleFavorite(doc.id);
              Navigator.pop(context);
            },
          ),
          _option(context, Icons.delete_rounded, 'Delete', () async {
            Navigator.pop(context);
            ref.read(documentsProvider.notifier).deleteDocument(doc.id);
          }, isDestructive: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    ScaffoldMessengerState messenger,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _RenameDialog(
        initialName: doc.name,
        onRename: (name) async {
          await ref
              .read(documentsProvider.notifier)
              .renameDocument(doc.id, name);
          messenger.showSnackBar(SnackBar(content: Text('Renamed to "$name"')));
        },
      ),
    );
  }

  Widget _option(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.error : null,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.error : null,
          fontSize: 15,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

// ── Rename Dialog ─────────────────────────────────────────────────────────────
class _RenameDialog extends StatefulWidget {
  final String initialName;
  final Future<void> Function(String name) onRename;

  const _RenameDialog({required this.initialName, required this.onRename});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final name = widget.initialName;
    _ctrl = TextEditingController(text: name);
    // Pre-select the name without its extension.
    final dot = name.toLowerCase().endsWith('.pdf')
        ? name.length - 4
        : name.length;
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: dot);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _valid {
    final t = _ctrl.text.trim();
    return t.isNotEmpty && t != widget.initialName;
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final name = _ctrl.text.trim();
    Navigator.pop(context);
    await widget.onRename(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Document name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _valid ? _submit : null,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

// ── Internal Data Types ───────────────────────────────────────────────────────
class _FilterChipData {
  final String? value;
  final String label;
  final IconData icon;
  const _FilterChipData(this.value, this.label, this.icon);
}
