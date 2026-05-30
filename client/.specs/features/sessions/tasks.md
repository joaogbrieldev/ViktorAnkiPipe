# Tasks: Sessions

> Cada tarefa é atômica e verificável em isolamento.

## Data layer

- [ ] **S-01** Criar `lib/data/dto/session_dto.dart` com classe `SessionDto`,
       `fromJson` e `toCreateBody`.
  - Verificação: teste unitário `SessionDto.fromJson({...})` retorna campos
    corretos; data inválida lança `FormatException`.
- [ ] **S-02** Confirmar com o backend se `GET /sessions` retorna `card_count`
       no payload. Se não retornar, abrir issue e usar `null`/`0` no DTO.
  - Verificação: chamada `curl http://localhost:8000/sessions` mostra o campo.
- [ ] **S-03** Criar `lib/data/repositories/session_repository.dart` com
       métodos `list`, `create`, `delete`.
  - Verificação: teste com `mocktail` cobrindo 200, 404, 500.

## State

- [ ] **S-04** Criar `lib/features/sessions/application/sessions_controller.dart`
       com `AsyncNotifier` e métodos `refresh`, `create`, `delete`.
  - Verificação: teste com `ProviderContainer` cobre fluxos otimistas + rollback.

## UI

- [ ] **S-05** Criar `lib/features/sessions/presentation/sessions_list_screen.dart`
       substituindo o placeholder do M0.
- [ ] **S-06** Implementar `GlassAppBar` na tela (reutilizando widget do M0)
       com menu/título/add/sync.
- [ ] **S-07** Implementar headline "Sessions" + `SearchField`.
- [ ] **S-08** Criar widget `SessionTile` em `widgets/session_tile.dart`.
- [ ] **S-09** Wrap `SessionTile` com `Dismissible` para swipe-delete +
       `AlertDialog` de confirmação.
- [ ] **S-10** Criar `NewSessionSheet` em `widgets/new_session_sheet.dart`
       (form + submit).
- [ ] **S-11** Wire-up: `+` do header chama `showModalBottomSheet`.
- [ ] **S-12** Estado de busca local (`useState` ou `StateProvider`) + filtro.
- [ ] **S-13** `RefreshIndicator` envolvendo o `CustomScrollView`.
- [ ] **S-14** Estados de loading / erro / vazio (componentes próprios em
       `widgets/`).

## Testes

- [ ] **S-15** `test/features/sessions/sessions_screen_test.dart`:
  - renderiza lista mockada;
  - "+" abre sheet;
  - submeter sheet chama `create`;
  - swipe revela ação delete.
- [ ] **S-16** Cobertura ≥ 80% no módulo sessions
       (`flutter test --coverage`).

## Verificação manual

- [ ] **S-17** Com backend up, criar duas sessões via API e abrir o app:
       aparecem listadas.
- [ ] **S-18** Criar via app → aparece no topo.
- [ ] **S-19** Deletar via swipe → some.
- [ ] **S-20** Cortar backend: pull-to-refresh mostra erro com retry.

## Dependências
- Depende de **F-14** (`ApiClient`), **F-15..F-17** (router/shell),
  **F-19..F-21** (widgets base).
- Bloqueia [session-detail](../session-detail/spec.md) — tap em tile precisa
  de rota destino real em M4.
