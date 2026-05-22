# CLAUDE.md

Este arquivo dá contexto ao Claude Code ao trabalhar neste repositório.

## Visão geral do projeto

**ViktorAnkiPipe** é um sistema para acelerar o estudo de vocabulário enquanto se lê livros em inglês. O fluxo é: **câmera → OCR → tradução → `.apkg` pronto para importar no Anki**.

O cliente Flutter (em diretório separado) faz captura e OCR via Google ML Kit. Este repositório contém **apenas o backend**, responsável por:

- Traduzir textos via LibreTranslate self-hosted.
- Manter histórico de session e cards.
- Cachear traduções globalmente via **Redis** (compartilhadas entre sessions).
- Gerar frases de exemplo para palavras traduzidas via **IA** (Claude API).
- Gerar arquivos `.apkg` via `genanki` para download direto.

**Sem autenticação.** A API é aberta — não há `X-API-Key`, usuários ou tokens. O caso de uso é pessoal/local.

## Componentes

| Diretório | Linguagem    | Descrição                                                |
| --------- | ------------ | -------------------------------------------------------- |
| `server/` | Python 3.11+ | API FastAPI, SQLite, LibreTranslate client, gerador Anki |
| `docs/`   | —            | Plano de arquitetura, decisões                           |

## Como funciona

```
Flutter (OCR) → POST /sessions/{id}/cards (batch)
                     ↓
              hash SHA256 de cada texto
                     ↓
              consulta Redis (MGET por hash)
                     ↓
              separa hits vs misses
                     ↓
              LibreTranslate batch call (só os misses)
                     ↓
              persiste cards + popula Redis (SET EX por hash)
                     ↓
              retorna todos os cards criados

Flutter → POST /cards/{card_id}/example
                     ↓
              Claude API gera frase de exemplo
              para a palavra/tradução do card
                     ↓
              retorna { example_sentence: "..." }

Flutter → GET /sessions/{id}/export
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
- **Redis** — cache global de traduções (substitui a tabela `translation_cache`)
- **redis-py (async)** — client Redis com suporte a `asyncio` (`redis.asyncio`)
- **httpx** — client async para LibreTranslate
- **google-genai** — SDK oficial do Google para geração de frases de exemplo via Gemini 2.5 Flash
- **genanki** — geração de `.apkg`
- **pydantic-settings** — config via `.env`
- **pytest + httpx.AsyncClient** — testes
- **Docker Compose** — sobe backend + LibreTranslate + Redis juntos

## Setup

```bash
cd server
cp .env.example .env              # preencher DATABASE_URL, LIBRETRANSLATE_URL, REDIS_URL, GEMINI_API_KEY
docker compose up -d              # sobe backend + libretranslate + redis

# migrations
docker compose exec api alembic upgrade head

# healthcheck
curl http://localhost:8000/health  # { status: "ok", libretranslate: "ok", redis: "ok" }
```

## Comandos de desenvolvimento

O projeto usa **[uv](https://docs.astral.sh/uv/)** (lockfile: `uv.lock`, ambiente: `server/.venv`).

**Instalar [uv](https://docs.astral.sh/uv/getting-started/installation/)** (uma vez no sistema) e, na pasta `server/`:

```bash
uv sync          # cria/actualiza .venv a partir de uv.lock (inclui grupo dev)
uv run …         # executa no ambiente do projecto sem activar o venv manualmente
```

Todos os comandos abaixo a partir de `server/`:

```bash
# Rodar servidor local (sem Docker)
uv run uvicorn src.main:app --reload

# Rodar TODOS os testes (obrigatório antes de qualquer commit)
uv run pytest

# Rodar testes com cobertura
uv run pytest --cov=src --cov-report=term-missing

# Arquivo específico
uv run pytest tests/test_cache.py -v

# Por nome
uv run pytest -k "test_hit" -v

# Lint e format
uv run ruff check .
uv run ruff format .

# Nova migration
uv run alembic revision --autogenerate -m "descrição"
uv run alembic upgrade head

# Subir só o LibreTranslate (útil em dev local)
docker compose up -d libretranslate
```

`pip` ainda funciona: `cd server && .venv/bin/pip` após `uv sync`, mas o workflow recomendado é `uv sync` e `uv run`.

## Estrutura do projeto

```
server/
├── pyproject.toml              # deps + tooling (ruff, pytest)
├── uv.lock                     # lockfile (uv) — comitar
├── docker-compose.yml          # backend + libretranslate
├── Dockerfile
├── .env.example
├── alembic.ini
├── alembic/versions/
├── src/
│   ├── main.py                 # FastAPI app, routers, middleware
│   ├── config.py               # Settings(BaseSettings)
│   ├── database.py             # engine, SessionLocal, get_db
│   ├── exceptions.py           # Global exceptions
│   ├── constants.py            # Global constants
│   ├── sessions/
│   │   ├── ...                 # All about sessions
│   └── cards/
│   │   ├── ...                 # All about cards
└── tests/
    ├── conftest.py             # fixtures: client, db, mock translator
    ├── test_cards.py
    ├── test_translate.py
    ├── test_cache.py           # hit/miss e batch mixing
    └── test_export.py          # valida que .apkg gerado abre no Anki
```

## Schema do banco

Duas tabelas SQLite. O cache de traduções vive no Redis, não em SQL.

```sql
sessions  (id, name, source, created_at)
           -- source: livro / capítulo de origem (ex: "Harry Potter ch.3")

cards     (id, session_id FK, source_text, translated_text, context, created_at,
           UNIQUE(session_id, source_text))
           -- context: frase original onde a palavra apareceu (usada no prompt de IA)
```

## Cache Redis

O cache de traduções é armazenado no Redis como strings simples. Chave no formato:

```
translate:{source_lang}:{target_lang}:{sha256(source_text)}
```

- Valor: texto traduzido (string UTF-8).
- TTL: configurável via `REDIS_CACHE_TTL_SECONDS` (padrão: sem expiração).
- Lookup em batch: `MGET` com todas as chaves de uma vez — nunca N chamadas em loop.
- Escrita: `SET` por chave após tradução nos misses.

**Por que Redis no lugar da tabela?** Chaves com TTL nativo, sem overhead de SQL, MGET é O(N) sem query planner. O caso de uso é leitura intensiva com escritas pontuais — Redis é a ferramenta certa.

## Referência da API

Sem autenticação — todas as rotas são públicas.

| Método | Rota                             | Descrição                                          |
| ------ | -------------------------------- | -------------------------------------------------- |
| GET    | `/health`                        | Status do servidor + LibreTranslate + Redis        |
| POST   | `/sessions`                      | Cria sessão (`name`, `source?`)                    |
| GET    | `/sessions`                      | Lista todas as sessões (filtro: `?source=...`)     |
| GET    | `/sessions/{id}`                 | Detalhes + cards                                   |
| DELETE | `/sessions/{id}`                 | Deleta sessão e todos os cards                     |
| POST   | `/sessions/{id}/cards`           | Batch: traduz (cache first) + persiste             |
| DELETE | `/sessions/{id}/cards/{card_id}` | Deleta card                                        |
| GET    | `/sessions/{id}/export`          | Download do `.apkg` (streaming)                    |
| POST   | `/translate`                     | Tradução avulsa (popula cache, não cria card)      |
| POST   | `/cards/{card_id}/example`       | Gera frase de exemplo via IA para o card           |

### Payload de criação de sessão

```json
POST /sessions
{
  "name": "Leitura Harry Potter",
  "source": "Harry Potter and the Philosopher's Stone — ch.3"
}
```

O campo `source` é opcional mas recomendado: identifica o livro/capítulo, serve como nome do deck exportado e permite ao Flutter buscar uma sessão existente para o mesmo livro sem criar duplicatas (`GET /sessions?source=...`).

OpenAPI automático em `http://localhost:8000/docs`.

## Decisões de design importantes

- **Sem autenticação.** Uso pessoal/local; adicionar auth depois é trivial se necessário.
- **OCR fica no cliente.** O servidor nunca lida com imagens; recebe texto já extraído. Isso mantém o backend simples e barato.
- **Python é obrigatório.** `genanki` não tem equivalente maduro em Go/Node/Rust. Essa decisão é fixa.
- **Cache Redis é global.** Se o deck A traduziu "melange", o deck B recebe a tradução do Redis — não retraduz. Chave: `translate:{src}:{tgt}:{hash}`.
- **Batch sempre.** O endpoint `POST /sessions/{id}/cards` sempre aceita um array de items. Flutter pode mandar 1, mas o shape é sempre de lista. Evita round-trips.
- **Lookup de cache em uma chamada só.** Calcular todos os hashes primeiro, depois `MGET` no Redis — nunca N chamadas em loop.
- **LibreTranslate batch.** A API aceita array em `/translate`; chamar uma vez só com os misses, nunca N vezes.
- **Geração de exemplo via Claude API.** `POST /cards/{id}/example` usa a Anthropic SDK para gerar uma frase de exemplo contextualizada para a palavra traduzida. O resultado **não é cacheado** — cada chamada é on-demand (latência baixa, frequência baixa).
- **SQLite em dev.** Migração pra Postgres é só trocar a URL no `.env`. SQLAlchemy abstrai.

## Convenções de código

- **Ruff** para lint e format (config no `pyproject.toml`).
- **Type hints obrigatórios** em signatures públicas de serviços e schemas.
- **Pydantic para I/O**, SQLAlchemy para persistência — nunca misturar.
- **Schemas separados** para input e output (ex: `DeckIn`, `DeckOut`) — evita vazar campos internos.
- **Async em todo caminho crítico** (routers, services que fazem I/O, DB session async).
- **Nomes em inglês** no código; comentários e docs podem ser em português.

## Padrões de teste

**Testes são obrigatórios.** Nenhum módulo, serviço ou endpoint vai para produção sem cobertura de testes automatizados. A regra é: se não tem teste, não está pronto.

- Fixtures em `conftest.py`: `client` (AsyncClient), `db` (SQLite in-memory), `mock_translator` (subclasse fake de `LibreTranslateClient`).
- **Nunca chamar LibreTranslate de verdade em testes** — sempre mockar via dependency override.
- **Todo novo endpoint** deve ter teste de caminho feliz + pelo menos um caso de erro.
- **Todo novo serviço** deve ter testes unitários isolados (sem dependência de rede ou banco real).
- Testes de cache cobrem: cache vazio, hit total, miss total, mistura (alguns hits + alguns misses).
- Teste de export valida que o `.apkg` é um ZIP válido e contém os arquivos esperados (`collection.anki2`, `media`).
- Rodar `pytest --cov=app` para verificar cobertura antes de considerar qualquer feature completa.

## Integração com IA (Gemini API)

O endpoint `POST /cards/{card_id}/example` gera uma frase de exemplo em inglês contextualizada para a palavra ou expressão traduzida no card.

**Ficheiros envolvidos:**

| Ficheiro | Responsabilidade |
| -------- | ---------------- |
| `src/cards/ai_service.py` | `GeminiService` — chama a API; `_build_prompt` |
| `src/cards/dependencies.py` | `get_gemini_service` (singleton via `lru_cache`); `GeminiDep` |
| `src/cards/service.py` | `get_example_sentence` — busca card + delega ao Gemini |
| `src/cards/routes.py` | `POST /cards/{card_id}/example` |

**Fluxo:**

1. Busca o card pelo `card_id` no banco.
2. Monta prompt com `source_text`, `translated_text` **e `context`** (frase original onde a palavra apareceu) do card.
3. Chama a Gemini API via `google-genai` SDK (modelo `gemini-2.5-flash` — rápido e barato).
4. Retorna `{ "example_sentence": "..." }`.

**Prompt base:**

```
You are an English vocabulary tutor.
Word: "{source_text}" (means "{translated_text}" in Portuguese).
[If card.context is not None:]
The reader encountered it in this sentence: "{context}".
[End if]
Write one short, natural English example sentence that uses this word correctly.
Return only the sentence, nothing else.
```

O campo `context` é a frase original onde o usuário encontrou a palavra. Quando presente, o modelo gera um exemplo que respeita o registro e domínio do texto original, produzindo frases muito mais úteis para revisão no Anki.

**Configuração:** `GEMINI_API_KEY` no `.env`. O SDK recebe a chave explicitamente via `genai.Client(api_key=...)`.

**Decisões:**

- Gemini 2.5 Flash por padrão — latência baixa, custo mínimo para frases curtas.
- Singleton via `lru_cache` em `get_gemini_service` — um único `genai.Client` por processo.
- Sem cache de exemplos — frases são geradas on-demand; variedade é desejável.
- Sem streaming — a frase é curta o suficiente para resposta direta.
- `context` sempre incluído no prompt quando disponível — melhora a qualidade sem custo de latência.

**Mock em testes:** subclasse `GeminiService` com `__init__` vazio e `generate_example` síncrono retornando string fixa; injectar via `app.dependency_overrides[get_gemini_service] = lambda: _FakeGemini()`.

## Armadilhas conhecidas

- **`genanki` precisa de IDs estáveis** para o modelo e o deck. Gerar aleatório uma vez e guardar como constante no módulo — senão toda exportação vira um "deck novo" no Anki e perde o progresso de revisão do usuário.
- **LibreTranslate tarda pra subir** no primeiro boot (baixa modelos). Healthcheck do Docker Compose precisa de `start_period` generoso (uns 60s).
- **SQLite + async**: usar `aiosqlite` como driver (`sqlite+aiosqlite:///...`) e `AsyncSession` do SQLAlchemy 2.x. Misturar sessão sync com engine async quebra sutilmente.
- **`UNIQUE(deck_id, source_text)`** em `cards`: ao adicionar o mesmo texto duas vezes no mesmo deck, retornar o card existente em vez de quebrar. O conflito deve ser tratado como idempotência, não como erro.
- **Redis `MGET` retorna `None` para chaves ausentes** — iterar resultado com zip para separar hits e misses em vez de assumir que todos os valores estão presentes.
- **Gemini API tem custo por chamada** — `POST /cards/{id}/example` não deve ser chamado em loop automático; é sempre ação explícita do usuário.

## Fluxos comuns

**Adicionar um novo endpoint:**

1. Schema em `app/schemas.py`.
2. Router em `app/routers/<arquivo>.py`.
3. Registrar o router em `app/main.py`.
4. **Teste em `tests/test_<arquivo>.py`** — obrigatório, não opcional.

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

Em ordem:

1. Migration para adicionar coluna `source` na tabela `sessions` (a coluna está no modelo ORM mas não na migration inicial).
2. Migration para remover tabela `translation_cache` (cache é Redis — a tabela SQL não deve existir).
3. `src/cards/service.py` — batch add com cache Redis first + LibreTranslate para os misses.
4. `src/anki/service.py` — geração de `.apkg` com `genanki`.
5. `src/anki/router.py` — endpoint `GET /sessions/{id}/export`.
6. ~~Cards router + example endpoint (`POST /cards/{card_id}/example`).~~ ✓ Implementado com Gemini 2.5 Flash.
7. Testes de export — valida que `.apkg` é um ZIP válido com `collection.anki2` e `media`.

# FastAPI Best Practices for AI Agents

A machine-readable companion to [README.md](./README.md) for AI coding agents
working in FastAPI projects. Same rules, restructured for fast pattern matching:
version pins, Do/Don't blocks, anti-patterns, and a quick-reference table.

## Compatibility Matrix

Pin to these versions or newer. Examples in this file assume them.

| Dependency        | Minimum | Notes                                                    |
| ----------------- | ------- | -------------------------------------------------------- |
| Python            | 3.11    | Required for `StrEnum` and `X \| Y` union syntax         |
| FastAPI           | 0.115   | `Annotated[T, Depends(...)]` is the idiomatic form       |
| Pydantic          | 2.7     | v1 APIs (`json_encoders`, `.dict()`) are removed         |
| pydantic-settings | 2.4     | Lives in a separate package since Pydantic v2            |
| SQLAlchemy        | 2.0     | Use the async API (`AsyncSession`, `async_sessionmaker`) |
| Alembic           | 1.13    | Async-aware migrations                                   |
| httpx             | 0.27    | Use `ASGITransport` for in-process tests                 |
| PyJWT             | 2.9     | Use this, not the unmaintained `python-jose`             |
| ruff              | 0.6     | Replaces black, isort, autoflake                         |

## Project Structure

Organize by domain, not by file type. One package per bounded context.

```
src/
├── {domain}/           # e.g., auth/, posts/, aws/
│   ├── router.py       # API endpoints
│   ├── schemas.py      # Pydantic models
│   ├── models.py       # SQLAlchemy ORM models
│   ├── service.py      # Business logic
│   ├── dependencies.py # Route dependencies
│   ├── config.py       # Domain-scoped BaseSettings
│   ├── constants.py    # Constants and error codes
│   ├── exceptions.py   # Domain-specific exceptions
│   └── utils.py        # Helper functions
├── config.py           # Global BaseSettings
├── models.py           # Shared Pydantic / ORM bases
├── exceptions.py       # Global exceptions
├── database.py         # Async engine + session factory
└── main.py             # FastAPI app + lifespan
```

**Cross-domain imports**: always use the explicit module name. Never `from src.auth import *`.

```python
from src.auth import constants as auth_constants
from src.notifications import service as notification_service
from src.posts.constants import ErrorCode as PostsErrorCode
```

## Async Routes

### Decision rule

| Route does this                       | Use                                                     |
| ------------------------------------- | ------------------------------------------------------- |
| `await`-able non-blocking I/O         | `async def`                                             |
| Blocking I/O (no async client exists) | `def` (sync, runs in threadpool)                        |
| Mix of both                           | `async def` + `run_in_threadpool` for the blocking part |
| CPU-bound work (>50 ms compute)       | Offload to a worker process (Celery / RQ / Arq)         |

### Do / Don't

```python
# DON'T — blocking call inside async route freezes the entire event loop
@router.get("/bad")
async def bad():
    time.sleep(10)            # blocks every request on this worker
    return {"ok": True}

# DO — sync route lets FastAPI run it in a threadpool
@router.get("/sync-ok")
def sync_ok():
    time.sleep(10)            # blocks one threadpool worker, not the loop
    return {"ok": True}

# DO — async route with awaitable sleep
@router.get("/async-ok")
async def async_ok():
    await asyncio.sleep(10)   # yields control, loop keeps serving requests
    return {"ok": True}

# DO — async route that has to call a sync library
from fastapi.concurrency import run_in_threadpool

@router.get("/wrap")
async def wrap():
    result = await run_in_threadpool(legacy_sync_client.fetch, "id")
    return result
```

### Threadpool caveats

- Default Starlette threadpool size is 40. Saturating it slows every sync route.
- Threads cost more than coroutines. Don't use sync routes "just because."

## Pydantic

### Use built-in validators

```python
from enum import StrEnum
from pydantic import AnyUrl, BaseModel, EmailStr, Field


class MusicBand(StrEnum):
    AEROSMITH = "AEROSMITH"
    QUEEN = "QUEEN"
    ACDC = "AC/DC"


class UserCreate(BaseModel):
    first_name: str = Field(min_length=1, max_length=128)
    username: str = Field(min_length=1, max_length=128, pattern=r"^[A-Za-z0-9_-]+$")
    email: EmailStr
    age: int = Field(ge=18)                     # required, must be >= 18
    favorite_band: MusicBand | None = None
    website: AnyUrl | None = None
```

> **Don't** write `Field(ge=18, default=None)`. The constraint and the default contradict
> each other. Decide: required (`Field(ge=18)`) or optional (`int | None = Field(default=None, ge=18)`).

### Custom base model — modern serialization

`json_encoders` is deprecated in Pydantic v2. Use `@field_serializer` for per-field rules,
or annotate a custom type with `PlainSerializer`.

```python
from datetime import datetime
from zoneinfo import ZoneInfo
from pydantic import BaseModel, ConfigDict, field_serializer


class CustomModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    @field_serializer("*", when_used="json", check_fields=False)
    def _serialize_datetimes(self, value):
        if isinstance(value, datetime):
            if value.tzinfo is None:
                value = value.replace(tzinfo=ZoneInfo("UTC"))
            return value.strftime("%Y-%m-%dT%H:%M:%S%z")
        return value
```

### Split BaseSettings by domain

`pydantic-settings` is its own package since Pydantic v2.

```python
# src/auth/config.py
from datetime import timedelta
from pydantic_settings import BaseSettings, SettingsConfigDict


class AuthConfig(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AUTH_", env_file=".env", extra="ignore")

    JWT_ALG: str
    JWT_SECRET: str
    JWT_EXP_MINUTES: int = 5
    REFRESH_TOKEN_KEY: str
    REFRESH_TOKEN_EXP: timedelta = timedelta(days=30)
    SECURE_COOKIES: bool = True


auth_settings = AuthConfig()
```

## Dependencies

### Use Annotated, not default-arg `Depends(...)`

`Annotated[T, Depends(...)]` is the idiomatic form since FastAPI 0.95 and avoids
gotchas with default values.

```python
# DO — modern Annotated form
from typing import Annotated
from fastapi import Depends

PostDep = Annotated[dict, Depends(valid_post_id)]

@router.get("/posts/{post_id}")
async def get_post(post: PostDep):
    return post

# Avoid — default-argument form (still works, but legacy)
@router.get("/posts/{post_id}")
async def get_post(post: dict = Depends(valid_post_id)):
    return post
```

### Validate inside dependencies (not just inject)

```python
async def valid_post_id(post_id: UUID4) -> dict:
    post = await service.get_by_id(post_id)
    if not post:
        raise PostNotFound()
    return post
```

### Chain dependencies for reuse

```python
async def valid_owned_post(
    post: Annotated[dict, Depends(valid_post_id)],
    token_data: Annotated[dict, Depends(parse_jwt_data)],
) -> dict:
    if post["creator_id"] != token_data["user_id"]:
        raise UserNotOwner()
    return post
```

### Rules

- Dependencies are **cached per request**. Same `Depends(x)` called 5 times in one request → `x` runs once.
- Prefer `async def` dependencies. Sync deps run in the threadpool — wasted overhead for small CPU-only checks.
- Use **the same path-variable name** across endpoints when you want to share a dependency (e.g. `profile_id` in both `/profiles/{profile_id}` and `/creators/{profile_id}`).

## Authentication — JWT

Use **`PyJWT`**, not `python-jose` (unmaintained).

```python
import jwt  # PyJWT
from jwt.exceptions import InvalidTokenError

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALG])
    except InvalidTokenError as exc:
        raise InvalidCredentials() from exc
```

## Database — SQLAlchemy 2.0 async

Prefer SQLAlchemy 2.0's async API. `encode/databases` is in maintenance mode — don't pick it for new projects.

```python
# src/database.py
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

engine = create_async_engine(str(settings.DATABASE_URL), pool_pre_ping=True)
SessionFactory = async_sessionmaker(engine, expire_on_commit=False)


async def get_db() -> AsyncSession:
    async with SessionFactory() as session:
        yield session
```

### Naming conventions

- `lower_case_snake`
- Singular tables: `post`, `user`, `post_like`
- Group with prefix: `payment_account`, `payment_bill`
- `_at` suffix for `datetime`, `_date` suffix for `date`
- Use the same FK column name everywhere it appears (`profile_id`, not `user_id` in some tables and `profile_id` in others)

### Index naming convention

```python
from sqlalchemy import MetaData

POSTGRES_INDEXES_NAMING_CONVENTION = {
    "ix": "%(column_0_label)s_idx",
    "uq": "%(table_name)s_%(column_0_name)s_key",
    "ck": "%(table_name)s_%(constraint_name)s_check",
    "fk": "%(table_name)s_%(column_0_name)s_fkey",
    "pk": "%(table_name)s_pkey",
}
metadata = MetaData(naming_convention=POSTGRES_INDEXES_NAMING_CONVENTION)
```

### SQL-first, Pydantic-second

- Do joins, aggregation, and JSON shaping in SQL — Postgres is faster than CPython at this.
- Hydrate the result into Pydantic only for response validation, not for transformation.

## Background work — BackgroundTasks vs Celery

| Use BackgroundTasks when…                | Use Celery / Arq / RQ when…                  |
| ---------------------------------------- | -------------------------------------------- |
| Task is < 1 second                       | Task takes seconds to minutes                |
| Failure can be silently dropped          | You need retries, dead-letter, or visibility |
| Task is in-process (send email, log row) | Task is CPU-heavy or needs a separate pool   |
| You don't need scheduling                | You need cron, ETA, or rate limiting         |

```python
from fastapi import BackgroundTasks

@router.post("/signup")
async def signup(data: SignupIn, bg: BackgroundTasks):
    user = await service.create_user(data)
    bg.add_task(send_welcome_email, user.email)   # fire-and-forget, in-process
    return user
```

> BackgroundTasks run **after the response is sent, in the same worker process**. If the
> worker dies, the task is lost. There is no retry. Don't use them for anything you'd
> page on.

## Testing

### Async client from day one

```python
import pytest
from httpx import AsyncClient, ASGITransport

from src.main import app


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_create_post(client: AsyncClient):
    resp = await client.post("/posts", json={"title": "hi"})
    assert resp.status_code == 201
```

> **Don't** use `async_asgi_testclient` — it's unmaintained. The example above (httpx +
> `ASGITransport`) is the supported path.

### Override dependencies in tests

Don't monkeypatch internals. Use FastAPI's built-in `dependency_overrides`.

```python
from src.auth.dependencies import parse_jwt_data
from src.main import app


def fake_user():
    return {"user_id": "00000000-0000-0000-0000-000000000001"}


@pytest.fixture(autouse=True)
def _override_auth():
    app.dependency_overrides[parse_jwt_data] = fake_user
    yield
    app.dependency_overrides.clear()
```

## Migrations (Alembic)

- Migrations must be static and reversible.
- Use the async template: `alembic init -t async migrations`
- Descriptive filenames:
  ```ini
  # alembic.ini
  file_template = %%(year)d-%%(month).2d-%%(day).2d_%%(slug)s
  ```
  → `2026-04-14_add_post_content_idx.py`

## API documentation

### Hide docs outside selected envs

```python
from fastapi import FastAPI
from src.config import settings

SHOW_DOCS_IN = {"local", "staging"}
app_kwargs = {"title": "My API"}
if settings.ENVIRONMENT not in SHOW_DOCS_IN:
    app_kwargs["openapi_url"] = None    # disables /docs and /redoc

app = FastAPI(**app_kwargs)
```

### Document endpoints fully

```python
from fastapi import APIRouter, status

router = APIRouter()


@router.post(
    "/items",
    response_model=ItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create an item",
    description="Creates an item owned by the authenticated user.",
    tags=["items"],
    responses={
        status.HTTP_400_BAD_REQUEST: {"model": ErrorResponse, "description": "Validation error"},
        status.HTTP_409_CONFLICT:    {"model": ErrorResponse, "description": "Slug already exists"},
    },
)
async def create_item(payload: ItemCreate) -> ItemResponse: ...
```

## Linting

```shell
ruff check --fix src
ruff format src
```

Add to a pre-commit hook or run in CI. Ruff replaces black + isort + autoflake + most of flake8.

---

## Anti-patterns — common AI-agent mistakes

If you're an agent reviewing a diff, check for these. Each is a real failure mode I've
seen agents introduce.

| Anti-pattern                                                                       | Why it's wrong                                       | Fix                                                                                                                   |
| ---------------------------------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `requests.get(...)` inside `async def`                                             | Blocks the event loop. `requests` is sync.           | Use `httpx.AsyncClient` or `await run_in_threadpool(requests.get, ...)`.                                              |
| `time.sleep` / `open()` / sync DB driver inside `async def`                        | Same — blocks the loop.                              | Use the async equivalent (`asyncio.sleep`, `aiofiles`, async driver).                                                 |
| `from jose import jwt`                                                             | `python-jose` is unmaintained.                       | `import jwt` (PyJWT).                                                                                                 |
| `from async_asgi_testclient import TestClient`                                     | Unmaintained.                                        | `httpx.AsyncClient` + `ASGITransport`.                                                                                |
| `model_config = ConfigDict(json_encoders={...})`                                   | Deprecated in Pydantic v2.                           | `@field_serializer` or `Annotated[T, PlainSerializer(...)]`.                                                          |
| `Field(ge=18, default=None)`                                                       | Constraint contradicts the default.                  | Pick required or optional, not both.                                                                                  |
| `def get_user(id: int = Depends(...))` (default-arg form)                          | Legacy; gotchas with default values.                 | `user: Annotated[User, Depends(...)]`.                                                                                |
| Catching `Exception` around a route's body                                         | Hides bugs and turns 500s into silent 200s.          | Catch the specific exception class; raise `HTTPException` with a meaningful status.                                   |
| `BackgroundTasks` for anything you'd page on                                       | No retry, dies with the worker.                      | Use Celery / Arq / RQ.                                                                                                |
| Calling a sync ORM session inside `async def`                                      | Blocks the loop, may deadlock the pool.              | Use `AsyncSession`.                                                                                                   |
| Returning a Pydantic model and _also_ setting `response_model=` to that same class | Model gets constructed twice (validate + serialize). | Either return a `dict`/ORM row and let `response_model` validate, or drop `response_model` and trust the return type. |
| Importing across domains via deep paths (`from src.auth.service.user import ...`)  | Tight coupling, hard to refactor.                    | `from src.auth import service as auth_service`.                                                                       |
| Reusing one `BaseSettings` for the whole app                                       | Hard to reason about, every domain reads every var.  | One `BaseSettings` per domain.                                                                                        |
| Mocking the database in integration tests                                          | Mock/prod divergence eventually fires in prod.       | Use a real DB (testcontainers, ephemeral schema) and `dependency_overrides` for auth/external services.               |

## Quick reference

| Scenario                          | Solution                                       |
| --------------------------------- | ---------------------------------------------- |
| Non-blocking I/O                  | `async def` route with `await`                 |
| Blocking I/O (no async client)    | `def` route (sync, runs in threadpool)         |
| Sync library inside async route   | `await run_in_threadpool(fn, *args)`           |
| CPU-intensive work                | Celery / Arq / RQ worker process               |
| Request validation against DB     | Dependency that loads + validates + returns    |
| Reuse validation across routes    | Chain dependencies                             |
| Inject dependency in modern style | `Annotated[T, Depends(...)]`                   |
| Per-request dep caching           | Default behavior — same `Depends(x)` runs once |
| Per-domain config                 | One `BaseSettings` subclass per domain         |
| Custom datetime serialization     | `@field_serializer`                            |
| Fire-and-forget short task        | `BackgroundTasks`                              |
| Reliable / scheduled / heavy task | Celery / Arq / RQ                              |
| JWT decode                        | `PyJWT` (`import jwt`)                         |
| Async DB                          | SQLAlchemy 2.0 async (`AsyncSession`)          |
| HTTP test client                  | `httpx.AsyncClient` + `ASGITransport`          |
| Swap dep in tests                 | `app.dependency_overrides[dep] = fake`         |
| Lint + format                     | `ruff check --fix` + `ruff format`             |
