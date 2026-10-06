import 'package:get/get.dart';
import '../data/models/file_model.dart';
import '../core/storage/hive_service.dart';

class FavoritesViewModel extends GetxController {
  final HiveService _hiveService = Get.find<HiveService>();

  var favorites = <FileModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  void loadFavorites() {
    favorites.assignAll(_hiveService.getFavorites());
  }

  bool isFavorite(String url) {
    // Check against reactive favorites list for proper Obx updates
    return favorites.any((f) => f.url == url);
  }

  Future<void> toggleFavorite(FileModel file) async {
    if (isFavorite(file.url)) {
      await _hiveService.removeFavorite(file.url);
      Get.snackbar('Removed', 'Removed from favorites');
    } else {
      await _hiveService.addFavorite(file);
      Get.snackbar('Added', 'Added to favorites');
    }
    loadFavorites();
  }

  Future<void> removeFavorite(FileModel file) async {
    await _hiveService.removeFavorite(file.url);
    loadFavorites();
  }

  Future<void> clearAll() async {
    await _hiveService.clearFavorites();
    loadFavorites();
  }
}
