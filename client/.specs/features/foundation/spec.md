# Feature: Foundation

## Objetivo
Preparar o esqueleto do app Flutter: dependências, configuração, theme,
roteamento, cliente HTTP, lints. Após esta feature, qualquer outra
feature pode ser implementada sem mexer em infraestrutura.

## Escopo
- Editar `pubspec.yaml` com todas as dependências do roadmap (M0–M5).
- Configurar `analysis_options.yaml` (já existe — adicionar regras estritas).
- Criar estrutura de pastas (`lib/core`, `lib/data`, `lib/features`).
- Aplicar design system **Kinetic Utility** como `ThemeData` global.
- Configurar `go_router` com shell route para a bottom nav.
- Cliente HTTP fino sobre `http` com base URL via `--dart-define`.
- Tela de splash mínima usando o logo Stitch (`design/logo.svg`).
- Tela de erro/offline global.
- `pubspec.yaml` declara assets/fontes Inter.

## Fora do escopo
- Telas funcionais (sessions, camera, result) — outras features.
- Persistência local além de `shared_preferences` para base URL.
- Dark mode.

## Critérios de aceitação
1. `flutter pub get` resolve sem erros em macOS + Android.
2. `flutter run` abre o app com splash + bottom nav vazia (3 tabs placeholder).
3. `flutter analyze` retorna 0 issues.
4. `flutter test` passa (smoke test do widget root).
5. Cores, fontes e radii do `ThemeData` correspondem ao Kinetic Utility:
   - `primary = #007AFF`
   - `secondary = #5856D6`
   - `surface = #F2F2F7` (background app)
   - `Inter` como fonte padrão
   - `cardTheme.shape` com radius 16.
6. Mudando o argumento `--dart-define=API_BASE_URL=...` o app aponta para
   um backend diferente sem rebuild da estrutura.

## Dependências
- Backend não precisa estar rodando.
- Nenhuma outra feature.

## Design de referência
- [`client/design/01-sessions.png`](../../../client/design/01-sessions.png) (cores/tipografia visíveis no header e tabs).
- Design system completo no PROJECT.md.
