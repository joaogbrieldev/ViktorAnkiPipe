# Feature: AI Example Generation

## Objetivo
Permitir gerar uma frase de exemplo em inglês para um card específico,
usando o endpoint `POST /cards/{card_id}/example` (que internamente chama
Gemini 2.5 Flash).

## Escopo
- Botão "Gerar frase de exemplo" no `CardDetailSheet` quando
  `card.exampleSentence == null`.
- Tap → estado de loading no botão por ~1–3s.
- Em sucesso: atualiza o card no `SessionDetailController` (via
  `setExampleFor`) e mostra a frase no card "Frase exemplo".
- Em erro: snackbar com retry.
- Se a frase já existe: mostrar com botão pequeno "Regerar" ao lado.

## Fora do escopo
- Cachear exemplos localmente (servidor não cacheia; cada toque gera nova frase).
- Edição manual da frase.
- Múltiplos exemplos por card.

## Critérios de aceitação
1. Tap em "Gerar frase" inicia loading.
2. Em <5s mostra a frase real do servidor.
3. Frase aparece em `_SectionCard` "FRASE EXEMPLO" com label tertiary.
4. "Regerar" sobrepõe a frase atual após confirmação implícita.
5. Em erro 500 do servidor: snackbar "Não foi possível gerar exemplo" + retry.

## Dependências
- Foundation, Session-detail (que hospeda o botão).
- Backend rodando com `GEMINI_API_KEY` configurado.

## Design de referência
Reutiliza `_SectionCard` da translation-result. Label "FRASE EXEMPLO" em
`tertiary` (`#9E3D00`), value em on-surface italic.
