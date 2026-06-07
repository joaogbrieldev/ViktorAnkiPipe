import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/features/ai_example/presentation/example_section.dart';
import 'package:client/features/session_detail/application/session_detail_controller.dart';

class CardDetailSheet extends ConsumerWidget {
  const CardDetailSheet({
    required this.card,
    required this.sessionId,
    super.key,
  });

  final CardDto card;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _Handle(),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Card', style: AppText.navTitle),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionCard(label: 'Palavra', value: card.sourceText),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      label: 'Tradução',
                      value: card.translatedText,
                    ),
                    if (card.context != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SectionCard(
                        label: 'Contexto',
                        value: card.context!,
                        highlight: card.sourceText,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ExampleSection(card: card, sessionId: sessionId),
                    const SizedBox(height: AppSpacing.xl),
                    OutlinedButton.icon(
                      onPressed: () => _deleteCard(context, ref),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Deletar card'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar card?'),
        content: Text('"${card.sourceText}" será removido permanentemente.'),
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
    if (confirmed == true && context.mounted) {
      await ref
          .read(sessionDetailControllerProvider(sessionId).notifier)
          .deleteCard(card.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.labelCaps.copyWith(
              color: AppColors.outline,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          highlight != null
              ? _highlightedText(value, highlight!)
              : Text(value, style: AppText.bodyMd),
        ],
      ),
    );
  }

  Widget _highlightedText(String text, String word) {
    final lower = text.toLowerCase();
    final wordLower = word.toLowerCase();
    final idx = lower.indexOf(wordLower);
    if (idx == -1) return Text(text, style: AppText.bodyMd);

    return RichText(
      text: TextSpan(
        style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + word.length),
            style: AppText.bodyMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: text.substring(idx + word.length)),
        ],
      ),
    );
  }
}

