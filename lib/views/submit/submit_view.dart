import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/submit_view_model.dart';

class SubmitView extends StatelessWidget {
  const SubmitView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(SubmitViewModel());
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final urlController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Submit URL')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Icon(Icons.cloud_upload, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Submit a URL',
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Submit a direct file URL for indexing.\nThe file will be added to our search database.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // URL Input
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/file.mp4',
                labelText: 'File URL',
                prefixIcon: Icon(Icons.link, color: colorScheme.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => urlController.clear(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => viewModel.submitUrl(urlController.text),
            ),
            const SizedBox(height: 24),

            // Submit Button
            Obx(() => ElevatedButton.icon(
              onPressed: viewModel.isSubmitting.value
                  ? null
                  : () => viewModel.submitUrl(urlController.text),
              icon: viewModel.isSubmitting.value
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(viewModel.isSubmitting.value ? 'Submitting...' : 'Submit URL'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )),
            const SizedBox(height: 32),

            // Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Guidelines', style: textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _guideline(context, Icons.check_circle, 'Direct file links only'),
                    _guideline(context, Icons.check_circle, 'Supported: video, audio, images, documents'),
                    _guideline(context, Icons.check_circle, 'Public URLs accessible without login'),
                    _guideline(context, Icons.cancel, 'No streaming URLs (YouTube, etc.)', isNegative: true),
                    _guideline(context, Icons.cancel, 'No private or password-protected files', isNegative: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideline(BuildContext context, IconData icon, String text, {bool isNegative = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isNegative ? colorScheme.error : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
