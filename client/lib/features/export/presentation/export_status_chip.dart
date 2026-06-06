import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';

enum ExportStatus { idle, exporting, success, error }

class ExportStatusChip extends StatelessWidget {
  const ExportStatusChip({
    required this.status,
    this.exportedAt,
    super.key,
  });

  final ExportStatus status;
  final DateTime? exportedAt;

  @override
  Widget build(BuildContext context) {
    if (status == ExportStatus.idle) return const SizedBox.shrink();

    final color = switch (status) {
      ExportStatus.exporting => AppColors.primary,
      ExportStatus.success => const Color(0xFF34C759),
      ExportStatus.error => AppColors.error,
      ExportStatus.idle => AppColors.outline,
    };

    final label = switch (status) {
      ExportStatus.exporting => 'Exportando...',
      ExportStatus.success => exportedAt != null
          ? '● Exportado às ${_formatTime(exportedAt!)}'
          : '● Exportado',
      ExportStatus.error => '● Falha — tentar novamente',
      ExportStatus.idle => '',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ExportStatus.exporting)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(
              status == ExportStatus.success
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              size: 12,
              color: color,
            ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppText.footnote.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
