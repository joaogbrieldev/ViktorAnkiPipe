import 'package:client/core/router/routes.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/glass_app_bar.dart';
import 'package:client/core/widgets/grouped_list_card.dart';
import 'package:client/core/widgets/search_field.dart';
import 'package:client/data/dto/session_dto.dart';
import 'package:client/features/sessions/application/sessions_controller.dart';
import 'package:client/features/sessions/widgets/new_session_sheet.dart';
import 'package:client/features/sessions/widgets/session_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionsListScreen extends ConsumerStatefulWidget {
  const SessionsListScreen({super.key});

  @override
  ConsumerState<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends ConsumerState<SessionsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewSessionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const NewSessionSheet(),
    );
  }

  Future<void> _refresh() =>
      ref.read(sessionsControllerProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final asyncSessions = ref.watch(sessionsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'ViktorAnkiPipe',
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova sessão',
            onPressed: _openNewSessionSheet,
          ),
        ],
      ),
      body: asyncSessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(onRetry: _refresh),
        data: (sessions) => _SessionsList(
          sessions: sessions,
          searchController: _searchController,
          onDelete: (id) =>
              ref.read(sessionsControllerProvider.notifier).delete(id),
          onRefresh: _refresh,
        ),
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  const _SessionsList({
    required this.sessions,
    required this.searchController,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<SessionDto> sessions;
  final TextEditingController searchController;
  final void Function(String id) onDelete;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: searchController,
        builder: (context, searchValue, _) {
          final query = searchValue.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? sessions
              : sessions
                    .where((s) => s.name.toLowerCase().contains(query))
                    .toList();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sessões', style: AppText.headlineLgMobile),
                      const SizedBox(height: AppSpacing.md),
                      SearchField(
                        controller: searchController,
                        hintText: 'Buscar sessões',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(isSearching: query.isNotEmpty),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: GroupedListCard(
                      dividerIndent: 72,
                      children: [
                        for (final session in filtered)
                          SessionTile(
                            session: session,
                            onTap: () => context.go(
                              Routes.sessionDetailPath(session.id),
                            ),
                            onDelete: () => onDelete(session.id),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.folder_open_outlined,
            size: 56,
            color: AppColors.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isSearching ? 'Nenhum resultado' : 'Nenhuma sessão',
            style: AppText.subhead.copyWith(color: AppColors.onSurfaceVariant),
          ),
          if (!isSearching) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Toque em + para criar uma sessão.',
              style: AppText.footnote.copyWith(color: AppColors.outline),
            ),
          ],
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
            'Falha ao carregar sessões',
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
