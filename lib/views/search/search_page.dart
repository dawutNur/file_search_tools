import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/file_model.dart';
import '../../viewmodels/search_view_model.dart';
import '../../core/storage/hive_service.dart';
import '../preview/file_preview_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final searchController = TextEditingController();
  final scrollController = ScrollController();
  bool _showScrollUp = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton = scrollController.offset > 300;
    if (showButton != _showScrollUp) {
      setState(() => _showScrollUp = showButton);
    }
  }

  void _scrollToTop() {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SearchViewModel());
    final hiveService = Get.find<HiveService>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Obx(() => viewModel.totalPages.value > 1
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filled(
                        onPressed: viewModel.currentPage.value > 1
                            ? () {
                                viewModel.loadPage(viewModel.currentPage.value - 1);
                                _scrollToTop();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Page ${viewModel.currentPage.value} / ${viewModel.totalPages.value}',
                        style: textTheme.titleSmall,
                      ),
                      IconButton.filled(
                        onPressed: viewModel.hasNext.value
                            ? () {
                                viewModel.loadPage(viewModel.currentPage.value + 1);
                                _scrollToTop();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
        ),
      ),
      floatingActionButton: _showScrollUp
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
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
                        itemCount: viewModel.results.length,
                        itemBuilder: (context, index) {
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
                    if (viewModel.isLoading.value)
                      const LinearProgressIndicator(),
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
