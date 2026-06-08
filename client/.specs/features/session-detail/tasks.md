# Tasks: Session Detail

## Data

- [x] **SD-01** `lib/data/dto/session_detail_dto.dart`.
- [x] **SD-02** Adicionar `SessionRepository.getById(id)`.

## State

- [x] **SD-03** `SessionDetailController` (FamilyAsyncNotifier) com refresh,
       deleteCard, setExampleFor.

## UI

- [x] **SD-04** `SessionDetailScreen` em
       `lib/features/session_detail/presentation/session_detail_screen.dart`.
- [x] **SD-05** Widget `_Header` (headline + chips + ações).
- [x] **SD-06** `CardTile` (em `widgets/card_tile.dart`) com swipe-delete.
- [x] **SD-07** `CardDetailSheet` (reutiliza `_SectionCard`).
- [x] **SD-08** Botão "Scan +" seta `activeSessionProvider` e empurra `/scan`.
- [x] **SD-09** Após voltar de `/result`, invalidar `sessionDetailControllerProvider(id)`
       para recarregar (ou usar listener no provider).

## Testes

- [x] **SD-10** Unit test do controller.
- [x] **SD-11** Widget test da tela.

## Verificação manual

- [ ] **SD-12** Criar uma sessão, abrir detalhe, ir para Scan, adicionar
       1 card, voltar: card aparece.
- [ ] **SD-13** Swipe em card → confirma → some.

## Dependências
- Foundation, Sessions, Translation-result, AI-example (botão de gerar
  exemplo).
