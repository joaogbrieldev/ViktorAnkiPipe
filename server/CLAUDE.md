# CLAUDE.md

Este arquivo dá contexto ao Claude Code ao trabalhar neste repositório.

## Visão geral do projeto

**ViktorAnkiPipe** é um sistema para acelerar o estudo de vocabulário enquanto se lê livros em inglês. O fluxo é: **câmera → OCR → tradução → `.apkg` pronto para importar no Anki**.

O cliente Flutter (em diretório separado) faz captura e OCR via Google ML Kit. Este repositório contém **apenas o backend**, responsável por:

- Traduzir textos via LibreTranslate self-hosted.
- Manter histórico de decks e cards por usuário.
- Cachear traduções globalmente (compartilhadas entre usuários).
- Gerar arquivos `.apkg` via `genanki` para download direto.

## Componentes

| Diretório | Linguagem    | Descrição                                                |
| --------- | ------------ | -------------------------------------------------------- |
| `server/` | Python 3.11+ | API FastAPI, SQLite, LibreTranslate client, gerador Anki |
| `docs/`   | —            | Plano de arquitetura, decisões                           |

## Como funciona

```
Flutter (OCR) → POST /decks/{id}/cards (batch)
                     ↓
              hash SHA256 de cada texto
                     ↓
              consulta translation_cache (1 query, IN por hash)
                     ↓
              separa hits vs misses
                     ↓
              LibreTranslate batch call (só os misses)
                     ↓
              persiste cards + popula cache (1 transação)
                     ↓
              retorna todos os cards criados

Flutter → GET /decks/{id}/export
                     ↓
              genanki monta .apkg em memória (BytesIO)
                     ↓
              streaming download
```

## Stack

- **Python 3.11+** — obrigatório por causa do `genanki`
- **FastAPI** — framework web async
- **SQLAlchemy 2.x + Alembic** — ORM e migrations
- **SQLite** (dev) — migração pra Postgres é trivial depois
- **httpx** — client async para LibreTranslate
- **genanki** — geração de `.apkg`
- **pydantic-settings** — config via `.env`
- **pytest + httpx.AsyncClient** — testes
- **Docker Compose** — sobe backend + LibreTranslate juntos

## Setup

```bash
cd server
cp .env.example .env              # preencher ADMIN_TOKEN
docker compose up -d              # sobe backend + libretranslate

# migrations
docker compose exec api alembic upgrade head

# healthcheck
curl http://localhost:8000/health  # { status: "ok", libretranslate: "ok" }
```

## Comandos de desenvolvimento

Todos rodados a partir de `server/`:

```bash
# Rodar servidor local (sem Docker)
uvicorn app.main:app --reload

# Rodar testes
pytest                            # todos
pytest tests/test_cache.py -v     # arquivo específico
pytest -k "test_hit" -v           # por nome

# Lint e format
ruff check .
ruff format .

# Nova migration
alembic revision --autogenerate -m "descrição"
alembic upgrade head

# Subir só o LibreTranslate (útil em dev local)
docker compose up -d libretranslate
```

## Estrutura do projeto

```
server/
├── pyproject.toml              # deps + tooling (ruff, pytest)
├── docker-compose.yml          # backend + libretranslate
├── Dockerfile
├── .env.example
├── alembic.ini
├── alembic/versions/
├── app/
│   ├── main.py                 # FastAPI app, routers, middleware
│   ├── config.py               # Settings(BaseSettings)
│   ├── db.py                   # engine, SessionLocal, get_db
│   ├── models.py               # User, Deck, Card, TranslationCache
│   ├── schemas.py              # Pydantic: DeckIn/Out, CardIn/Out, etc.
│   ├── auth.py                 # dependency X-API-Key
│   ├── hashing.py              # SHA256 helpers
│   ├── routers/
│   │   ├── auth.py
│   │   ├── decks.py
│   │   ├── cards.py
│   │   └── translate.py
│   └── services/
│       ├── translator.py       # LibreTranslateClient (retry + timeout)
│       ├── cache.py            # get_or_translate_batch(items)
│       └── anki_exporter.py    # build_apkg(deck, cards) -> BytesIO
└── tests/
    ├── conftest.py             # fixtures: client, db, mock translator
    ├── test_decks.py
    ├── test_cards.py
    ├── test_translate.py
    ├── test_cache.py           # hit/miss e batch mixing
    └── test_export.py          # valida que .apkg gerado abre no Anki
```

## Schema do banco

Quatro tabelas. Cache é **global** (não tem `user_id`), compartilhado entre todos.

```sql
users             (id, name, api_key UNIQUE, created_at)
decks             (id, user_id FK, name, source_lang, target_lang, created_at)
cards             (id, deck_id FK, source_text, translated_text, context, created_at,
                   UNIQUE(deck_id, source_text))
translation_cache (id, source_lang, target_lang, source_hash, source_text,
                   translated_text, created_at,
                   UNIQUE(source_lang, target_lang, source_hash),
                   INDEX on (source_lang, target_lang, source_hash))
```

**Por que `source_hash`?** Busca por hash SHA256 é mais rápida que por texto completo em cache com muitas entradas ou textos longos (frases inteiras como contexto). Padrão emprestado do FrankYomik, que usa hash de imagens para deduplicar jobs.

## Referência da API

Autenticação: header `X-API-Key: <key>` em todas as rotas exceto `/health`.

| Método | Rota                          | Descrição                                     |
| ------ | ----------------------------- | --------------------------------------------- |
| GET    | `/health`                     | Status do servidor + LibreTranslate (público) |
| POST   | `/auth/register`              | Cria usuário, requer `X-Admin-Token`          |
| GET    | `/me`                         | Valida key, retorna perfil                    |
| POST   | `/decks`                      | Cria deck                                     |
| GET    | `/decks`                      | Lista decks do usuário                        |
| GET    | `/decks/{id}`                 | Detalhes + cards                              |
| DELETE | `/decks/{id}`                 | Deleta deck                                   |
| POST   | `/decks/{id}/cards`           | Batch: traduz (cache first) + persiste        |
| DELETE | `/decks/{id}/cards/{card_id}` | Deleta card                                   |
| GET    | `/decks/{id}/export`          | Download do `.apkg` (streaming)               |
| POST   | `/translate`                  | Tradução avulsa (popula cache, não cria card) |

OpenAPI automático em `http://localhost:8000/docs`.

## Decisões de design importantes

- **OCR fica no cliente.** O servidor nunca lida com imagens; recebe texto já extraído. Isso mantém o backend simples e barato.
- **Python é obrigatório.** `genanki` não tem equivalente maduro em Go/Node/Rust. Essa decisão é fixa.
- **Cache é global.** Se o usuário A traduziu "melange", o usuário B recebe a tradução do cache — não retraduz. Sem `user_id` em `translation_cache`.
- **Batch sempre.** O endpoint `POST /decks/{id}/cards` sempre aceita um array de items. Flutter pode mandar 1, mas o shape é sempre de lista. Evita round-trips.
- **Lookup de cache em uma query só.** Calcular todos os hashes primeiro, depois `WHERE source_hash IN (...)` — nunca fazer N queries num loop.
- **LibreTranslate batch.** A API aceita array em `/translate`; chamar uma vez só com os misses, nunca N vezes.
- **Síncrono por enquanto.** Nada de Redis/Workers/WebSocket. O caso de uso é "eu + amigos", batches pequenos, latência aceitável. Se virar problema, migrar incrementalmente.
- **SQLite em dev.** Migração pra Postgres é só trocar a URL no `.env`. SQLAlchemy abstrai.

## Convenções de código

- **Ruff** para lint e format (config no `pyproject.toml`).
- **Type hints obrigatórios** em signatures públicas de serviços e schemas.
- **Pydantic para I/O**, SQLAlchemy para persistência — nunca misturar.
- **Schemas separados** para input e output (ex: `DeckIn`, `DeckOut`) — evita vazar campos internos.
- **Async em todo caminho crítico** (routers, services que fazem I/O, DB session async).
- **Nomes em inglês** no código; comentários e docs podem ser em português.

## Padrões de teste

- Fixtures em `conftest.py`: `client` (AsyncClient), `db` (SQLite in-memory), `mock_translator` (subclasse fake de Translator).
- **Nunca chamar LibreTranslate de verdade em testes** — sempre mockar via dependency override.
- Testes de cache cobrem: cache vazio, hit total, miss total, mistura (alguns hits + alguns misses).
- Teste de export valida que o `.apkg` é um ZIP válido e contém os arquivos esperados (`collection.anki2`, `media`).

## Armadilhas conhecidas

- **`genanki` precisa de IDs estáveis** para o modelo e o deck. Gerar aleatório uma vez e guardar como constante no módulo — senão toda exportação vira um "deck novo" no Anki e perde o progresso de revisão do usuário.
- **LibreTranslate tarda pra subir** no primeiro boot (baixa modelos). Healthcheck do Docker Compose precisa de `start_period` generoso (uns 60s).
- **SQLite + async**: usar `aiosqlite` como driver (`sqlite+aiosqlite:///...`) e `AsyncSession` do SQLAlchemy 2.x. Misturar sessão sync com engine async quebra sutilmente.
- **`UNIQUE(deck_id, source_text)`** em `cards`: ao adicionar o mesmo texto duas vezes no mesmo deck, retornar o card existente em vez de quebrar. O conflito deve ser tratado como idempotência, não como erro.

## Fluxos comuns

**Adicionar um novo endpoint:**

1. Schema em `app/schemas.py`.
2. Router em `app/routers/<arquivo>.py`.
3. Registrar o router em `app/main.py`.
4. Teste em `tests/test_<arquivo>.py`.

**Adicionar nova coluna:**

1. Editar `app/models.py`.
2. `alembic revision --autogenerate -m "..."`.
3. Revisar o arquivo de migration gerado (autogen nem sempre acerta tudo).
4. `alembic upgrade head`.

**Mudar o template do card Anki:**

1. Editar `app/services/anki_exporter.py`.
2. **Manter o `model_id` constante** — não regenerar.
3. Testar com `pytest tests/test_export.py` e abrir o `.apkg` no Anki desktop para conferir visualmente.

## Próximos passos pendentes

Ver `docs/plano-viktoranki-v2.md` para o roadmap completo. Em ordem:

1. `pyproject.toml` + `docker-compose.yml` + `Dockerfile`.
2. Modelos + primeira migration.
3. `services/translator.py` e `services/cache.py`.
4. Routers (auth → decks → cards → translate → export).
5. `services/anki_exporter.py`.
6. Testes e validação manual no Anki desktop.
