import 'package:dio/dio.dart';
import '../../data/models/file_model.dart';
import '../../data/models/search_response_model.dart';
import '../constants.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ));

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'Network error. Please try again.';
    }
  }

  Future<SearchResponseModel> searchFiles({
    required String query,
    int page = 1,
    int perPage = 12,
    String sortBy = 'name',
    String order = 'asc',
    String? category,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.searchEndpoint,
        queryParameters: {
          'q': query,
          'page': page,
          'per_page': perPage,
          'sort_by': sortBy,
          'order': order,
          if (category != null) 'category': category,
        },
      );

      return SearchResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to search files: $e');
    }
  }

  Future<List<FileModel>> getLatestFiles({int limit = 12}) async {
    try {
      final response = await _dio.get(
        AppConstants.latestEndpoint,
        queryParameters: {'limit': limit},
      );
      final List data = response.data;
      return data.map((json) => FileModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to fetch latest files: $e');
    }
  }

  Future<void> reportFile(String path) async {
    try {
      await _dio.post(AppConstants.reportEndpoint, data: {'path': path});
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to report file: $e');
    }
  }

  Future<void> submitUrl(String url) async {
    try {
      await _dio.post(AppConstants.submitEndpoint, data: {'url': url});
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to submit URL: $e');
    }
  }

  Future<void> ping() async {
    try {
      await _dio.get(AppConstants.statsEndpoint);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('API unreachable: $e');
    }
  }

  Future<List<dynamic>> getStats() async {
    try {
      final response = await _dio.get(AppConstants.statsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to fetch stats: $e');
    }
  }
}
