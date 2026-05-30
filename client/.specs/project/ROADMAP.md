# Roadmap

## Milestones

### M0 — Foundation (pré-feature)
Setup do projeto Flutter: theme Kinetic Utility, roteamento, cliente HTTP,
configuração via `--dart-define`, estrutura de pastas, lints.

→ Feature: [foundation](../features/foundation/spec.md)

### M1 — Sessions (lista, criar, deletar)
Tela "Lista de Sessões" 100% funcional contra o backend. Permite criar uma
sessão nova (nome + source opcional), buscar/filtrar, deletar via swipe.
Sem cards ainda.

→ Feature: [sessions](../features/sessions/spec.md)

### M2 — Camera + OCR
Tela "Câmera de Tradução": preview da câmera, framing brackets, controle de
flash, troca de câmera, shutter. Após captura, ML Kit tokeniza o texto e
expõe blocos selecionáveis. Sem tradução ainda — só captura e mostra
tokens detectados sobre a imagem congelada.

→ Feature: [camera-ocr](../features/camera-ocr/spec.md)

### M3 — Translation Result + Card Add
Tela "Resultado da Tradução": ao tocar em um token detectado, abre bottom
sheet com a tradução (chamada ao backend) + contexto (frase original).
Botão "Adicionar ao deck" persiste o card via `POST /sessions/{id}/cards`.

→ Feature: [translation-result](../features/translation-result/spec.md)

### M4 — Session Detail + Cards
Tela de detalhe da sessão acessível a partir da lista. Mostra cards
(palavra / tradução / data). Swipe para deletar. Botão para gerar
frase exemplo via IA (`POST /cards/{id}/example`).

→ Features: [session-detail](../features/session-detail/spec.md),
  [ai-example](../features/ai-example/spec.md)

### M5 — Anki Export
Botão de export na tela de detalhe da sessão: chama `GET /sessions/{id}/export`,
salva o `.apkg` em diretório do app, abre share sheet do SO. O usuário
escolhe para onde enviar (Anki Mobile, AirDrop, email, Drive, etc.).

→ Feature: [anki-export](../features/anki-export/spec.md)

## Ordem de implementação

```
M0 foundation
   ↓
M1 sessions ────────────┐
   ↓                    │
M2 camera-ocr           │
   ↓                    │
M3 translation-result   │
                        ↓
                  M4 session-detail
                        ↓
                   M4 ai-example
                        ↓
                   M5 anki-export
```

## Fora do roadmap (backlog futuro)

- Modo "live OCR" (sem precisar tocar shutter — texto detectado continuamente).
- Áudio TTS para pronúncia.
- Histórico de palavras já adicionadas (dedup cross-session).
- Modo escuro custom (hoje confiamos no light mode do design system).
- Migração para self-hosted backend remoto (HTTPS + token simples).
- Tablet/desktop layout (responsive). Hoje: mobile only.

## Decisões pendentes

- **Bottom nav 3 tabs (Sessions / Scan / Cards) vs nested routing**: o design
  mostra 3 tabs mas "Cards" não tem tela própria definida. Decidir em M4 se
  "Cards" leva a uma busca global ou agrega todos os cards.
- **Cache local de sessões?** Hoje, todo refresh chama `GET /sessions`. Avaliar
  se vale cachear em memória ou em `shared_preferences` durante M1.
