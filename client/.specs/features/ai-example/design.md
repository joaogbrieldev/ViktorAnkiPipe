# Design: AI Example Generation

## Data
Já existe `CardRepository.generateExample(cardId)` (criado em translation-result).
Adicionar `CardDto.copyWith(exampleSentence: ...)` se ainda não houver.

## Widget local
`lib/features/ai_example/presentation/example_section.dart`:
```dart
class ExampleSection extends ConsumerStatefulWidget {
  final CardDto card;
  const ExampleSection({required this.card, super.key});
  @override
  ConsumerState createState() => _ExampleSectionState();
}

class _ExampleSectionState extends ConsumerState<ExampleSection> {
  bool _loading = false;
  String? _localError;

  Future<void> _generate() async {
    setState(() { _loading = true; _localError = null; });
    try {
      final example = await ref.read(cardRepoProvider).generateExample(cardId: widget.card.id);
      ref.read(sessionDetailControllerProvider(widget.card.sessionId).notifier)
         .setExampleFor(widget.card.id, example);
    } catch (e) {
      setState(() => _localError = 'Não foi possível gerar exemplo');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final example = widget.card.exampleSentence;
    if (example == null) {
      return _SectionCard(
        label: 'FRASE EXEMPLO',
        accent: AppColors.tertiary,
        value: Row(children: [
          if (_loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          if (!_loading)
            TextButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Gerar frase de exemplo'),
            ),
          if (_localError != null) Text(_localError!, style: TextStyle(color: AppColors.error)),
        ]),
      );
    }
    return _SectionCard(
      label: 'FRASE EXEMPLO',
      accent: AppColors.tertiary,
      value: Text(example, style: AppText.subhead.copyWith(fontStyle: FontStyle.italic)),
      footer: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _loading ? null : _generate,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Regerar'),
        ),
      ),
    );
  }
}
```

## Erros conhecidos
- `Gemini API tem custo por chamada` (ver server CLAUDE.md). Não chamar em
  loop automático. Botão sempre exige tap do usuário.

## Verificação manual
- Em uma sessão com card sem `example_sentence`, abrir `CardDetailSheet`,
  tocar "Gerar": <5s frase aparece.
- Tocar "Regerar": nova frase substitui a anterior.
