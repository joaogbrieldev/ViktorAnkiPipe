# Design: Translation Result

## Camadas

### DTO (`lib/data/dto/card_dto.dart`)
```dart
class CardDto {
  final String id;
  final String sessionId;
  final String sourceText;
  final String translatedText;
  final String? context;
  final String? exampleSentence;
  final DateTime createdAt;
  factory CardDto.fromJson(Map<String, dynamic> j) => ...;
}

class CardCreateBody {
  final String sourceText;
  final String? context;
  Map<String, dynamic> toJson() => {
    'source_text': sourceText,
    if (context != null) 'context': context,
  };
}
```

### Repository (`lib/data/repositories/card_repository.dart`)
```dart
class CardRepository {
  CardRepository(this._api);
  final ApiClient _api;

  Future<List<CardDto>> addBatch({required String sessionId, required List<CardCreateBody> items}) async {
    final res = await _api.postJson('/sessions/$sessionId/cards', {'items': items.map((i) => i.toJson()).toList()});
    return (res['items'] as List).map((j) => CardDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> delete({required String sessionId, required String cardId}) =>
      _api.delete('/sessions/$sessionId/cards/$cardId');

  Future<String> generateExample({required String cardId}) async {
    final res = await _api.postJson('/cards/$cardId/example', const {});
    return res['example_sentence'] as String;
  }
}

class TranslateRepository {
  TranslateRepository(this._api);
  final ApiClient _api;
  Future<String> translate(String text) async {
    final res = await _api.postJson('/translate', {'q': text});
    return res['translated_text'] as String;
  }
}
```

### Controller
`lib/features/translation_result/application/translation_controller.dart`:
```dart
class TranslationState {
  final WordSelection selection;
  final AsyncValue<String> translation;     // string traduzida
  final AsyncValue<CardDto?> card;          // null = not added; non-null = added
}

class TranslationController extends StateNotifier<TranslationState> {
  TranslationController(this._cards, this._translate, WordSelection sel)
    : super(TranslationState(selection: sel, translation: const AsyncValue.loading(), card: const AsyncValue.data(null)));

  Future<void> fetch() async {
    state = state.copyWith(translation: const AsyncValue.loading());
    try {
      final txt = await _translate.translate(state.selection.word);
      state = state.copyWith(translation: AsyncValue.data(txt));
    } catch (e, st) {
      state = state.copyWith(translation: AsyncValue.error(e, st));
    }
  }

  Future<void> addToSession(String sessionId) async {
    state = state.copyWith(card: const AsyncValue.loading());
    try {
      final created = await _cards.addBatch(
        sessionId: sessionId,
        items: [CardCreateBody(sourceText: state.selection.word, context: state.selection.contextLine)],
      );
      state = state.copyWith(card: AsyncValue.data(created.first));
    } catch (e, st) {
      state = state.copyWith(card: AsyncValue.error(e, st));
    }
  }
}
```

## UI

### Layout

```
Scaffold(
  body: Stack(
    children: [
      Positioned.fill(child: _BackgroundImage(selection)), // foto congelada
      Positioned.fill(child: _DimOverlay()),                // black/30
      Align(alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          builder: (ctx, scroll) => _ResultSheet(scrollController: scroll),
        ),
      ),
    ],
  ),
);
```

### `_ResultSheet`
- Container branco, radius `(top: 20)`, com `ClipRRect` para o blur.
- `Padding(margin-main)`:
  - handle bar (40×6, central, surface-variant);
  - row: headline "Resultado" + subtitle + close X (lado direito);
  - `Column(spacing: AppSpacing.md, children: [
      _SectionCard(label: 'TERMO SELECIONADO', value: word, accent: primary),
      _SectionCard(label: 'TRADUÇÃO', value: translation, accent: tertiary, footer: notes),
      _SectionCard(label: 'CONTEXTO NO LIVRO', value: contextWithHighlight, accent: on-surface-variant),
    ])`;
  - flex Spacer;
  - bottom CTA `PrimaryButton(label: 'Adicionar ao deck', leadingIcon: Icons.add_box)`.

### `_SectionCard`
```dart
class _SectionCard extends StatelessWidget {
  final String label;   // CAPS pequeno
  final Widget value;
  final Color accent;
  final Widget? footer;
  @override
  Widget build(...) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F3F8),  // surface-container-low
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(crossAxisAlignment: start, children: [
      Text(label, style: AppText.labelCaps.copyWith(color: accent, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      value,
      if (footer != null) ...[const SizedBox(height: 4), footer!],
    ]),
  );
}
```

### Highlight do contexto
```dart
TextSpan(
  text: line,
  children: [
    for (final segment in splitAroundWord(line, word))
      if (segment == word)
        TextSpan(text: segment, style: AppText.subhead.copyWith(
          color: AppColors.primary, fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary.withOpacity(0.3),
        ))
      else
        TextSpan(text: segment, style: AppText.subhead.copyWith(color: AppColors.onSurface)),
  ],
);
```

### CTA `Adicionar ao deck`
- Se `activeSessionProvider == null` ao tocar:
  - abre `_SessionPickerSheet` que lista sessions (reusando `SessionsController`)
    + opção "Criar sessão rápida";
  - depois chama `controller.addToSession(picked.id)`.
- Se sessão ativa: chama direto.
- Botão fica `loading` enquanto card está sendo persistido (não permite duplo
  tap).
- Sucesso → `context.pop()` + `ScaffoldMessenger.showSnackBar(SnackBar(...))`
  na tela anterior.

## Testes

- `translation_controller_test.dart` — mock `TranslateRepository` e
  `CardRepository`:
  - `fetch()` popula `translation`;
  - `addToSession` cria card e atualiza estado;
  - falhas atualizam o lado correto.
- `translation_result_screen_test.dart` — renderiza com providers mockados,
  verifica que os 3 cards aparecem, CTA dispara `addToSession`.

## Verificação manual
- Da câmera, tocar em "serendipity" no contexto "It was a serendipity that…":
  - sheet aparece a 60% da altura;
  - "Termo Selecionado: serendipity";
  - "Tradução" exibe string PT-BR após latência;
  - "Contexto no Livro" mostra a linha com "serendipity" em primary underline;
  - tocar "Adicionar ao deck": se há sessão ativa → snackbar, pop;
    caso contrário, picker aparece.
