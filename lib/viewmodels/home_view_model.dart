import 'package:get/get.dart';
import '../data/models/file_model.dart';
import '../data/repositories/file_repository.dart';

class HomeViewModel extends GetxController {
  final FileRepository _repository = FileRepository();
  var latestFiles = <FileModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLatestFiles();
  }

  Future<void> fetchLatestFiles() async {
    try {
      isLoading.value = true;
      latestFiles.value = await _repository.getLatestFiles();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pingApi() async {
    try {
      await _repository.ping();
      Get.snackbar(
        'Success',
        'API is working!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
