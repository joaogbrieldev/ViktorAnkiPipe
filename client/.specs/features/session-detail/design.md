# Design: Session Detail

## DTOs

`SessionDetailDto` em `lib/data/dto/session_detail_dto.dart`:
```dart
class SessionDetailDto {
  final SessionDto session;
  final List<CardDto> cards;
  factory SessionDetailDto.fromJson(Map<String, dynamic> j) => SessionDetailDto(
    session: SessionDto.fromJson(j),  // os campos top-level já são da sessão
    cards: (j['cards'] as List).map((c) => CardDto.fromJson(c as Map<String, dynamic>)).toList(),
  );
}
```

Adicionar ao `SessionRepository`:
```dart
Future<SessionDetailDto> getById(String id) async {
  final res = await _api.getJson('/sessions/$id');
  return SessionDetailDto.fromJson(res);
}
```

## State

`lib/features/session_detail/application/session_detail_controller.dart`:
```dart
final sessionDetailControllerProvider = AsyncNotifierProviderFamily<
    SessionDetailController, SessionDetailDto, String>(SessionDetailController.new);

class SessionDetailController extends FamilyAsyncNotifier<SessionDetailDto, String> {
  @override
  Future<SessionDetailDto> build(String id) => ref.read(sessionRepoProvider).getById(id);

  Future<void> deleteCard(String cardId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(SessionDetailDto(
      session: current.session,
      cards: current.cards.where((c) => c.id != cardId).toList(),
    ));
    try {
      await ref.read(cardRepoProvider).delete(sessionId: arg, cardId: cardId);
    } catch (_) {
      state = AsyncValue.data(current); rethrow;
    }
  }

  Future<void> setExampleFor(String cardId, String example) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(SessionDetailDto(
      session: current.session,
      cards: current.cards.map((c) => c.id == cardId ? c.copyWith(exampleSentence: example) : c).toList(),
    ));
  }
}
```

## UI

### `SessionDetailScreen`
```
CustomScrollView(
  slivers: [
    GlassAppBar(
      leading: BackButton, 
      title: session.name (truncated), 
      actions: [ExportButton (visible at M5)],
    ),
    SliverToBoxAdapter(child: _Header(session)),    // headline + chip + ações
    SliverPadding(
      sliver: SliverList.builder(
        itemBuilder: (_, i) => CardTile(card: cards[i], onTap: ..., onDelete: ...),
      ),
    ),
    SliverSafeArea(...),
  ],
);
```

### `_Header`
- Padding `(margin-main, top: stack-md)`.
- Column:
  - Text(session.name, headline-lg-mobile, bold).
  - if (session.source != null) Text(session.source, subhead, on-surface-variant).
  - SizedBox(12).
  - Row(spacing: 8, children: [
      _Chip(label: '${cards.length} cards', icon: Icons.style),
      _Chip(label: formatDate(session.createdAt), icon: Icons.calendar_today),
    ]).
  - SizedBox(16).
  - Row(spacing: 12, children: [
      Expanded(child: PrimaryButton(label: 'Scan +', icon: photo_camera, onPressed: () { ref.read(activeSessionProvider.notifier).state = session.id; context.push('/scan'); })),
      Expanded(child: SecondaryButton(label: 'Exportar', icon: download, onPressed: _onExport)),  // M5
    ]).

### `CardTile`
- Reutiliza visual de `SessionTile` (44px row, leading icon, title/subtitle,
  chevron).
- `leading`: `Icons.style` color secondary.
- `title`: `sourceText`.
- `subtitle`: `translatedText`.

### `CardDetailSheet`
Bottom sheet (`showModalBottomSheet`, `isScrollControlled: true`) com:

- handle bar.
- close X.
- Section cards (`_SectionCard` reutilizado de translation-result):
  - "Palavra" — sourceText.
  - "Tradução" — translatedText.
  - "Contexto" — context (com palavra em destaque).
  - "Frase exemplo" — exampleSentence se existir; senão, button
    "Gerar frase de exemplo" (M4 via `ai-example` feature).
- bottom action: `OutlinedButton.icon('Deletar card', delete)` em vermelho.

## Testes

- Unit do controller (delete otimista, refresh).
- Widget test da tela com session mockada.

## Verificação manual
- Tap em sessão da lista → abre detalhe.
- "Scan +" navega para câmera com session ativa; ao adicionar um card,
  ao voltar, o card aparece (após refresh manual ou auto via
  `invalidate` do controller).
