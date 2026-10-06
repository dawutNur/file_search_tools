import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
  bool _hasStartedLoading = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Static cache to persist thumbnails across widget rebuilds
  static final Map<String, List<Uint8List>> _thumbnailCache = {};

  // Time positions for carousel: 3 from middle, 3 from end (no start)
  static const List<int> _carouselTimePositions = [
    180000,   // 3:00 - middle section
    240000,   // 4:00 - middle section
    300000,   // 5:00 - middle section
    420000,   // 7:00 - end section
    480000,   // 8:00 - end section
    540000,   // 9:00 - end section
  ];

  // For single thumbnail (list view), use first carousel position (3:00 middle)
  static const int _singleThumbnailTime = 180000; // 3 minutes into video

  // Thumbnail load timeout (60 seconds for slow connections)
  static const Duration _thumbnailTimeout = Duration(seconds: 60);

  /// Load a single thumbnail with specified parameters
  Future<Uint8List?> _loadSingleThumbnail(
    String url,
    int timeMs,
    int maxWidth,
    int quality,
  ) async {
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

  void _onVisibilityChanged(VisibilityInfo info) {
    // Start loading when at least 10% visible
    if (info.visibleFraction > 0.1 && !_hasStartedLoading) {
      _hasStartedLoading = true;
      _loadThumbnails();
    }
  }

  String _normalizeUrl(String url) {
    var normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    if (normalizedUrl.startsWith('http://')) {
      normalizedUrl = normalizedUrl.replaceFirst('http://', 'https://');
    }
    return normalizedUrl;
  }

  @override
  void initState() {
    super.initState();
    // Check cache immediately - if cached, load without waiting for visibility
    final normalizedUrl = _normalizeUrl(widget.videoUrl);
    final cacheKey = '${normalizedUrl}_${widget.thumbnailCount}';
    if (_thumbnailCache.containsKey(cacheKey)) {
      _hasStartedLoading = true;
      _thumbnails.addAll(_thumbnailCache[cacheKey]!);
      _isLoading = false;
    }
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

    // Optimized for 6 Mbit/s (~750 KB/s):
    // - Reduced resolution: 320px carousel, 150px single
    // - Lower quality: 65% carousel, 60% single (~20-40KB each)
    // - Sequential loading for stability

    if (widget.showMultiple) {
      // Sequential loading for carousel
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
      // Single thumbnail for list view
      final thumbnail = await _loadSingleThumbnail(
        normalizedUrl,
        _singleThumbnailTime,
        150,
        60,
      );

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

    // Wrap with VisibilityDetector for lazy loading
    return VisibilityDetector(
      key: Key('video_thumb_${widget.videoUrl.hashCode}_${identityHashCode(this)}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.showMultiple
          ? _buildMultipleThumbnails(colorScheme, borderRadius)
          : ClipRRect(
              borderRadius: borderRadius,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: _buildSingleContent(colorScheme),
              ),
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Loading thumbnails...'),
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
            // Carousel
            PageView.builder(
              controller: _pageController,
              itemCount: _thumbnails.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final thumbnail = _thumbnails[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      thumbnail,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                    // Time indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
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
            // Dot indicators
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_thumbnails.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Loading indicator for more thumbnails
            if (_isLoading)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_thumbnails.length}/6',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeLabel(int index) {
    final times = ['3:00', '4:00', '5:00', '7:00', '8:00', '9:00'];
    final sections = ['Middle', 'Middle', 'Middle', 'End', 'End', 'End'];
    if (index < times.length) {
      return '${sections[index]} • ${times[index]}';
    }
    return '';
  }

  Widget _buildSingleContent(ColorScheme colorScheme) {
    if (_isLoading) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_hasError || _thumbnails.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.video_file, color: colorScheme.primary, size: 28),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.play_arrow, color: colorScheme.onPrimary, size: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          _thumbnails.first,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
          ),
        ),
      ],
    );
  }
}
