import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:client/core/providers/active_session_provider.dart';
import 'package:client/core/router/routes.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/glass_app_bar.dart';
import 'package:client/core/widgets/grouped_list_card.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/session_detail_dto.dart';
import 'package:client/data/dto/session_dto.dart';
import 'package:client/features/session_detail/application/session_detail_controller.dart';
import 'package:client/features/session_detail/widgets/card_detail_sheet.dart';
import 'package:client/features/session_detail/widgets/card_tile.dart';

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(sessionDetailControllerProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: asyncDetail.valueOrNull?.session.name ?? 'Detalhe',
        actions: const [],
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          onRetry: () =>
              ref.read(sessionDetailControllerProvider(id).notifier).refresh(),
        ),
        data: (detail) => _DetailBody(
          detail: detail,
          sessionId: id,
          onDeleteCard: (cardId) => ref
              .read(sessionDetailControllerProvider(id).notifier)
              .deleteCard(cardId),
          onScanTap: () async {
            ref.read(activeSessionProvider.notifier).state = id;
            await context.push(Routes.scan);
            ref.invalidate(sessionDetailControllerProvider(id));
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.sessionId,
    required this.onDeleteCard,
    required this.onScanTap,
  });

  final SessionDetailDto detail;
  final String sessionId;
  final void Function(String cardId) onDeleteCard;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          ProviderScope.containerOf(context)
              .read(sessionDetailControllerProvider(sessionId).notifier)
              .refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              session: detail.session,
              cardCount: detail.cards.length,
              onScanTap: onScanTap,
            ),
          ),
          if (detail.cards.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyCardsView(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: GroupedListCard(
                  dividerIndent: 72,
                  children: [
                    for (final card in detail.cards)
                      CardTile(
                        card: card,
                        onTap: () => _openCardDetail(context, card),
                        onDelete: () => onDeleteCard(card.id),
                      ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.safeBottom),
          ),
        ],
      ),
    );
  }

  void _openCardDetail(BuildContext context, CardDto card) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (_) => CardDetailSheet(card: card, sessionId: sessionId),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.session,
    required this.cardCount,
    required this.onScanTap,
  });

  final SessionDto session;
  final int cardCount;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.name,
            style: AppText.headlineLgMobile,
          ),
          if (session.source != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              session.source!,
              style: AppText.subhead.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Chip(
                icon: Icons.style_outlined,
                label: '$cardCount card${cardCount == 1 ? '' : 's'}',
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                icon: Icons.calendar_today_outlined,
                label: _formatDate(session.createdAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onScanTap,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Scan +'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Exportar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppText.footnote.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCardsView extends StatelessWidget {
  const _EmptyCardsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 56,
            color: AppColors.outline,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum card ainda',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Use a câmera para adicionar cards.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 56, color: AppColors.outline),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Falha ao carregar sessão',
            style: AppText.subhead.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
