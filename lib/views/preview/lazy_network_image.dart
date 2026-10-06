import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const LazyNetworkImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  State<LazyNetworkImage> createState() => _LazyNetworkImageState();
}

class _LazyNetworkImageState extends State<LazyNetworkImage> {
  bool _shouldLoad = false;

  // Static cache to track loaded URLs - skip lazy loading if already loaded
  static final Set<String> _loadedUrls = {};

  @override
  void initState() {
    super.initState();
    // If already loaded before, show immediately
    final normalizedUrl = _normalizeUrl(widget.imageUrl);
    if (_loadedUrls.contains(normalizedUrl)) {
      _shouldLoad = true;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction > 0.1 && !_shouldLoad) {
      final normalizedUrl = _normalizeUrl(widget.imageUrl);
      _loadedUrls.add(normalizedUrl);
      setState(() {
        _shouldLoad = true;
      });
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(8);

    return VisibilityDetector(
      key: Key('lazy_img_${widget.imageUrl.hashCode}_${identityHashCode(this)}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: _shouldLoad
              ? CachedNetworkImage(
                  imageUrl: _normalizeUrl(widget.imageUrl),
                  fit: widget.fit,
                  filterQuality: FilterQuality.medium,
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                  fadeInDuration: const Duration(milliseconds: 150),
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image, color: colorScheme.outline),
                  ),
                )
              : Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image,
                    color: colorScheme.outline,
                    size: 32,
                  ),
                ),
        ),
      ),
    );
  }
}
