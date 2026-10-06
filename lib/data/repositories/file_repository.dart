import 'package:file_search_tools/core/api/api_service.dart';
import 'package:file_search_tools/core/storage/hive_service.dart';
import '../models/file_model.dart';
import '../models/search_response_model.dart';

class FileRepository {
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();

  // --- Search Logic ---
  Future<SearchResponseModel> searchFiles({
    required String query,
    int page = 1,
    String sortBy = 'name',
    String order = 'asc',
    String? category,
  }) async {
    final response = await _apiService.searchFiles(
      query: query,
      page: page,
      sortBy: sortBy,
      order: order,
      category: category,
    );

    if (query.isNotEmpty) {
      await _hiveService.saveSearchQuery(query);
    }

    return response;
  }

  // --- Latest Files ---
  Future<List<FileModel>> getLatestFiles() async {
    return await _apiService.getLatestFiles();
  }

  // --- Stats ---
  Future<List<dynamic>> getStats() async {
    return await _apiService.getStats();
  }

  // --- History ---
  List<String> getSearchHistory() {
    return _hiveService.getSearchHistory();
  }

  Future<void> clearHistory() async {
    await _hiveService.clearHistory();
  }

  // --- Actions ---
  Future<void> reportFile(String path) async {
    await _apiService.reportFile(path);
  }

  Future<void> submitUrl(String url) async {
    await _apiService.submitUrl(url);
  }

  Future<void> ping() async {
    await _apiService.ping();
  }
}
