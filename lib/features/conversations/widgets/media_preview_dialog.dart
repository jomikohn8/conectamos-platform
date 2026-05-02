import 'package:flutter/material.dart';

/// Fullscreen image viewer for network URLs.
/// Tap anywhere to dismiss.
class MediaPreviewDialog extends StatelessWidget {
  const MediaPreviewDialog({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (ctx, e, s) => const Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
