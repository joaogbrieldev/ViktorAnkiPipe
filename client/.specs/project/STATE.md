# State — memória entre sessões

## Status atual
**M5 / Anki Export concluído em 2026-06-04.**
Tasks E-01 a E-09 implementadas; E-10/11/12/13 requerem verificação manual com device e Anki.

Funcionalidades implementadas:
- `ExportService` com injeção de `getDocumentsDir`/`shareFiles` (testável sem plataforma)
- `ExportCancellation` para cancelar operação em andamento (dispose do widget ou flag)
- `ExportStatusChip` com estados idle/exporting/success/error
- `_Header` convertido para `ConsumerStatefulWidget` com `LinearProgressIndicator` durante download
- `share_plus` + `path_provider` já estavam no pubspec; nenhuma dependência nova adicionada
- 10 testes unitários cobrindo bytes gravados, slug, re-export, cancellation

Próximo passo: verificação manual E-10/E-11/E-12/E-13 (requer backend com GET /sessions/{id}/export).

## Decisões registradas
- **2026-06-01** — `TranslationController` é `StateNotifier.autoDispose` com `fetch()` +
  `addToSession()`; inicializado com `ref.read(pendingTranslationProvider)` (não watch) para
  capturar a seleção uma vez no mount. `TranslateRepository` separado de `CardRepository`
  seguindo bounded-context.
- **2026-06-01** — `WordSelection` ganhou campo `capturedImagePath` para passar o path do
  frame congelado à `TranslationResultScreen` via `pendingTranslationProvider`.
- **2026-06-01** — `_SessionPickerSheet` usa `ConsumerStatefulWidget` dentro do
  `showModalBottomSheet`; retorna o `sessionId` selecionado via `Navigator.of(context).pop(id)`.
- **2026-05-31** — Camera feature usa `StateNotifier.autoDispose` com factories injetáveis
  (camerasFactory, controllerFactory, recognizerFactory, imageSizeResolver) para testabilidade sem device real.
- **2026-05-31** — `pendingTranslationProvider` + `WordSelection` em `core/providers/` e `data/dto/`
  para consumo cruzado por translation-result (M3).
- **2026-05-31** — Coordinate mapping em `OcrTokens` usa BoxFit.cover math (scale = max(dx, dy));
  tested with a `390×693` surface via `tester.view.physicalSize`.
- **2026-05-27** — Adotado design system Stitch "Kinetic Utility"
  (iOS-inspired, primary `#007AFF`). Layout de 3 telas referenciado em
  `client/design/`.
- **2026-05-27** — Stack: Riverpod + go_router + http + ML Kit. Sem `dio`,
  sem code-gen JSON para manter atrito baixo.
- **2026-05-27** — Bottom nav: 3 tabs (Sessions / Scan / Cards). O destino
  da tab "Cards" será decidido em M4 (ver ROADMAP).
- **2026-05-28** — Foundation implementada com `StatefulShellRoute.indexedStack`
  (go_router 14.x) em vez de `ShellRoute` simples — permite manter estado de
  cada tab independentemente.
- **2026-05-28** — `ApiClient` implementado com `getJsonList` adicional para
  endpoints que retornam arrays (necessário para GET /sessions).

## Blockers
Nenhum.

## Preferences
- O usuário trabalha em PT-BR — copy de UI em PT-BR; código/identificadores
  em inglês (espelha convenção do server).
- Plano-primeiro: gerar specs/design antes de tocar em código. Para tarefas
  leves (atualizações de state, validações simples), modelos menores também
  servem bem.
