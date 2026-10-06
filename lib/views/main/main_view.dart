import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_search_tools/core/navigation_controller.dart';
import 'package:file_search_tools/core/theme/app_theme.dart';
import 'package:file_search_tools/views/home/home_view.dart';
import 'package:file_search_tools/views/search/search_page.dart';
import 'package:file_search_tools/views/stats/stats_view.dart';
import 'package:file_search_tools/views/history/history_view.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(NavigationController());

    final List<Widget> views = [
      const HomeView(),
      const SearchView(),
      const StatsView(),
      const HistoryView(),
    ];

    return Scaffold(
      body: Obx(() => views[navController.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: navController.currentIndex.value,
          onTap: navController.changeIndex,
          backgroundColor: AppTheme.primaryColor,
          selectedItemColor: AppTheme.textColor,
          unselectedItemColor: AppTheme.mutedTextColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
