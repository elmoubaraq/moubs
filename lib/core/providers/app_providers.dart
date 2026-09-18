import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/pdf_service.dart';
import '../services/ocr_service.dart';
import '../services/image_service.dart';
import '../services/analytics_service.dart';
import '../models/document_model.dart';

// ---- Service Providers ----

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// ---- State Providers ----

final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<DocumentModel>>(
        DocumentsNotifier.new);

class DocumentsNotifier extends Notifier<List<DocumentModel>> {
  @override
  List<DocumentModel> build() {
    final storage = ref.read(storageServiceProvider);
    return storage.getAllDocuments();
  }

  void loadDocuments() {
    final storage = ref.read(storageServiceProvider);
    state = storage.getAllDocuments();
  }

  Future<void> addDocument(DocumentModel doc) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveDocument(doc);
    loadDocuments();
  }

  Future<void> deleteDocument(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteDocument(id);
    loadDocuments();
  }

  Future<void> toggleFavorite(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.toggleFavorite(id);
    loadDocuments();
  }

  List<DocumentModel> search(String query) {
    final storage = ref.read(storageServiceProvider);
    return storage.searchDocuments(query);
  }
}

// ---- Theme Provider ----

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final storage = ref.read(storageServiceProvider);
    switch (storage.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final storage = ref.read(storageServiceProvider);
    state = mode;
    switch (mode) {
      case ThemeMode.light:
        await storage.setThemeMode('light');
        break;
      case ThemeMode.dark:
        await storage.setThemeMode('dark');
        break;
      case ThemeMode.system:
        await storage.setThemeMode('system');
        break;
    }
  }
}

// ---- Premium Provider ----

final isPremiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.read(storageServiceProvider);
    return storage.isPremium;
  }

  Future<void> setPremium(bool value) async {
    final storage = ref.read(storageServiceProvider);
    state = value;
    await storage.setPremium(value);
  }
}

// ---- Search Provider ----

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final filteredDocumentsProvider = Provider<List<DocumentModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final docs = ref.watch(documentsProvider);
  if (query.isEmpty) return docs;
  return docs
      .where((d) =>
          d.name.toLowerCase().contains(query.toLowerCase()) ||
          d.tags.any((t) => t.toLowerCase().contains(query.toLowerCase())))
      .toList();
});

// ---- Tab Provider ----

class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}

final selectedTabProvider =
    NotifierProvider<SelectedTabNotifier, int>(SelectedTabNotifier.new);

// ---- Processing State ----

final processingProvider =
    NotifierProvider<ProcessingNotifier, ProcessingInfo>(
        ProcessingNotifier.new);

class ProcessingInfo {
  final bool isProcessing;
  final String? message;
  final double? progress;

  const ProcessingInfo({
    this.isProcessing = false,
    this.message,
    this.progress,
  });

  ProcessingInfo copyWith({
    bool? isProcessing,
    String? message,
    double? progress,
  }) {
    return ProcessingInfo(
      isProcessing: isProcessing ?? this.isProcessing,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

class ProcessingNotifier extends Notifier<ProcessingInfo> {
  @override
  ProcessingInfo build() => const ProcessingInfo();

  void startProcessing(String message) {
    state = ProcessingInfo(isProcessing: true, message: message);
  }

  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void stopProcessing() {
    state = const ProcessingInfo();
  }
}
