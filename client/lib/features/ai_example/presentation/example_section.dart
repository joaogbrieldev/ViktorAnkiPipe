import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/features/session_detail/application/session_detail_controller.dart';

class ExampleSection extends ConsumerStatefulWidget {
  const ExampleSection({
    required this.card,
    required this.sessionId,
    super.key,
  });

  final CardDto card;
  final String sessionId;

  @override
  ConsumerState<ExampleSection> createState() => _ExampleSectionState();
}

class _ExampleSectionState extends ConsumerState<ExampleSection> {
  bool _loading = false;
  String? _localExample;

  @override
  void initState() {
    super.initState();
    _localExample = widget.card.exampleSentence;
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final example = await ref
          .read(cardRepositoryProvider)
          .generateExample(cardId: widget.card.id);
      if (!mounted) return;
      setState(() => _localExample = example);
      await ref
          .read(sessionDetailControllerProvider(widget.sessionId).notifier)
          .setExampleFor(widget.card.id, example);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível gerar exemplo'),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: _generate,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
            'Frase exemplo',
            style: AppText.labelCaps.copyWith(
              color: AppColors.tertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_localExample != null)
            _ExistingExample(
              example: _localExample!,
              word: widget.card.sourceText,
              loading: _loading,
              onRegenerate: _generate,
            )
          else
            _GenerateButton(loading: _loading, onPressed: _generate),
        ],
      ),
    );
  }
}

class _ExistingExample extends StatelessWidget {
  const _ExistingExample({
    required this.example,
    required this.word,
    required this.loading,
    required this.onRegenerate,
  });

  final String example;
  final String word;
  final bool loading;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _HighlightedText(text: example, word: word)),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm, top: 2),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            tooltip: 'Regerar',
            onPressed: onRegenerate,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome_outlined, size: 18),
      label: Text(loading ? 'Gerando...' : 'Gerar frase de exemplo'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.word});

  final String text;
  final String word;

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final wordLower = word.toLowerCase();
    final idx = lower.indexOf(wordLower);

    final baseStyle = AppText.bodyMd.copyWith(
      color: AppColors.onSurface,
      fontStyle: FontStyle.italic,
    );

    if (idx == -1) return Text(text, style: baseStyle);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + word.length),
            style: baseStyle.copyWith(
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
