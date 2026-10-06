import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/file_model.dart';
import '../../viewmodels/search_view_model.dart';
import '../../core/storage/hive_service.dart';
import '../preview/file_preview_view.dart';
import '../preview/video_thumbnail_widget.dart';
import '../preview/lazy_network_image.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SearchViewModel());
    final hiveService = Get.find<HiveService>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    final scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        if (!viewModel.isLoading.value && viewModel.hasNext.value) {
          viewModel.loadNextPage();
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for files...',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: Obx(() => viewModel.currentQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          viewModel.onSearchChanged('');
                        },
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onChanged: viewModel.onSearchChanged,
              onSubmitted: (_) => viewModel.performSearch(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              spacing: 8,
              children: [
                Text('Sort by:', style: textTheme.labelMedium),
                Obx(() => SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'name', label: Text('Name')),
                        ButtonSegment(value: 'size', label: Text('Size')),
                        ButtonSegment(value: 'time', label: Text('Time')),
                      ],
                      selected: {viewModel.sortBy.value},
                      onSelectionChanged: (selected) => viewModel.updateSort(selected.first),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    )),
                const Spacer(),
                Obx(() => IconButton(
                      icon: Icon(
                        viewModel.order.value == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                        color: colorScheme.primary,
                      ),
                      tooltip: viewModel.order.value == 'asc' ? 'Ascending' : 'Descending',
                      onPressed: () => viewModel.updateOrder(viewModel.order.value == 'asc' ? 'desc' : 'asc'),
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Obx(() => FilterChip(
                      label: const Text('All'),
                      selected: viewModel.category.value == null,
                      onSelected: (_) => viewModel.updateCategory(null),
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                    )),
                ...viewModel.availableCategories.map((cat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Obx(() => FilterChip(
                            label: Text(cat.toUpperCase()),
                            selected: viewModel.category.value == cat,
                            onSelected: (_) => viewModel.updateCategory(cat),
                            selectedColor: colorScheme.primaryContainer,
                            checkmarkColor: colorScheme.onPrimaryContainer,
                          )),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (viewModel.isLoading.value && viewModel.results.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.currentQuery.value.isNotEmpty) {
                if (viewModel.results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 16,
                      children: [
                        Icon(Icons.search_off, size: 64, color: colorScheme.outline),
                        Text('No results found', style: textTheme.titleMedium),
                        Text('Try a different search term or filter', style: textTheme.bodySmall),
                      ],
                    ),
                  );
                }

                final hasMore = viewModel.hasNext.value;
                final itemCount = viewModel.results.length + (hasMore ? 1 : 0);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${viewModel.results.length} results', style: textTheme.labelMedium),
                          Text('Page ${viewModel.currentPage.value}/${viewModel.totalPages.value}', style: textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (index == viewModel.results.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Obx(() => viewModel.isLoading.value
                                    ? const CircularProgressIndicator()
                                    : const SizedBox.shrink()),
                              ),
                            );
                          }

                          final file = viewModel.results[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  ],
                );
              }

              final history = hiveService.getSearchHistory();
              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 16,
                    children: [
                      Icon(Icons.search, size: 64, color: colorScheme.outline),
                      Text('Start searching', style: textTheme.titleMedium),
                      Text('Enter a search term above', style: textTheme.bodySmall),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Recent Searches', style: textTheme.titleSmall),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final query = history[index];
                        return ListTile(
                          leading: Icon(Icons.history, color: colorScheme.outline),
                          title: Text(query, style: textTheme.bodyLarge),
                          onTap: () {
                            searchController.text = query;
                            viewModel.onSearchChanged(query);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
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

    // Default icon for other file types
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
