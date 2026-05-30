# Feature: Sessions (Lista, Criar, Deletar)

## Objetivo
Tela "Lista de Sessões" funcional. Usuário vê todas as sessões existentes
no backend, busca por nome, cria uma nova, deleta com swipe.

## Escopo
- Tela `SessionsListScreen` em `/sessions`.
- Carregar lista do backend (`GET /sessions`) ao montar e em pull-to-refresh.
- Busca local sobre a lista carregada (filtro client-side).
- Botão `+` na app bar → bottom sheet de criação (campo nome + source opcional).
- Submit chama `POST /sessions` e adiciona ao topo da lista.
- Swipe horizontal em um item → "Deletar" com confirmação → `DELETE /sessions/{id}`.
- Toque em item → navega para `/sessions/:id` (placeholder por enquanto se M4
  ainda não estiver pronto).
- Estado vazio: ilustração + texto "Crie sua primeira sessão" + CTA.
- Estado de erro: snack bar com botão "Tentar novamente".

## Fora do escopo
- Detalhe da sessão / cards — feature [session-detail](../session-detail/spec.md).
- Editar nome/source de sessão existente.
- Filtros por `source` no servidor (deixar local por enquanto).

## Critérios de aceitação
1. App abre direto em `/sessions` (rota inicial).
2. Com backend rodando em `localhost:8000` e duas sessões cadastradas via API,
   o app exibe as duas linhas com nome, "X cards" e data formatada.
3. Pull-to-refresh dispara novo `GET /sessions`.
4. Tocar em `+` abre um sheet modal (page sheet style, 90% da altura) com
   `TextField` para `name` (obrigatório) e `source` (opcional). Botão
   "Criar" desabilita quando `name.trim().isEmpty`.
5. Submeter cria a sessão no backend e ela aparece imediatamente no topo
   da lista (estado otimista, com rollback se POST falhar).
6. Swipe-left em um item revela botão "Deletar" vermelho. Confirmar deleta
   server-side e remove da lista.
7. Loading e erro são visualmente distintos do estado vazio.
8. Campo de busca filtra a lista por substring case-insensitive em `name`.
9. Tile mostra ícone diferente conforme `source`: livro (`menu_book`), jornal
   (`newspaper`), artigo (`article`), default (`description`). Heurística
   simples: keyword no source.

## Dependências
- Foundation completa (theme, router, ApiClient).
- Backend rodando.

## Design de referência
[`client/design/01-sessions.png`](../../../client/design/01-sessions.png).
HTML em [`client/design/01-sessions.html`](../../../client/design/01-sessions.html).

Elementos visuais a preservar:
- Header sticky com blur, título "ViktorAnkiPipe" centralizado em primary,
  botões menu (esquerda), `+` e `sync` (direita).
- Headline "Sessions" 28px bold à esquerda, margin 16.
- Input de busca cinza claro com ícone, radius 8.
- Grouped list card branca (radius 16) com itens 44px de altura, divider
  fino alinhado ao texto (não toca a borda esquerda).
- Chip "● Synced with Anki Web" (rotativo: pode ser ocultado em MVP se não
  estamos implementando sync — usar como indicador de status da última
  exportação local em M5).
