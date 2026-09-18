import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/services/print_service.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  final String filePath;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _controller = PdfViewerController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  bool _isLoading = true;
  bool _isSearching = false;
  PdfTextSearchResult? _searchResult;

  @override
  void dispose() {
    _searchResult?.removeListener(_onSearchUpdate);
    _searchResult?.clear();
    _controller.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _sharePdf() async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(widget.filePath)], subject: widget.title),
    );
  }

  Future<void> _printPdf() async {
    final error = await PrintService.printFile(widget.filePath, widget.title);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _toggleSearch() {
    setState(() => _isSearching = !_isSearching);
    if (_isSearching) {
      _searchFocus.requestFocus();
    } else {
      _clearSearch();
    }
  }

  void _clearSearch() {
    _searchResult?.removeListener(_onSearchUpdate);
    _searchResult?.clear();
    _searchCtrl.clear();
    setState(() => _searchResult = null);
  }

  void _runSearch(String query) {
    _searchResult?.removeListener(_onSearchUpdate);
    _searchResult?.clear();
    if (query.trim().isEmpty) {
      setState(() => _searchResult = null);
      return;
    }
    final result = _controller.searchText(query.trim());
    result.addListener(_onSearchUpdate);
    setState(() => _searchResult = result);
  }

  void _onSearchUpdate() {
    if (!mounted) return;
    setState(() {});
    final result = _searchResult;
    if (result != null &&
        result.isSearchCompleted &&
        result.totalInstanceCount == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No matches for "${_searchCtrl.text}"')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _searchResult;
    final hasMatches = result != null && result.hasResult;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                decoration: const InputDecoration(
                  hintText: 'Search in document…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              )
            : Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: false,
        actions: _isSearching
            ? [
                if (hasMatches)
                  Center(
                    child: Text(
                      '${result.currentInstanceIndex}/${result.totalInstanceCount}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  tooltip: 'Previous match',
                  onPressed: hasMatches ? result.previousInstance : null,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  tooltip: 'Next match',
                  onPressed: hasMatches ? result.nextInstance : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close search',
                  onPressed: _toggleSearch,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search',
                  onPressed: _isLoading ? null : _toggleSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.print_rounded),
                  tooltip: 'Print',
                  onPressed: _printPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share',
                  onPressed: _sharePdf,
                ),
              ],
        elevation: 0,
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.filePath),
            controller: _controller,
            enableDoubleTapZooming: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (_) => setState(() => _isLoading = false),
            onDocumentLoadFailed: (details) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
