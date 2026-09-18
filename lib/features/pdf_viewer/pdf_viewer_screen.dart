import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/models/document_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_widgets.dart';
import '../_shared/tool_widgets.dart';

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
  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
      GlobalKey<SfPdfViewerState>();

  bool _isLoading = true;

  Future<void> _sharePdf() async {
    await Share.shareXFiles([XFile(widget.filePath)]);
  }

  void _showSearchHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use OCR tab to extract text'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
            onPressed: _showSearchHint,
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
            key: _pdfViewerKey,
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
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
