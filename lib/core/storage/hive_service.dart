import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../data/models/file_model.dart';
import '../constants.dart';

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FileModelAdapter());
    await Hive.openBox<String>(AppConstants.historyBoxName);
    await Hive.openBox<FileModel>(AppConstants.favoritesBoxName);
  }

  Future<void> saveSearchQuery(String query) async {
    final box = Hive.box<String>(AppConstants.historyBoxName);

    // Remove duplicate if exists (to move it to end)
    final existingKey = box.keys.cast<int>().where(
      (key) => box.get(key) == query,
    ).firstOrNull;
    if (existingKey != null) {
      await box.delete(existingKey);
    }

    await box.add(query);

    // Limit history
    if (box.length > AppConstants.maxHistoryItems) {
      await box.deleteAt(0);
    }
  }

  List<String> getSearchHistory() {
    final box = Hive.box<String>(AppConstants.historyBoxName);
    return box.values.toList().reversed.toList();
  }

  Future<void> clearHistory() async {
    final box = Hive.box<String>(AppConstants.historyBoxName);
    await box.clear();
  }

  // --- Favorites ---
  Future<void> addFavorite(FileModel file) async {
    final box = Hive.box<FileModel>(AppConstants.favoritesBoxName);
    // Use URL as key to prevent duplicates
    await box.put(file.url, file);
  }

  Future<void> removeFavorite(String url) async {
    final box = Hive.box<FileModel>(AppConstants.favoritesBoxName);
    await box.delete(url);
  }

  bool isFavorite(String url) {
    final box = Hive.box<FileModel>(AppConstants.favoritesBoxName);
    return box.containsKey(url);
  }

  List<FileModel> getFavorites() {
    final box = Hive.box<FileModel>(AppConstants.favoritesBoxName);
    return box.values.toList().reversed.toList();
  }

  Future<void> clearFavorites() async {
    final box = Hive.box<FileModel>(AppConstants.favoritesBoxName);
    await box.clear();
  }
}
