# ViktorAnkiPipe

Vocabulary flashcard pipeline for English reading sessions. Point your camera at any English text, select words you don't know, and export a ready-to-import Anki deck — with translations and AI-generated example sentences.

## Components

| Directory | Language      | Description                                                         |
| --------- | ------------- | ------------------------------------------------------------------- |
| `server/` | Python 3.11+  | FastAPI backend — translation, session management, Anki export      |
| `client/` | Dart/Flutter  | Mobile app — camera OCR, word selection, session management         |

## How It Works

```
Camera → Google ML Kit OCR → word selection
                                   ↓
                        POST /sessions/{id}/cards (batch)
                                   ↓
                         SHA256 hash per word
                                   ↓
                         Redis cache lookup (MGET)
                                   ↓
                    LibreTranslate batch call (cache misses only)
                                   ↓
                      cards persisted + cache populated
                                   ↓
                        GET /sessions/{id}/export
                                   ↓
                    genanki builds .apkg in memory
                                   ↓
                          streaming download
```

**AI example generation** (on demand):

```
POST /cards/{id}/example
        ↓
  Claude API (Haiku) receives word + translation + original sentence context
        ↓
  returns { "example_sentence": "..." }
```

The `context` field — the original sentence where the word appeared — is included in the Claude prompt when available, producing examples that match the register and domain of the source text.

## Requirements

- Python 3.11+
- [uv](https://docs.astral.sh/uv/) (Python package manager)
- Redis 7+
- [LibreTranslate](https://github.com/LibreTranslate/LibreTranslate) (self-hosted)
- Anthropic API key (for example sentence generation)
- Flutter 3.11+ (for the client app)
- Docker + Docker Compose (optional, for running dependencies)

## Setup

### Backend (local development)

```bash
cd server
cp .env.example .env
# fill in ANTHROPIC_API_KEY and adjust REDIS_URL if needed
```

Start Redis and LibreTranslate:

```bash
docker run -d --name redis -p 6379:6379 redis:7-alpine
docker run -d --name libretranslate -p 5001:5000 libretranslate/libretranslate
# LibreTranslate takes ~60s on first boot to download language models
```

Install dependencies and run migrations:

```bash
uv sync
uv run alembic upgrade head
```

Start the server:

```bash
uv run uvicorn src.main:app --reload
```

API available at `http://localhost:8000` — interactive docs at `http://localhost:8000/docs`.

### Flutter client

```bash
cd client
flutter pub get
flutter run
```

## API

No authentication — all routes are public. Personal/local use only.

| Method | Route                            | Description                                        |
| ------ | -------------------------------- | -------------------------------------------------- |
| GET    | `/health`                        | Server status                                      |
| POST   | `/sessions`                      | Create session (`name`, optional `source`)         |
| GET    | `/sessions`                      | List sessions (filter: `?source=...`)              |
| GET    | `/sessions/{id}`                 | Session details + cards                            |
| DELETE | `/sessions/{id}`                 | Delete session and all its cards                   |
| POST   | `/sessions/{id}/cards`           | Batch translate (cache-first) and persist cards    |
| DELETE | `/sessions/{id}/cards/{card_id}` | Remove a card                                      |
| GET    | `/sessions/{id}/export`          | Download `.apkg` (streaming)                       |
| POST   | `/translate`                     | Standalone translation (populates cache, no card)  |
| POST   | `/cards/{card_id}/example`       | Generate AI example sentence for a card            |

### Session payload

```json
{
  "name": "Evening reading",
  "source": "Harry Potter and the Philosopher's Stone — ch.3"
}
```

`source` tags the session with the book and chapter. Use `GET /sessions?source=...` to find an existing session for the same book instead of creating duplicates.

## Translation Cache

Translations are cached in Redis, shared across all sessions:

```
translate:{source_lang}:{target_lang}:{sha256(text)}  →  translated string
```

Cache is checked with a single `MGET` call before any LibreTranslate request. Only cache misses are sent to LibreTranslate as a batch. TTL is configurable via `REDIS_CACHE_TTL_SECONDS` (default: no expiry).

## Testing

```bash
cd server

# Run all tests
uv run pytest

# With coverage
uv run pytest --cov=src --cov-report=term-missing

# Single file
uv run pytest tests/test_sessions.py -v
```

Tests use an in-memory SQLite database — no Docker required.

## Configuration

All settings are loaded from `server/.env` (see `.env.example`):

| Variable                  | Default                              | Description                        |
| ------------------------- | ------------------------------------ | ---------------------------------- |
| `DATABASE_URL`            | `sqlite+aiosqlite:///./data/viktor.db` | SQLite (swap for Postgres URL)   |
| `REDIS_URL`               | `redis://localhost:6379`             | Redis connection string            |
| `REDIS_CACHE_TTL_SECONDS` | *(no expiry)*                        | Translation cache TTL              |
| `LIBRETRANSLATE_URL`      | `http://localhost:5001`              | LibreTranslate base URL            |
| `ANTHROPIC_API_KEY`       | —                                    | Required for example generation    |
| `CORS_ORIGINS`            | `*`                                  | Comma-separated or JSON array      |
| `ENVIRONMENT`             | `development`                        | `development` or `production`      |
