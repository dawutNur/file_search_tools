/// Application constants for File Search Tools
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'File Search Tools';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://filesearch.tools/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // API Endpoints
  static const String searchEndpoint = '/files/search';
  static const String latestEndpoint = '/files/latest';
  static const String statsEndpoint = '/stats';
  static const String reportEndpoint = '/files/report';
  static const String submitEndpoint = '/submit';

  // Storage Keys
  static const String historyBoxName = 'search_history';
  static const String favoritesBoxName = 'favorites';
  static const int maxHistoryItems = 20;

  // Search Configuration
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int defaultPage = 1;
  static const String defaultSortBy = 'time';
  static const String defaultOrder = 'desc';

  // File Categories (must match API values)
  static const List<String> availableCategories = [
    'video',
    'audio',
    'pictures',
    'documents',
  ];

  // Assets
  static const String logoPath = 'assets/images/logo.png';

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double cardMargin = 12.0;
  static const double borderRadius = 8.0;
}
