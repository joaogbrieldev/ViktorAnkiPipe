# State — memória entre sessões

## Status atual
**M0 / Foundation concluído em 2026-05-28.** Todas as tasks F-01 a F-27 verificadas.
F-28 (flutter run em dispositivo real) requer verificação manual.

Próximo passo: **M1 — Sessions** (lista, criar, deletar, buscar).
Ver [features/sessions/tasks.md](../features/sessions/tasks.md).

## Decisões registradas
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
