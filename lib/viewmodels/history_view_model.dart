import 'package:get/get.dart';
import '../data/repositories/file_repository.dart';

class HistoryViewModel extends GetxController {
  final FileRepository _repository = FileRepository();

  List<String> get history {
    return _repository.getSearchHistory();
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
