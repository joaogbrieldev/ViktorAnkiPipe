# Feature: Session Detail (lista de cards)

## Objetivo
Tela de detalhe de uma sessão acessada via `/sessions/:id`. Exibe os cards
existentes, permite deletar, e expõe ações: ir para câmera (com session
ativa), gerar frase exemplo e exportar `.apkg`.

## Escopo
- `SessionDetailScreen` em `/sessions/:id` (já dentro do shell).
- Header: GlassAppBar com botão "voltar", título = `session.name`,
  subtítulo = `session.source` se houver.
- Headline com nome da sessão + chip "X cards".
- Botões de ação grandes em row: "Scan +" (vai para `/scan` com
  `activeSessionProvider = this.id`) e "Exportar `.apkg`" (M5).
- Lista agrupada (estilo iOS grouped list) dos cards:
  - leading: ícone genérico (`Icons.style`);
  - title: `sourceText`;
  - subtitle: `translatedText`;
  - trailing: chevron;
  - tap: abre `CardDetailSheet` (bottom sheet com source/translated/context
    + frase exemplo + botão "Gerar exemplo" se vazio + botão deletar).
- Swipe-left em card: deletar com confirmação.
- Pull-to-refresh.

## Fora do escopo
- Edição inline de card.
- Reordenação manual.

## Critérios de aceitação
1. Tocando em uma sessão da lista, abre `/sessions/:id` com header correto.
2. Cards carregam via `GET /sessions/:id` (que retorna detalhes + cards).
3. Lista vazia: ilustração "Use a câmera para adicionar cards".
4. Botão "Scan +" navega para `/scan` e seta `activeSessionProvider`.
5. Tap em card abre sheet com info do card e botão "Gerar exemplo".
6. Swipe-delete remove o card otimisticamente.
7. Pull-to-refresh recarrega.

## Dependências
- Foundation, Sessions, Translation-result, AI-example (para o botão de
  gerar exemplo).

## Design de referência
Sem tela própria no Stitch — derivar do estilo de "Lista de Sessões":
mesma grouped list (radius 16, dividers, 44px tap targets), mesma
GlassAppBar, mesmo headline 28px.
