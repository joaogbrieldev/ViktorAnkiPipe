# ViktorAnkiPipe — Flutter Client

## Visão

App móvel para acelerar o estudo de vocabulário enquanto se lê em inglês.
O usuário aponta a câmera para o texto, seleciona palavras desconhecidas,
e o app produz um deck `.apkg` pronto para importar no Anki — com tradução
e frase de exemplo gerada por IA.

## Objetivos

1. **Fluxo único e rápido**: câmera → palavra → card. Menos de 5 toques por palavra.
2. **iOS-first em UX**: paradigmas iOS (grouped lists, bottom sheets, glassmorphism)
   reduzem fricção mesmo no Android. Design system: **Kinetic Utility**.
3. **Cliente burro**: toda lógica não-trivial (cache, tradução, IA, geração `.apkg`)
   vive no backend. O Flutter só captura, exibe e dispara chamadas.
4. **Sem conta, sem login**: uso pessoal/local. Base URL configurável.
5. **Offline-tolerante**: erros de rede são visíveis mas não destroem trabalho.
   Captura/seleção de palavra deve sobreviver a falhas pontuais de POST.

## Não-objetivos

- **OCR não roda no servidor.** Google ML Kit on-device, sem upload de imagem.
- **Sem multi-usuário, sem sync nuvem.** Cada device fala com um backend pessoal.
- **Sem geração de áudio/IPA no MVP.** Card Anki tem: front (palavra), back
  (tradução + frase exemplo + contexto). Pode evoluir depois.
- **Sem revisão dentro do app.** O app cria deck; revisão acontece no Anki.

## Público-alvo

Eu mesmo (proprietário) — leitor de livros físicos/digitais em inglês que estuda
vocabulário no Anki. O design system explicitamente cita "serious English learners".

## Stack alvo

| Camada       | Escolha                                  | Justificativa                                                    |
| ------------ | ---------------------------------------- | ---------------------------------------------------------------- |
| Framework    | Flutter 3.11+ (Dart SDK ^3.11.5)         | Pubspec já fixado nessa versão                                   |
| Estado       | `flutter_riverpod`                       | Testável, sem boilerplate de Bloc, escopo per-widget claro       |
| Rotas        | `go_router`                              | Declarativa, suporta deep link e tabs aninhadas (bottom nav)     |
| HTTP         | `http` + cliente fino próprio            | Backend é simples (REST JSON); evita peso do `dio`               |
| JSON         | `dart:convert` + classes manuais         | DTOs pequenos, sem code-gen                                      |
| Câmera       | `camera`                                 | Pacote oficial Flutter                                           |
| OCR          | `google_mlkit_text_recognition`          | Roda no device, latência baixa, sem chamada de rede              |
| Compartilhar | `share_plus` + `path_provider`           | Salvar `.apkg` em diretório acessível e abrir share sheet        |
| Storage      | `shared_preferences`                     | Base URL + última source de session (defaults UX)                |
| Testes       | `flutter_test` + `mocktail`              | Padrão Flutter; mocktail é o sucessor recomendado de mockito     |
| Lint         | `flutter_lints` (já no pubspec)          | Padrão do template                                               |

## Conexão com o backend

Backend documentado em [`../server/CLAUDE.md`](../../server/CLAUDE.md). Resumo:

- FastAPI, sem autenticação.
- Base URL configurável (default dev: `http://localhost:8000`).
- Endpoints relevantes ao MVP do cliente:
  - `GET /sessions`, `POST /sessions`, `GET /sessions/{id}`, `DELETE /sessions/{id}`
  - `POST /sessions/{id}/cards` (batch com `[{source_text, context?}]`)
  - `DELETE /sessions/{id}/cards/{card_id}`
  - `POST /cards/{card_id}/example`
  - `GET /sessions/{id}/export` (streaming `.apkg`)
  - `GET /health`

## Design

- Source visual: projeto Stitch `80654186402528267` (ViktorAnkiPipe / Kinetic Utility).
- Telas exportadas em `client/design/` (PNG + HTML de referência).
- Sistema de design completo em [client/design/](../../client/design/).

## Sucesso do MVP

Ao final do MVP o usuário deve conseguir:

1. Apontar a câmera para um parágrafo em inglês,
2. Tocar 1–10 palavras desconhecidas,
3. Ver cada uma traduzida com contexto da frase original,
4. Confirmar todas as palavras como cards de uma sessão,
5. Baixar o `.apkg` da sessão e importar no Anki Desktop.

Sem crash, sem perda de dados em transientes de rede, e em menos de 30s da
foto até o `.apkg` (excluindo upload do .apkg fora do app).
