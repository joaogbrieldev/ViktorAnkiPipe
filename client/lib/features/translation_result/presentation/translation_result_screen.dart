import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:client/core/providers/active_session_provider.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/primary_button.dart';
import 'package:client/features/sessions/application/sessions_controller.dart';
import 'package:client/features/translation_result/application/translation_controller.dart';
import 'package:client/features/translation_result/application/translation_state.dart';

class TranslationResultScreen extends ConsumerStatefulWidget {
  const TranslationResultScreen({super.key});

  @override
  ConsumerState<TranslationResultScreen> createState() =>
      _TranslationResultScreenState();
}

class _TranslationResultScreenState
    extends ConsumerState<TranslationResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(translationControllerProvider.notifier).fetch();
    });
  }

  Future<void> _handleCta() async {
    final activeSession = ref.read(activeSessionProvider);
    if (activeSession != null) {
      await _addToSession(activeSession);
    } else {
      final picked = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SessionPickerSheet(),
      );
      if (picked != null && mounted) {
        await _addToSession(picked);
      }
    }
  }

  Future<void> _addToSession(String sessionId) async {
    await ref
        .read(translationControllerProvider.notifier)
        .addToSession(sessionId);
    if (!mounted) return;
    final cardState = ref.read(translationControllerProvider).card;
    if (cardState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao adicionar card. Tente novamente.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    Future.microtask(
      () => messenger.showSnackBar(
        const SnackBar(content: Text('Card adicionado')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(translationControllerProvider);
    final activeSession = ref.watch(activeSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _BackgroundImage(
              imagePath: state.selection.capturedImagePath,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0x4D000000))),
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.92,
              builder: (_, scrollController) => _ResultSheet(
                scrollController: scrollController,
                state: state,
                activeSessionId: activeSession,
                onCta: () => _handleCta(),
                onClose: () => context.pop(),
                onRetry: () =>
                    ref.read(translationControllerProvider.notifier).fetch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background ─────────────────────────────────────────────────────────────────

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return const ColoredBox(color: Color(0xFF1C1C1E));
    }
    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, st) => const ColoredBox(color: Color(0xFF1C1C1E)),
    );
  }
}

// ── Result Sheet ───────────────────────────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.scrollController,
    required this.state,
    required this.activeSessionId,
    required this.onCta,
    required this.onClose,
    required this.onRetry,
  });

  final ScrollController scrollController;
  final TranslationState state;
  final String? activeSessionId;
  final VoidCallback onCta;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.surface.withValues(alpha: 0.96),
          child: Column(
            children: [
              _HandleBar(),
              _Header(onClose: onClose),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: [
                    _SectionCard(
                      label: 'TERMO SELECIONADO',
                      accent: AppColors.primary,
                      value: Text(
                        state.selection.word,
                        style: AppText.subhead,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      label: 'TRADUÇÃO',
                      accent: AppColors.tertiary,
                      value: state.translation.when(
                        data: (t) => Text(t, style: AppText.subhead),
                        loading: () => const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (e, s) => _TranslationError(onRetry: onRetry),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      label: 'CONTEXTO NO LIVRO',
                      accent: AppColors.onSurfaceVariant,
                      value: state.selection.contextLine != null
                          ? _ContextHighlight(
                              line: state.selection.contextLine!,
                              word: state.selection.word,
                            )
                          : Text(
                              state.selection.word,
                              style: AppText.subhead
                                  .copyWith(color: AppColors.onSurface),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
              // Gradient fade above CTA
              SizedBox(
                height: AppSpacing.xl,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.surface.withValues(alpha: 0.96),
                        AppColors.surface.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.of(context).padding.bottom,
                ),
                child: PrimaryButton(
                  key: const Key('cta_button'),
                  label: activeSessionId != null
                      ? 'Adicionar ao deck'
                      : 'Escolher sessão',
                  icon: Icons.add_box_outlined,
                  isLoading: state.card.isLoading,
                  onPressed: state.card.isLoading ? null : onCta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resultado', style: AppText.headlineLgMobile),
                const SizedBox(height: 2),
                Text(
                  'Detectado: Inglês para Português',
                  style: AppText.footnote
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: AppColors.onSurface,
          ),
        ],
      ),
    );
  }
}

// ── Section Card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.accent,
    required this.value,
  });

  final String label;
  final Color accent;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F8),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.labelCaps.copyWith(
              color: accent,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          value,
        ],
      ),
    );
  }
}

// ── Context highlight ──────────────────────────────────────────────────────────

class _ContextHighlight extends StatelessWidget {
  const _ContextHighlight({required this.line, required this.word});

  final String line;
  final String word;

  static List<String> _split(String line, String word) {
    final idx = line.toLowerCase().indexOf(word.toLowerCase());
    if (idx < 0) return [line];
    return [
      if (idx > 0) line.substring(0, idx),
      line.substring(idx, idx + word.length),
      if (idx + word.length < line.length) line.substring(idx + word.length),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final segments = _split(line, word);
    return RichText(
      text: TextSpan(
        children: segments.map((segment) {
          final isWord = segment.toLowerCase() == word.toLowerCase();
          return TextSpan(
            text: segment,
            style: isWord
                ? AppText.subhead.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary.withValues(alpha: 0.3),
                  )
                : AppText.subhead.copyWith(color: AppColors.onSurface),
          );
        }).toList(),
      ),
    );
  }
}

// ── Translation error widget ───────────────────────────────────────────────────

class _TranslationError extends StatelessWidget {
  const _TranslationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Erro ao traduzir',
          style: AppText.footnote.copyWith(color: AppColors.error),
        ),
        const Spacer(),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: const Size(0, 32),
          ),
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

// ── Session Picker Sheet ───────────────────────────────────────────────────────

class _SessionPickerSheet extends ConsumerStatefulWidget {
  const _SessionPickerSheet();

  @override
  ConsumerState<_SessionPickerSheet> createState() =>
      _SessionPickerSheetState();
}

class _SessionPickerSheetState extends ConsumerState<_SessionPickerSheet> {
  bool _showCreate = false;
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _quickCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isCreating = true);
    try {
      await ref.read(sessionsControllerProvider.notifier).create(name);
      final sessions = ref.read(sessionsControllerProvider).valueOrNull ?? [];
      if (mounted && sessions.isNotEmpty) {
        Navigator.of(context).pop(sessions.first.id);
      }
    } catch (_) {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsControllerProvider);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: safeBottom + keyboardHeight),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Text('Escolher sessão', style: AppText.navTitle),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          if (_showCreate)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('quick_create_field'),
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nome da sessão',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onSubmitted: (_) => _quickCreate(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _isCreating
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton.filled(
                          onPressed: _quickCreate,
                          icon: const Icon(Icons.check),
                        ),
                ],
              ),
            ),
          Flexible(
            child: sessionsAsync.when(
              data: (sessions) => ListView(
                shrinkWrap: true,
                children: [
                  if (!_showCreate)
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'Criar sessão rápida',
                        style: AppText.bodyMd
                            .copyWith(color: AppColors.primary),
                      ),
                      onTap: () => setState(() => _showCreate = true),
                    ),
                  ...sessions.map(
                    (s) => ListTile(
                      title: Text(s.name, style: AppText.bodyMd),
                      subtitle: Text(
                        '${s.cardCount} ${s.cardCount == 1 ? 'card' : 'cards'}',
                        style: AppText.footnote
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      onTap: () => Navigator.of(context).pop(s.id),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SizedBox(
                height: 80,
                child: Center(
                  child: Text(
                    'Erro ao carregar sessões',
                    style: AppText.bodyMd.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
