import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Reorder, rotate and remove pages of a PDF.
class OrganizePdfScreen extends ConsumerStatefulWidget {
  const OrganizePdfScreen({super.key});

  @override
  ConsumerState<OrganizePdfScreen> createState() => _OrganizePdfScreenState();
}

class _PageItem {
  _PageItem(this.originalIndex);
  final int originalIndex;
  int rotation = 0;
  bool removed = false;
  Uint8List? thumbnail;
}

class _OrganizePdfScreenState extends ConsumerState<OrganizePdfScreen> {
  String? _filePath;
  List<_PageItem> _pages = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _loadError;
  StreamSubscription<Uint8List>? _thumbSub;

  static final _gradient = AppTheme.toolGradients[12];

  bool get _hasChanges {
    for (var i = 0; i < _pages.length; i++) {
      final p = _pages[i];
      if (p.removed || p.rotation % 360 != 0 || p.originalIndex != i) {
        return true;
      }
    }
    return false;
  }

  int get _keptCount => _pages.where((p) => !p.removed).length;

  @override
  void dispose() {
    _thumbSub?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final path = await AppFilePicker.pickPdfFile(
      context,
      ref: ref,
      title: 'Select PDF to Organize',
    );
    if (path == null) return;

    await _thumbSub?.cancel();
    setState(() {
      _filePath = path;
      _pages = [];
      _loadError = null;
      _isLoading = true;
    });

    final svc = ref.read(pdfServiceProvider);
    final count = await svc.getPageCount(path);
    if (!mounted || _filePath != path) return;
    if (count == null || count == 0) {
      setState(() {
        _isLoading = false;
        _loadError =
            'Couldn\'t open this PDF. If it\'s password-protected, '
            'unlock it first with the Unlock PDF tool.';
      });
      return;
    }

    final pages = List.generate(count, _PageItem.new);
    setState(() {
      _pages = pages;
      _isLoading = false;
    });

    var index = 0;
    _thumbSub = svc.renderThumbnails(path, size: 240).listen(
      (png) {
        if (!mounted || index >= pages.length) return;
        setState(() => pages[index++].thumbnail = png);
      },
      onError: (_) {}, // Thumbnails are optional; placeholders remain.
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      _pages.insert(newIndex, _pages.removeAt(oldIndex));
    });
  }

  void _rotate(_PageItem page) {
    HapticFeedback.lightImpact();
    setState(() => page.rotation = (page.rotation + 90) % 360);
  }

  void _toggleRemoved(_PageItem page) {
    HapticFeedback.lightImpact();
    if (!page.removed && _keptCount == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A PDF needs at least one page')),
      );
      return;
    }
    setState(() => page.removed = !page.removed);
  }

  void _rotateAll() {
    HapticFeedback.lightImpact();
    setState(() {
      for (final p in _pages) {
        p.rotation = (p.rotation + 90) % 360;
      }
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _pages.sort((a, b) => a.originalIndex.compareTo(b.originalIndex));
      for (final p in _pages) {
        p.rotation = 0;
        p.removed = false;
      }
    });
  }

  Future<void> _save() async {
    if (_filePath == null || !_hasChanges) return;
    setState(() => _isProcessing = true);

    final kept = _pages.where((p) => !p.removed).toList();
    final base = _filePath!
        .split(RegExp(r'[\\/]'))
        .last
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final name = '${base}_organized';

    final result = await ref
        .read(pdfServiceProvider)
        .organizePages(
          inputPath: _filePath!,
          pageOrder: [for (final p in kept) p.originalIndex],
          rotations: {
            for (final p in kept)
              if (p.rotation != 0) p.originalIndex: p.rotation,
          },
          outputName: name,
        );

    if (!mounted) return;
    if (!result.isSuccess || result.outputPath == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Operation failed'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final doc = DocumentModel(
      id: const Uuid().v4(),
      name: name,
      filePath: result.outputPath!,
      type: DocumentType.organizedPdf,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      fileSizeBytes: result.fileSizeBytes ?? 0,
      pageCount: kept.length,
    );
    await ref.read(documentsProvider.notifier).addDocument(doc);
    try {
      await ref.read(adServiceProvider).showInterstitialAfterTask();
    } catch (_) {}
    if (!mounted) return;

    setState(() => _isProcessing = false);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (sheetCtx) => SuccessSheet(
        title: 'Pages Organized!',
        subtitle: '${doc.name} · ${kept.length} pages',
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
    final removedCount = _pages.length - _keptCount;
    final subtitle = _pages.isEmpty
        ? 'Reorder, rotate & remove pages'
        : '${_pages.length} pages'
              '${removedCount > 0 ? ' · $removedCount removed' : ''}';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              ToolSliverHeader(
                title: 'Organize Pages',
                subtitle: subtitle,
                icon: Icons.view_agenda_rounded,
                gradient: _gradient,
                actions: _pages.isEmpty
                    ? null
                    : [
                        IconButton(
                          icon: const Icon(Icons.rotate_right_rounded),
                          tooltip: 'Rotate all pages',
                          onPressed: _rotateAll,
                        ),
                        IconButton(
                          icon: const Icon(Icons.restart_alt_rounded),
                          tooltip: 'Reset changes',
                          onPressed: _hasChanges ? _reset : null,
                        ),
                      ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: FilePickerZone(
                    selectedPath: _filePath,
                    hint: 'Tap to select a PDF',
                    accept: 'Device or Google Drive',
                    gradient: _gradient,
                    onTap: _pickFile,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: NativeAdWidget(maxHeight: 110),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_loadError != null)
                SliverToBoxAdapter(
                  child: ErrorStateWidget(
                    message: _loadError!,
                    onRetry: _pickFile,
                  ),
                )
              else if (_pages.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text(
                      'Drag ☰ to reorder · tap ↻ to rotate · tap 🗑 to remove',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  sliver: SliverReorderableList(
                    itemCount: _pages.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, i) {
                      final page = _pages[i];
                      return _PageTile(
                        key: ValueKey(page.originalIndex),
                        index: i,
                        page: page,
                        gradient: _gradient,
                        onRotate: () => _rotate(page),
                        onToggleRemoved: () => _toggleRemoved(page),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            gradient: _gradient,
            primaryLabel: 'Save PDF',
            primaryIcon: Icons.save_rounded,
            enabled: _hasChanges && !_isProcessing,
            isLoading: _isProcessing,
            onPrimary: _save,
          ),
        ),
        if (_isProcessing)
          ProcessingOverlay(gradient: _gradient, message: 'Saving pages…'),
      ],
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.index,
    required this.page,
    required this.gradient,
    required this.onRotate,
    required this.onToggleRemoved,
  });

  final int index;
  final _PageItem page;
  final LinearGradient gradient;
  final VoidCallback onRotate;
  final VoidCallback onToggleRemoved;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = gradient.colors.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: page.removed ? 0.45 : 1,
        child: Material(
          color: AppTheme.cardColor(isDark),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: page.removed
                    ? AppTheme.error.withValues(alpha: 0.5)
                    : AppTheme.borderColor(isDark),
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppTheme.textSecondaryColor(isDark),
                    ),
                  ),
                ),
                _Thumbnail(page: page, isDark: isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${index + 1}',
                        style: TextStyle(
                          color: AppTheme.textColor(isDark),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          decoration: page.removed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (page.originalIndex != index)
                            'was ${page.originalIndex + 1}',
                          if (page.rotation != 0) '${page.rotation}°',
                          if (page.removed) 'removed',
                        ].join(' · '),
                        style: TextStyle(
                          color: page.removed
                              ? AppTheme.error
                              : AppTheme.textSecondaryColor(isDark),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.rotate_right_rounded, color: accent),
                  tooltip: 'Rotate page',
                  onPressed: page.removed ? null : onRotate,
                ),
                IconButton(
                  icon: Icon(
                    page.removed
                        ? Icons.restore_from_trash_rounded
                        : Icons.delete_outline_rounded,
                    color: page.removed ? accent : AppTheme.error,
                  ),
                  tooltip: page.removed ? 'Restore page' : 'Remove page',
                  onPressed: onToggleRemoved,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.page, required this.isDark});

  final _PageItem page;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final thumb = page.thumbnail;
    return AnimatedRotation(
      turns: page.rotation / 360,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 48,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderColor(isDark)),
        ),
        clipBehavior: Clip.antiAlias,
        child: thumb == null
            ? const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              )
            : Image.memory(thumb, fit: BoxFit.contain, gaplessPlayback: true),
      ),
    );
  }
}
