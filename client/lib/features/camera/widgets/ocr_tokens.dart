import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/features/camera/application/camera_state.dart';

class OcrTokens extends StatelessWidget {
  const OcrTokens({
    required this.words,
    required this.imageSize,
    required this.onTap,
    super.key,
  });

  final List<DetectedWord> words;
  final Size imageSize;
  final void Function(DetectedWord word) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: words.map((word) {
            final rect = _toScreenRect(word.boundingBox, imageSize, containerSize);
            return Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: GestureDetector(
                onTap: () => onTap(word),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Converts a bounding box in image-pixel coordinates to screen coordinates
  /// using BoxFit.cover scaling logic.
  static Rect _toScreenRect(
    Rect imageBounds,
    Size imageSize,
    Size containerSize,
  ) {
    final scale = math.max(
      containerSize.width / imageSize.width,
      containerSize.height / imageSize.height,
    );
    final dx = (containerSize.width - imageSize.width * scale) / 2;
    final dy = (containerSize.height - imageSize.height * scale) / 2;
    return Rect.fromLTWH(
      dx + imageBounds.left * scale,
      dy + imageBounds.top * scale,
      imageBounds.width * scale,
      imageBounds.height * scale,
    );
  }
}
