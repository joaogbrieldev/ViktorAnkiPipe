# Feature: Anki Export

## Objetivo
Baixar o `.apkg` da sessão via `GET /sessions/{id}/export` e abrir o
share sheet do SO para o usuário enviar ao app Anki (ou salvar/AirDrop).

## Escopo
- Botão "Exportar" no `SessionDetailScreen` (header ou row de ações).
- Tap → chama `ApiClient.getBytes('/sessions/{id}/export', timeout: 60s)`.
- Mostra `LinearProgressIndicator` no header durante o download.
- Salva bytes em `path_provider.getApplicationDocumentsDirectory()` como
  `{slug(session.name)}.apkg`.
- Chama `Share.shareXFiles([XFile(path)])` (do `share_plus`) com texto
  sugerido "Importe no Anki".
- Em erro: snackbar com "Tentar novamente".
- Não bloqueia a UI: usuário pode cancelar tocando fora do progresso
  (cancela a operação, deleta o arquivo parcial se houver).

## Fora do escopo
- Sincronização com AnkiWeb (a chip "Synced with Anki Web" do design fica
  como indicador estático do último export local).
- Importar `.apkg` de volta para revisão dentro do app.

## Critérios de aceitação
1. Tap em "Exportar" inicia download.
2. Em <10s para um deck de até 200 cards, share sheet abre com `.apkg` anexado.
3. Sucesso atualiza chip "● Exportado às HH:MM" no detalhe.
4. Erro mostra snackbar e mantém a chip anterior.
5. O `.apkg` aberto no Anki Desktop:
   - importa sem erros;
   - cria/atualiza deck com `model_id` constante (validação do servidor);
   - cards têm front (palavra), back (tradução + exemplo + contexto).
6. Re-exportar com mesmo session_id sobrescreve o arquivo local.

## Dependências
- Foundation, Session-detail.
- Backend rodando com `GET /sessions/{id}/export` implementado (M5 do server
  — verificar próximo passo #4 e #5 do server roadmap).

## Design de referência
Chip "● Synced with Anki Web" no design da lista de sessões. Adaptar
copy/cor:
- azul piscando enquanto exporta;
- verde "Exportado às HH:MM" depois;
- vermelho "Falha — tentar novamente" em erro.
