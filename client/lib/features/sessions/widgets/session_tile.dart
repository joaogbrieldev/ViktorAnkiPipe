import 'package:flutter/material.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/data/dto/session_dto.dart';

class SessionTile extends StatelessWidget {
  const SessionTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final SessionDto session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const _iconOptions = [
    (Icons.menu_book_outlined, AppColors.primary),
    (Icons.newspaper_outlined, AppColors.secondary),
    (Icons.article_outlined, AppColors.tertiary),
    (Icons.history_edu_outlined, AppColors.primary),
    (Icons.description_outlined, AppColors.outline),
  ];

  @override
  Widget build(BuildContext context) {
    final iconIndex = session.id.hashCode.abs() % _iconOptions.length;
    final (iconData, iconColor) = _iconOptions[iconIndex];

    return Dismissible(
      key: ValueKey(session.id),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: AppText.subhead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          _formatDate(session.createdAt),
                          style: AppText.footnote.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${session.cardCount} card${session.cardCount == 1 ? '' : 's'}',
                          style: AppText.footnote.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                size: 20,
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
        title: const Text('Deletar sessão?'),
        content: Text(
          'A sessão "${session.name}" e todos os seus cards serão removidos.',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'hoje';
    if (diff == 1) return 'ontem';
    if (diff < 7) return 'há ${diff}d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
