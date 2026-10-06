import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/stats_view_model.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(StatsViewModel());
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Stats'),
      ),
      body: Obx(() => switch ((viewModel.isLoading.value, viewModel.stats.isEmpty)) {
        (true, _) => const Center(child: CircularProgressIndicator()),
        (false, true) => Center(child: Text('No stats available', style: textTheme.bodyMedium)),
        (false, false) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewModel.stats.length,
          itemBuilder: (context, index) {
            final stat = viewModel.stats[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.extension, color: colorScheme.primary),
                title: Text(
                  stat['extension'] ?? 'Unknown',
                  style: textTheme.titleSmall,
                ),
                trailing: Text(
                  stat['count']?.toString() ?? '0',
                  style: textTheme.bodyLarge,
                ),
              ),
            );
          },
        ),
      }),
    );
  }
}
