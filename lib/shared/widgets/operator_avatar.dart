import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared operator avatar widget.
/// Shows [photoUrl] when available; falls back to initials derived from [name].
class OperatorAvatar extends StatelessWidget {
  const OperatorAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 34,
  });

  final String   name;
  final String?  photoUrl;
  final double   size;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts.isNotEmpty
            ? parts[0][0].toUpperCase()
            : '?';

    return Container(
      width:  size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.ctTealLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: AppColors.ctTealText,
        ),
      ),
    );
  }
}
