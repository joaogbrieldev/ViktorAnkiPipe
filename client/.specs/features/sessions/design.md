# Design: Sessions

## Camadas

### DTO (`lib/data/dto/session_dto.dart`)
```dart
class SessionDto {
  final String id;
  final String name;
  final String? source;
  final int cardCount;       // backend retorna count agregado em GET /sessions
  final DateTime createdAt;

  factory SessionDto.fromJson(Map<String, dynamic> json) => SessionDto(
    id: json['id'] as String,
    name: json['name'] as String,
    source: json['source'] as String?,
    cardCount: (json['card_count'] ?? 0) as int,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toCreateBody() => {
    'name': name,
    if (source != null) 'source': source,
  };
}
```

> Confirmar com o backend se `GET /sessions` retorna `card_count` agregado.
> Se não retornar, ajustar para chamar `GET /sessions/{id}` por linha (cara) ou
> aceitar mostrar "—" no MVP.

### Repository (`lib/data/repositories/session_repository.dart`)
```dart
class SessionRepository {
  SessionRepository(this._api);
  final ApiClient _api;

  Future<List<SessionDto>> list({String? source}) async {
    final qp = source != null ? '?source=${Uri.encodeQueryComponent(source)}' : '';
    final res = await _api.getJson('/sessions$qp');
    return (res['items'] as List).map((j) => SessionDto.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<SessionDto> create({required String name, String? source}) async {
    final res = await _api.postJson('/sessions', {'name': name, if (source != null) 'source': source});
    return SessionDto.fromJson(res);
  }

  Future<void> delete(String id) => _api.delete('/sessions/$id');
}

final sessionRepoProvider = Provider((ref) => SessionRepository(ref.read(apiClientProvider)));
```

### State notifier (`lib/features/sessions/application/sessions_controller.dart`)
```dart
final sessionsControllerProvider =
    AsyncNotifierProvider<SessionsController, List<SessionDto>>(SessionsController.new);

class SessionsController extends AsyncNotifier<List<SessionDto>> {
  @override
  Future<List<SessionDto>> build() => ref.read(sessionRepoProvider).list();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(sessionRepoProvider).list());
  }

  Future<void> create({required String name, String? source}) async {
    final current = state.valueOrNull ?? [];
    // optimistic: inserir placeholder no topo, substituir após sucesso
    final repo = ref.read(sessionRepoProvider);
    try {
      final created = await repo.create(name: name, source: source);
      state = AsyncValue.data([created, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;  // sheet exibe erro
    }
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((s) => s.id != id).toList());  // otimista
    try {
      await ref.read(sessionRepoProvider).delete(id);
    } catch (e) {
      state = AsyncValue.data(current);  // rollback
      rethrow;
    }
  }
}
```

## Tela `SessionsListScreen`

Estrutura:
```
Scaffold(
  body: CustomScrollView(
    slivers: [
      SliverAppBar — GlassAppBar (sticky)
        ├── leading: IconButton(Icons.menu)        // futuro: drawer
        ├── title: 'ViktorAnkiPipe' (primary, nav-title)
        └── actions: [add, sync]
      SliverPadding(margin-main)(
        SliverList: [
          headline "Sessions" (28px bold),
          SizedBox 12,
          SearchField (radius 8, surface-container-highest/50),
          SizedBox 24,
          GroupedListCard(  // radius 16
            children: filtered sessions → SessionTile,
          ),
          SizedBox 24,
          SyncStatusChip(),  // M5 visível
        ],
      ),
    ],
  ),
  floatingActionButton: null,  // o '+' está no header
)
```

### `SessionTile`
- 44px min altura, padding `(16, 12)`.
- 48×48 ícone leading com `primary-container/10` ou `secondary-container/10`
  (rotacionar pela hash do id ou pelo source heuristic).
- Title: `name` (subhead, on-surface), `maxLines: 1`, ellipsis.
- Subtitle: `${formatDate(createdAt)} • ${cardCount} cards` (footnote, on-surface-variant).
- Trailing: `Icon(Icons.chevron_right, color: outlineVariant)`.
- `Dismissible` envolve o tile (background vermelho com ícone delete).
- Tap → `context.push('/sessions/${session.id}')`.

### `NewSessionSheet` (bottom sheet)
- `showModalBottomSheet(useSafeArea: true, isScrollControlled: true, ...)`.
- Form com `nameController` e `sourceController`.
- Botão `PrimaryButton` cheio "Criar" desabilita quando `name.trim().isEmpty`.
- Mostra `CircularProgressIndicator` enquanto `isSubmitting`.
- Em erro: `SnackBar` na própria sheet.
- Foco automático em `nameController` ao abrir.

### Busca
Estado local da tela:
```dart
final searchQuery = useState('');
final visibleSessions = sessions.where((s) => s.name.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
```
(Sem debounce — filtro é local e a lista é pequena.)

### Ícone por source (heurística simples)
```dart
IconData iconForSource(String? source) {
  final s = source?.toLowerCase() ?? '';
  if (s.contains('news') || s.contains('times') || s.contains('jornal')) return Icons.newspaper;
  if (s.contains('book') || s.contains('chapter') || s.contains('livro') || s.contains('cap')) return Icons.menu_book;
  if (s.contains('journal') || s.contains('paper')) return Icons.history_edu;
  if (s.isNotEmpty) return Icons.article;
  return Icons.description;
}
```

## Erros e estados

| Estado          | UI                                                                         |
| --------------- | -------------------------------------------------------------------------- |
| Loading inicial | `CircularProgressIndicator` centralizado                                   |
| Lista vazia     | Ilustração (placeholder ícone), texto "Sem sessões ainda", CTA "Criar"     |
| Erro de rede    | `ErrorView` com texto e botão "Tentar novamente" que chama `refresh()`     |
| Após criar      | Lista atualizada otimisticamente; rollback em caso de erro                 |

## Testes

- `test/features/sessions/sessions_controller_test.dart`:
  - mock `SessionRepository`, valida `list()`/`create()`/`delete()`
    com otimismo + rollback.
- `test/features/sessions/sessions_screen_test.dart` (widget):
  - render com lista mockada exibe N tiles com nome.
  - tap em "+" abre sheet.
  - tap em "Criar" com nome vazio fica desabilitado.
  - swipe revela botão deletar.

## Verificação manual
- Criar sessão "Test 1" com source "Harry Potter": aparece no topo com ícone book.
- Criar sessão "Test 2" sem source: aparece com ícone description.
- Buscar "Test": ambas aparecem; buscar "Harry": só Test 1.
- Pull-to-refresh: lista é refetched.
- Swipe-delete em "Test 2": confirma e some.
