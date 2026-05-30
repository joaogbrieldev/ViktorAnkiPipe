# Tasks: Session Detail

## Data

- [ ] **SD-01** `lib/data/dto/session_detail_dto.dart`.
- [ ] **SD-02** Adicionar `SessionRepository.getById(id)`.

## State

- [ ] **SD-03** `SessionDetailController` (FamilyAsyncNotifier) com refresh,
       deleteCard, setExampleFor.

## UI

- [ ] **SD-04** `SessionDetailScreen` em
       `lib/features/session_detail/presentation/session_detail_screen.dart`.
- [ ] **SD-05** Widget `_Header` (headline + chips + ações).
- [ ] **SD-06** `CardTile` (em `widgets/card_tile.dart`) com swipe-delete.
- [ ] **SD-07** `CardDetailSheet` (reutiliza `_SectionCard`).
- [ ] **SD-08** Botão "Scan +" seta `activeSessionProvider` e empurra `/scan`.
- [ ] **SD-09** Após voltar de `/result`, invalidar `sessionDetailControllerProvider(id)`
       para recarregar (ou usar listener no provider).

## Testes

- [ ] **SD-10** Unit test do controller.
- [ ] **SD-11** Widget test da tela.

## Verificação manual

- [ ] **SD-12** Criar uma sessão, abrir detalhe, ir para Scan, adicionar
       1 card, voltar: card aparece.
- [ ] **SD-13** Swipe em card → confirma → some.

## Dependências
- Foundation, Sessions, Translation-result, AI-example (botão de gerar
  exemplo).
