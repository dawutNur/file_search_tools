import 'package:get/get.dart';
import '../data/repositories/file_repository.dart';

class StatsViewModel extends GetxController {
  final FileRepository _repository = FileRepository();
  var stats = <dynamic>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      isLoading.value = true;
      stats.value = await _repository.getStats();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
