# Tasks: Translation Result

## Data

- [ ] **R-01** Criar `lib/data/dto/card_dto.dart` com `CardDto` e `CardCreateBody`.
- [ ] **R-02** Criar `lib/data/repositories/card_repository.dart`
       (`addBatch`, `delete`, `generateExample`).
- [ ] **R-03** Criar `lib/data/repositories/translate_repository.dart`
       (`translate`).
- [ ] **R-04** Providers Riverpod para ambos os repositories.

## State

- [ ] **R-05** `TranslationState` em
       `lib/features/translation_result/application/translation_state.dart`.
- [ ] **R-06** `TranslationController` (StateNotifier) com `fetch` +
       `addToSession`.

## UI

- [ ] **R-07** Criar `TranslationResultScreen` em
       `lib/features/translation_result/presentation/translation_result_screen.dart`.
- [ ] **R-08** Implementar `_BackgroundImage` (foto congelada da câmera +
       overlay de bounding boxes mockados de contexto).
- [ ] **R-09** Implementar `DraggableScrollableSheet` com handle bar e
       layout do sheet.
- [ ] **R-10** Implementar `_SectionCard` reutilizável.
- [ ] **R-11** Implementar destaque do contexto via `RichText`.
- [ ] **R-12** Implementar CTA "Adicionar ao deck" com loading inline.
- [ ] **R-13** Implementar `_SessionPickerSheet` (reusa
       `sessionsControllerProvider`). Inclui "Criar sessão rápida"
       que chama `SessionsController.create()` e seleciona automaticamente.
- [ ] **R-14** Após sucesso: `context.pop()` e mostrar `SnackBar` na tela
       anterior via `Future.microtask`.

## Routing

- [ ] **R-15** Registrar rota `/result` (fora do shell, fullscreen) em
       `app_router.dart` com `extra` opcional.
- [ ] **R-16** Camera `_OcrTokens.onTap` empurra `/result`.

## Testes

- [ ] **R-17** Unit test do `TranslationController`.
- [ ] **R-18** Widget test do `TranslationResultScreen` com providers
       mockados (verifica 3 cards e CTA).

## Verificação manual

- [ ] **R-19** Fluxo end-to-end com backend rodando: scan → palavra → tradução
       em <2s → adicionar → pop com snackbar.
- [ ] **R-20** Erro de rede: cada card mostra estado de erro independente.
- [ ] **R-21** Sem sessão ativa: picker aparece e funciona.

## Dependências
- Foundation, Sessions, Camera+OCR.
- Bloqueia [session-detail](../session-detail/spec.md) (que mostra cards
  criados aqui).
