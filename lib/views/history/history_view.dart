import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_search_tools/viewmodels/history_view_model.dart';
import 'package:file_search_tools/viewmodels/search_view_model.dart';
import 'package:file_search_tools/core/navigation_controller.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(HistoryViewModel());
    final history = viewModel.history;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear history',
              onPressed: () async {
                final confirm = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Are you sure you want to clear all search history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await viewModel.clearHistory();
                  Get.forceAppUpdate();
                }
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Icon(Icons.history, size: 64, color: colorScheme.outline),
                  Text('No search history', style: textTheme.titleMedium),
                  Text('Your searches will appear here', style: textTheme.bodySmall),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final query = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.history, color: colorScheme.outline),
                    title: Text(query, style: textTheme.bodyLarge),
                    trailing: Icon(Icons.search, color: colorScheme.primary),
                    onTap: () {
                      final searchViewModel = Get.find<SearchViewModel>();
                      searchViewModel.onSearchChanged(query);
                      final navController = Get.find<NavigationController>();
                      navController.changeIndex(1);
                    },
                  ),
                );
              },
            ),
    );
  }
}
