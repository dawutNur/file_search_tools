import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_service.dart';
import 'views/main/main_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final hiveService = HiveService();
  await hiveService.init();

  // Dependency Injection for HiveService
  Get.put(hiveService);

  runApp(const FileSearchApp());
}

class FileSearchApp extends StatelessWidget {
  const FileSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'File Search Tools',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainView(),
    );
  }
}
