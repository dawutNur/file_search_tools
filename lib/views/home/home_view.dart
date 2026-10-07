import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_search_tools/data/models/file_model.dart';
import 'package:file_search_tools/viewmodels/home_view_model.dart';
import 'package:file_search_tools/core/navigation_controller.dart';
import 'package:file_search_tools/views/preview/file_preview_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(HomeViewModel());
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Search Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.signal_cellular_alt),
            tooltip: 'Check API Connectivity',
            onPressed: viewModel.pingApi,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text('Welcome back!', style: textTheme.headlineMedium),
                Text('Explore the latest indexed files below.', style: textTheme.bodyMedium),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                final navController = Get.find<NavigationController>();
                navController.changeIndex(1);
              },
              icon: const Icon(Icons.search),
              label: const Text('Quick Search'),
            ),
            Text('Latest Files', style: textTheme.titleLarge),
            Expanded(
              child: Obx(() => switch ((viewModel.isLoading.value, viewModel.latestFiles.isEmpty)) {
                (true, _) => const Center(child: CircularProgressIndicator()),
                (false, true) => Center(child: Text('No latest files available', style: textTheme.bodyMedium)),
                (false, false) => RefreshIndicator(
                  onRefresh: viewModel.fetchLatestFiles,
                  child: ListView.builder(
                    itemCount: viewModel.latestFiles.length,
                    itemBuilder: (context, index) {
                    final file = viewModel.latestFiles[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => Get.to(() => FilePreviewView(file: file)),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 16,
                            children: [
                              _buildMediaPreview(file, colorScheme),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      file.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      file.category.toUpperCase(),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Row(
                                      spacing: 12,
                                      children: [
                                        Row(
                                          spacing: 4,
                                          children: [
                                            Icon(Icons.storage, size: 14, color: colorScheme.outline),
                                            Text(
                                              file.sizeFormatted.isNotEmpty
                                                  ? file.sizeFormatted
                                                  : _formatSize(file.size),
                                              style: textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          spacing: 4,
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: colorScheme.outline),
                                            Text(file.time, style: textTheme.bodySmall),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: colorScheme.outline),
                            ],
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                ),
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    if (normalized.startsWith('http://')) {
      normalized = normalized.replaceFirst('http://', 'https://');
    }
    return normalized;
  }

  Widget _buildMediaPreview(FileModel file, ColorScheme colorScheme) {
    final category = file.category.toLowerCase();
    final fileName = file.name.toLowerCase();

    final isImage = category.contains('image') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png') ||
        fileName.endsWith('.gif') ||
        fileName.endsWith('.webp');

    final isVideo = category.contains('video') ||
        fileName.endsWith('.mp4') ||
        fileName.endsWith('.webm') ||
        fileName.endsWith('.mov');

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 100,
          height: 100,
          child: CachedNetworkImage(
            imageUrl: _normalizeUrl(file.url),
            fit: BoxFit.cover,
            memCacheWidth: 200,
            memCacheHeight: 200,
            placeholder: (context, url) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(Icons.image, color: colorScheme.outline),
            ),
            errorWidget: (context, url, error) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image, color: colorScheme.outline),
            ),
          ),
        ),
      );
    }

    final iconData = switch (category) {
      _ when isVideo => Icons.video_file,
      'audio' => Icons.audio_file,
      'pdf' => Icons.picture_as_pdf,
      'doc' => Icons.description,
      'txt' => Icons.text_snippet,
      'zip' => Icons.folder_zip,
      'exe' => Icons.terminal,
      _ => Icons.insert_drive_file,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 100,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(iconData, color: colorScheme.primary, size: 48),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
