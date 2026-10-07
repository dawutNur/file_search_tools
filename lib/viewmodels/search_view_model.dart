import 'package:get/get.dart';
import 'dart:async';
import '../data/models/file_model.dart';
import '../data/repositories/file_repository.dart';
import '../core/constants.dart';

class SearchViewModel extends GetxController {
  final FileRepository _repository = FileRepository();

  var results = <FileModel>[].obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasNext = false.obs;
  var currentQuery = ''.obs;

  var sortBy = 'time'.obs;  // API default is 'time'
  var order = 'desc'.obs;   // API default is 'desc'
  var category = Rxn<String>();

  final List<String> availableCategories = AppConstants.availableCategories;

  Timer? _debounce;

  void onSearchChanged(String query) {
    currentQuery.value = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        performSearch();
      } else {
        results.clear();
      }
    });
  }

  Future<void> performSearch() async {
    try {
      isLoading.value = true;
      currentPage.value = 1;

      final response = await _repository.searchFiles(
        query: currentQuery.value,
        page: currentPage.value,
        sortBy: sortBy.value,
        order: order.value,
        category: category.value,
      );

      results.assignAll(
        (response.files).map((json) => FileModel.fromJson(json)).toList(),
      );
      totalPages.value = response.pages;
      currentPage.value = response.currentPage;
      hasNext.value = response.hasNext;
    } catch (e) {
      Get.snackbar('Search Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadNextPage() async {
    if (hasNext.value) {
      await loadPage(currentPage.value + 1, append: true);
    }
  }

  Future<void> loadPage(int page, {bool append = false}) async {
    try {
      isLoading.value = true;
      final response = await _repository.searchFiles(
        query: currentQuery.value,
        page: page,
        sortBy: sortBy.value,
        order: order.value,
        category: category.value,
      );

      final newFiles = (response.files).map((json) => FileModel.fromJson(json)).toList();
      if (append) {
        results.addAll(newFiles);
      } else {
        results.assignAll(newFiles);
      }
      totalPages.value = response.pages;
      currentPage.value = response.currentPage;
      hasNext.value = response.hasNext;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void updateSort(String newSort) {
    sortBy.value = newSort;
    performSearch();
  }

  void updateOrder(String newOrder) {
    order.value = newOrder;
    performSearch();
  }

  void updateCategory(String? newCat) {
    category.value = newCat;
    performSearch();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
