import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/data/dto/card_dto.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    required this.card,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final CardDto card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.style_outlined,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.sourceText,
                      style: AppText.subhead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.translatedText,
                      style: AppText.footnote.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar card?'),
        content: Text(
          '"${card.sourceText}" será removido permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
