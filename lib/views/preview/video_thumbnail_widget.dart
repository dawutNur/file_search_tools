import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool showMultiple;
  final int thumbnailCount;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.width = 56,
    this.height = 56,
    this.borderRadius,
    this.showMultiple = false,
    this.thumbnailCount = 4,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  final List<Uint8List> _thumbnails = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Static cache to persist thumbnails across widget rebuilds
  static final Map<String, List<Uint8List>> _thumbnailCache = {};

  // Time positions for carousel: 3 from middle, 3 from end
  static const List<int> _carouselTimePositions = [
    180000, 240000, 300000, 420000, 480000, 540000,
  ];

  static const int _singleThumbnailTime = 180000;
  static const Duration _thumbnailTimeout = Duration(seconds: 60);

  Future<Uint8List?> _loadSingleThumbnail(String url, int timeMs, int maxWidth, int quality) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: quality,
        timeMs: timeMs,
      ).timeout(_thumbnailTimeout);
    } catch (e) {
      return null;
    }
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

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnails() async {
    final normalizedUrl = _normalizeUrl(widget.videoUrl);
    final cacheKey = '${normalizedUrl}_${widget.thumbnailCount}';

    // Check cache first
    if (_thumbnailCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _thumbnails.addAll(_thumbnailCache[cacheKey]!);
          _isLoading = false;
        });
      }
      return;
    }

    final count = widget.showMultiple ? widget.thumbnailCount : 1;

    if (widget.showMultiple) {
      for (int i = 0; i < count; i++) {
        final timeMs = _carouselTimePositions[i % _carouselTimePositions.length];
        final thumbnail = await _loadSingleThumbnail(normalizedUrl, timeMs, 320, 65);

        if (thumbnail != null && mounted) {
          setState(() {
            _thumbnails.add(thumbnail);
            _isLoading = _thumbnails.length < count;
          });
        }
      }

      if (_thumbnails.isNotEmpty) {
        _thumbnailCache[cacheKey] = _thumbnails.toList();
      }
    } else {
      final thumbnail = await _loadSingleThumbnail(normalizedUrl, _singleThumbnailTime, 150, 60);

      if (thumbnail != null && mounted) {
        setState(() {
          _thumbnails.add(thumbnail);
          _isLoading = false;
        });
        _thumbnailCache[cacheKey] = [thumbnail];
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = _thumbnails.isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8);

    return widget.showMultiple
        ? _buildMultipleThumbnails(colorScheme, borderRadius)
        : ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: _buildSingleContent(colorScheme),
            ),
          );
  }

  Widget _buildMultipleThumbnails(ColorScheme colorScheme, BorderRadius borderRadius) {
    if (_isLoading && _thumbnails.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 8),
                Text('Loading...', style: TextStyle(color: colorScheme.outline)),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError || _thumbnails.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_file, size: 48, color: colorScheme.outline),
                const SizedBox(height: 8),
                Text('Video preview', style: TextStyle(color: colorScheme.outline)),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _thumbnails.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_thumbnails[index], fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTimeLabel(index),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_thumbnails.length, (index) {
                  final isActive = index == _currentPage;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            if (_isLoading)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_thumbnails.length}/6',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeLabel(int index) {
    const times = ['3:00', '4:00', '5:00', '7:00', '8:00', '9:00'];
    const sections = ['Middle', 'Middle', 'Middle', 'End', 'End', 'End'];
    if (index < times.length) return '${sections[index]} • ${times[index]}';
    return '';
  }

  Widget _buildSingleContent(ColorScheme colorScheme) {
    if (_isLoading) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.video_file, color: colorScheme.outline),
      );
    }

    if (_hasError || _thumbnails.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.video_file, color: colorScheme.primary, size: 28),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_thumbnails.first, fit: BoxFit.cover),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }
}
