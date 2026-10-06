import 'package:get/get.dart';
import '../data/repositories/file_repository.dart';

class SubmitViewModel extends GetxController {
  final FileRepository _repository = FileRepository();

  var isSubmitting = false.obs;
  var urlController = ''.obs;

  Future<void> submitUrl(String url) async {
    if (url.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a URL');
      return;
    }

    // Basic URL validation
    final normalizedUrl = _normalizeUrl(url);
    if (!Uri.tryParse(normalizedUrl)!.hasAbsolutePath) {
      Get.snackbar('Error', 'Please enter a valid URL');
      return;
    }

    try {
      isSubmitting.value = true;
      await _repository.submitUrl(normalizedUrl);
      Get.snackbar('Success', 'URL submitted for indexing');
      urlController.value = '';
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isSubmitting.value = false;
    }
  }

  String _normalizeUrl(String url) {
    var normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    return normalizedUrl;
  }
}
