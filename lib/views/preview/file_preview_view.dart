import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../data/repositories/file_repository.dart';
import '../../data/models/file_model.dart';
import '../../viewmodels/favorites_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class FilePreviewView extends StatelessWidget {
  final FileModel file;

  const FilePreviewView({super.key, required this.file});

  void _showBrowserSelectionDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('Open with', style: textTheme.titleLarge),
            Text('Choose how to open this file', style: textTheme.bodySmall),
            const Divider(),
            _browserOption(
              context,
              icon: Icons.open_in_browser,
              color: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: 'In-App Browser',
              subtitle: 'Open inside the app',
              onTap: () {
                Get.back();
                _launchUrl(LaunchMode.inAppBrowserView);
              },
            ),
            _browserOption(
              context,
              icon: Icons.shield,
              color: const Color(0xFFDE5833),
              iconColor: Colors.white,
              title: 'DuckDuckGo',
              subtitle: 'Privacy-focused browser',
              onTap: () {
                Get.back();
                _launchInBrowser('com.duckduckgo.mobile.android', 'ddgQuickLink');
              },
            ),
            _browserOption(
              context,
              icon: Icons.public,
              color: const Color(0xFF4285F4),
              iconColor: Colors.white,
              title: 'Chrome',
              subtitle: 'Google Chrome browser',
              onTap: () {
                Get.back();
                _launchInBrowser('com.android.chrome', 'googlechrome');
              },
            ),
            _browserOption(
              context,
              icon: Icons.local_fire_department,
              color: const Color(0xFFFF7139),
              iconColor: Colors.white,
              title: 'Firefox',
              subtitle: 'Mozilla Firefox browser',
              onTap: () {
                Get.back();
                _launchInBrowser('org.mozilla.firefox', 'firefox');
              },
            ),
            _browserOption(
              context,
              icon: Icons.open_in_new,
              color: colorScheme.secondaryContainer,
              iconColor: colorScheme.onSecondaryContainer,
              title: 'Default Browser',
              subtitle: 'System default browser',
              onTap: () {
                Get.back();
                _launchUrl(LaunchMode.externalApplication);
              },
            ),
            const Divider(),
            _browserOption(
              context,
              icon: Icons.content_copy,
              color: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
              title: 'Copy Link',
              subtitle: 'Copy URL to clipboard',
              onTap: () {
                Get.back();
                _copyToClipboard();
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _browserOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _launchInBrowser(String androidPackage, String iosScheme) async {
    final normalizedUrl = _normalizeUrl(file.url);

    if (Platform.isAndroid) {
      // Use android_intent_plus for reliable package-specific launching
      final intent = AndroidIntent(
        action: 'action_view',
        data: normalizedUrl,
        package: androidPackage,
      );

      try {
        await intent.launch();
        return;
      } catch (e) {
        // Package not installed or other error
        final shouldOpenDefault = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Browser not found'),
            content: Text('${_getBrowserName(androidPackage)} is not installed.\nOpen in default browser?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Open'),
              ),
            ],
          ),
        );

        if (shouldOpenDefault == true) {
          _launchUrl(LaunchMode.externalApplication);
        }
      }
      return;
    } else if (Platform.isIOS) {
      final uri = Uri.parse(normalizedUrl);
      // Try iOS URL scheme
      final iosUri = Uri.parse('$iosScheme://${uri.host}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}');
      try {
        if (await canLaunchUrl(iosUri)) {
          await launchUrl(iosUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      Get.snackbar(
        'Browser not found',
        'Opening in default browser instead',
        snackPosition: SnackPosition.BOTTOM,
      );
      _launchUrl(LaunchMode.externalApplication);
      return;
    }

    // Fallback for other platforms
    _launchUrl(LaunchMode.externalApplication);
  }

  String _getBrowserName(String packageName) {
    return switch (packageName) {
      'com.duckduckgo.mobile.android' => 'DuckDuckGo',
      'com.android.chrome' => 'Chrome',
      'org.mozilla.firefox' => 'Firefox',
      _ => packageName,
    };
  }

  String _normalizeUrl(String url) {
    var normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    // Force HTTPS for security (Android blocks cleartext traffic)
    if (normalizedUrl.startsWith('http://')) {
      normalizedUrl = normalizedUrl.replaceFirst('http://', 'https://');
    }
    return normalizedUrl;
  }

  Future<void> _launchUrl(LaunchMode mode) async {
    final normalizedUrl = _normalizeUrl(file.url);
    final Uri url = Uri.parse(normalizedUrl);
    try {
      final canLaunch = await canLaunchUrl(url);
      if (!canLaunch) {
        Get.snackbar(
          'Error',
          'Cannot open this URL. Try copying the link instead.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final launched = await launchUrl(
        url,
        mode: mode,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );

      if (!launched) {
        Get.snackbar(
          'Error',
          'Failed to open URL',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not open link: ${e.toString().replaceAll('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _copyToClipboard() {
    final normalizedUrl = _normalizeUrl(file.url);
    Clipboard.setData(ClipboardData(text: normalizedUrl));
    Get.snackbar(
      'Copied',
      'Link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showReportDialog() {
    Get.defaultDialog(
      title: 'Report File',
      content: Text('Are you sure you want to report ${file.name}?'),
      textConfirm: 'Report',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          await FileRepository().reportFile(file.url);
          Get.back();
          Get.snackbar('Success', 'File reported successfully');
        } catch (e) {
          Get.snackbar('Error', e.toString());
        }
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final category = file.category.toLowerCase();
    final isImage =
        category.contains('image') ||
        file.name.toLowerCase().endsWith('.jpg') ||
        file.name.toLowerCase().endsWith('.jpeg') ||
        file.name.toLowerCase().endsWith('.png') ||
        file.name.toLowerCase().endsWith('.gif') ||
        file.name.toLowerCase().endsWith('.webp');
    final isVideo =
        category.contains('video') ||
        file.name.toLowerCase().endsWith('.mp4') ||
        file.name.toLowerCase().endsWith('.webm') ||
        file.name.toLowerCase().endsWith('.mov');
    final isAudio =
        category.contains('audio') ||
        file.name.toLowerCase().endsWith('.mp3') ||
        file.name.toLowerCase().endsWith('.wav') ||
        file.name.toLowerCase().endsWith('.ogg');
    final isPdf =
        category.contains('pdf') || file.name.toLowerCase().endsWith('.pdf');

    final colorScheme = Theme.of(context).colorScheme;
    final favoritesViewModel = Get.put(FavoritesViewModel());

    return Scaffold(
      appBar: AppBar(
        title: Text(file.name, overflow: TextOverflow.ellipsis),
        actions: [
          Obx(() => IconButton(
            icon: Icon(
              favoritesViewModel.isFavorite(file.url)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favoritesViewModel.isFavorite(file.url)
                  ? colorScheme.error
                  : null,
            ),
            tooltip: favoritesViewModel.isFavorite(file.url)
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: () => favoritesViewModel.toggleFavorite(file),
          )),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
            onPressed: () => _showBrowserSelectionDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 24,
          children: [
            // Preview Section
            _buildPreview(context, isImage, isVideo, isAudio, isPdf),

            // File Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow(context, 'Name', file.name),
                    _infoRow(context, 'Size', _formatSize(file.size)),
                    _infoRow(context, 'Time', file.time),
                    _infoRow(context, 'Category', file.category),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showBrowserSelectionDialog(context),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open File'),
                ),
                OutlinedButton.icon(
                  onPressed: _showReportDialog,
                  icon: Icon(Icons.report_problem, color: colorScheme.error),
                  label: Text(
                    'Report',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    bool isImage,
    bool isVideo,
    bool isAudio,
    bool isPdf,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isImage) {
      final imageUrl = _normalizeUrl(file.url);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            fadeInDuration: const Duration(milliseconds: 300),
            progressIndicatorBuilder: (context, url, progress) => Container(
              height: 200,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: progress.progress,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  Text('Failed to load image', style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isVideo) {
      return Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showBrowserSelectionDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, size: 32, color: colorScheme.onPrimary),
                ),
                Text('Video File', style: textTheme.titleMedium),
                Text('Tap to play in browser', style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    if (isAudio) {
      return Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showBrowserSelectionDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 32,
                    color: colorScheme.onPrimary,
                  ),
                ),
                Text('Audio File', style: textTheme.titleMedium),
                Text('Tap to play in browser', style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    if (isPdf) {
      return Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showBrowserSelectionDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                Text('PDF Document', style: textTheme.titleMedium),
                Text('Tap to view in browser', style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    // Default file preview
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showBrowserSelectionDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              Icon(
                _getFileIcon(file.category),
                size: 64,
                color: colorScheme.primary,
              ),
              Text(file.category.toUpperCase(), style: textTheme.titleMedium),
              Text('Tap to open', style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String category) {
    return switch (category.toLowerCase()) {
      'image' => Icons.image,
      'video' => Icons.video_file,
      'audio' => Icons.audio_file,
      'pdf' => Icons.picture_as_pdf,
      'doc' => Icons.description,
      'txt' => Icons.text_snippet,
      'zip' => Icons.folder_zip,
      'exe' => Icons.terminal,
      _ => Icons.insert_drive_file,
    };
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall),
          Flexible(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
