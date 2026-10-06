import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/file_model.dart';
import '../../viewmodels/favorites_view_model.dart';
import '../preview/file_preview_view.dart';
import '../preview/video_thumbnail_widget.dart';
import '../preview/lazy_network_image.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(FavoritesViewModel());
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          Obx(() => viewModel.favorites.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear All',
                  onPressed: () => _showClearDialog(context, viewModel),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (viewModel.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text('No favorites yet', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Tap the heart icon to add files', style: textTheme.bodySmall),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => viewModel.loadFavorites(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.favorites.length,
            itemBuilder: (context, index) {
              final file = viewModel.favorites[index];
              return Dismissible(
                key: Key(file.url),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: colorScheme.error,
                  child: Icon(Icons.delete, color: colorScheme.onError),
                ),
                onDismissed: (_) => viewModel.removeFavorite(file),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => Get.to(() => FilePreviewView(file: file)),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMediaPreview(file, colorScheme),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  file.category.toUpperCase(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.storage, size: 14, color: colorScheme.outline),
                                    const SizedBox(width: 4),
                                    Text(
                                      file.sizeFormatted.isNotEmpty
                                          ? file.sizeFormatted
                                          : _formatSize(file.size),
                                      style: textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time, size: 14, color: colorScheme.outline),
                                    const SizedBox(width: 4),
                                    Text(file.time, style: textTheme.bodySmall),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.favorite, color: colorScheme.error),
                            onPressed: () => viewModel.removeFavorite(file),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _showClearDialog(BuildContext context, FavoritesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text('Are you sure you want to remove all favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
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
      return LazyNetworkImage(
        imageUrl: file.url,
        width: 100,
        height: 100,
        borderRadius: BorderRadius.circular(8),
      );
    }

    if (isVideo) {
      return VideoThumbnailWidget(
        videoUrl: file.url,
        width: 100,
        height: 100,
        borderRadius: BorderRadius.circular(8),
      );
    }

    final iconData = switch (category) {
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
