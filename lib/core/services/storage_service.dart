import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document_model.dart';
import '../models/document_model.g.dart';
import '../constants/app_constants.dart';

/// Local storage service using Hive
class StorageService {
  static late Box<DocumentModel> _documentsBox;
  static late Box _settingsBox;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(dir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DocumentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DocumentTypeAdapter());
    }

    _documentsBox = await Hive.openBox<DocumentModel>('documents');
    _settingsBox = await Hive.openBox('settings');
  }

  // ---- Document Operations ----

  List<DocumentModel> getAllDocuments() {
    final docs = _documentsBox.values.toList();
    docs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return docs;
  }

  List<DocumentModel> getRecentDocuments({int limit = 10}) {
    return getAllDocuments().take(limit).toList();
  }

  List<DocumentModel> getDocumentsByType(DocumentType type) {
    return getAllDocuments().where((d) => d.type == type).toList();
  }

  List<DocumentModel> getFavorites() {
    return getAllDocuments().where((d) => d.isFavorite).toList();
  }

  List<DocumentModel> searchDocuments(String query) {
    final lower = query.toLowerCase();
    return getAllDocuments()
        .where((d) =>
            d.name.toLowerCase().contains(lower) ||
            d.tags.any((t) => t.toLowerCase().contains(lower)))
        .toList();
  }

  Future<void> saveDocument(DocumentModel doc) async {
    await _documentsBox.put(doc.id, doc);
  }

  Future<void> deleteDocument(String id) async {
    await _documentsBox.delete(id);
  }

  Future<void> toggleFavorite(String id) async {
    final doc = _documentsBox.get(id);
    if (doc != null) {
      await _documentsBox.put(
        id,
        doc.copyWith(isFavorite: !doc.isFavorite),
      );
    }
  }

  DocumentModel? getDocument(String id) {
    return _documentsBox.get(id);
  }

  // ---- Settings Operations ----

  bool get isOnboardingComplete =>
      _settingsBox.get(AppConstants.onboardingCompleteKey, defaultValue: false);

  Future<void> setOnboardingComplete() async {
    await _settingsBox.put(AppConstants.onboardingCompleteKey, true);
  }

  String get themeMode =>
      _settingsBox.get(AppConstants.themeKey, defaultValue: 'system');

  Future<void> setThemeMode(String mode) async {
    await _settingsBox.put(AppConstants.themeKey, mode);
  }

  bool get isPremium =>
      _settingsBox.get(AppConstants.premiumKey, defaultValue: false);

  Future<void> setPremium(bool value) async {
    await _settingsBox.put(AppConstants.premiumKey, value);
  }

  int get exportCount =>
      _settingsBox.get('export_count', defaultValue: 0);

  Future<void> incrementExportCount() async {
    await _settingsBox.put('export_count', exportCount + 1);
  }

  Future<void> resetDailyExportCount() async {
    await _settingsBox.put('export_count', 0);
    await _settingsBox.put('last_reset_date', DateTime.now().toIso8601String());
  }

  Future<void> checkAndResetDailyCount() async {
    final lastReset = _settingsBox.get('last_reset_date');
    if (lastReset != null) {
      final lastDate = DateTime.parse(lastReset);
      if (DateTime.now().difference(lastDate).inHours >= 24) {
        await resetDailyExportCount();
      }
    } else {
      await resetDailyExportCount();
    }
  }
}
