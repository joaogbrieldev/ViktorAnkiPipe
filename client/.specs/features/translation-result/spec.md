# Feature: Translation Result + Card Add

## Objetivo
Mostrar a tradução de uma palavra selecionada na tela de câmera, com a
frase original de contexto, e permitir adicionar como card a uma sessão.

## Escopo
- Tela `TranslationResultScreen` em `/result` (push fullscreen).
- Lê `pendingTranslationProvider` (definido pela câmera) → `WordSelection`.
- Dispara translation request ao montar:
  - se houver `activeSessionProvider`: chama
    `POST /sessions/{id}/cards` com `[{source_text, context}]` direto
    (cria card + retorna o card hidratado);
  - senão: chama `POST /translate` (não cria card, só traduz).
- Mostra background com a foto congelada da câmera (faz mock se vier sem foto).
- Bottom sheet draggable com:
  - título "Resultado" 28px + subtítulo "Detectado: Inglês para Português";
  - botão close (X);
  - card "Termo Selecionado" (primary).
  - card "Tradução" (tertiary).
  - card "Contexto no Livro" (on-surface, com a palavra original em
    sublinhado primary).
- CTA fixo no rodapé "Adicionar ao deck" → confirma o card e fecha.
- Se a tradução vier de `POST /translate` (sem session ativa), o CTA muda
  para "Escolher sessão" que abre o picker e então persiste via batch.

## Fora do escopo
- Editar a tradução manualmente.
- Sugestões alternativas / múltiplos significados (LibreTranslate retorna
  uma string única; futuras versões podem listar variantes).
- Frase de exemplo gerada por IA aqui — isso vive na feature
  [ai-example](../ai-example/spec.md), disparada na lista de cards.

## Critérios de aceitação
1. Tocar em uma palavra em `/scan` empurra `/result`.
2. Ao montar, mostra skeleton de loading nos 3 cards (shimmer ou bullets).
3. Em <2s exibe tradução real (cache Redis no servidor garante isso).
4. "Termo Selecionado" exibe a palavra original detectada.
5. "Tradução" mostra a string PT-BR.
6. "Contexto no Livro" mostra a `contextLine` (linha completa do OCR) com
   a palavra original em destaque (primary, underline 30% opacity).
7. Se `activeSessionProvider == null`: o tap em "Adicionar" abre um sheet
   com lista de sessões + opção "Criar nova sessão" rápida.
8. Após persistir card: pop da tela com snackbar "Card adicionado".
9. Em erro de rede: cards mostram erro, com retry no card específico.
10. Sheet é arrastável; tap no fundo (foto) fecha-o (volta para câmera).

## Dependências
- Foundation, Camera+OCR, Sessions.
- Backend rodando.

## Design de referência
[`client/design/03-result.png`](../../../client/design/03-result.png).
HTML em [`client/design/03-result.html`](../../../client/design/03-result.html).

Elementos visuais a preservar:
- Foto de fundo com `ocr-highlight` boxes sobrepostas (mostrando onde
  a palavra apareceu).
- Bottom sheet branco com radius 20 (top) e blur (`ios-blur`).
- Handle bar (40×6, on-surface-variant/20, rounded full).
- Headline "Resultado" 28px bold, footnote "Detectado: Inglês para Português".
- 3 cards (surface-container-low / `#f4f3f8`) em coluna com spacing 12.
- Botão "Adicionar ao deck" full-width primary 56px, radius 12,
  com gradient mask de fade no topo (`from-white via-white/90 to-transparent`).
