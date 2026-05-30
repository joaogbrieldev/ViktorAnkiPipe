# CLAUDE.md

Este arquivo dá contexto ao Claude Code ao trabalhar neste repositório (cliente Flutter).

## Visão geral do projeto

**ViktorAnkiPipe** é um sistema para acelerar o estudo de vocabulário ao ler livros em inglês. Fluxo: **câmera → OCR → tradução → `.apkg` Anki**.

Este diretório (`client/`) contém **apenas o app móvel Flutter**, responsável por:

- Capturar imagem da câmera traseira do device.
- Rodar OCR on-device via **Google ML Kit** (sem upload de imagem).
- Permitir que o usuário toque em palavras detectadas para traduzir.
- Conversar com o backend FastAPI para tradução, persistência de cards, frases de exemplo e exportação `.apkg`.
- Abrir share sheet do SO para enviar o `.apkg` ao Anki.

O backend vive em [`../server/`](../server/). API documentada em [`../server/CLAUDE.md`](../server/CLAUDE.md). Sem autenticação — uso pessoal.

## Componentes

| Diretório         | Linguagem      | Descrição                                                  |
| ----------------- | -------------- | ---------------------------------------------------------- |
| `lib/main.dart`   | Dart 3.11+     | Entrypoint, monta `ProviderScope(child: App())`            |
| `lib/app.dart`    | Dart           | `MaterialApp.router` com tema Kinetic Utility              |
| `lib/core/`       | Dart           | Theme, router, ApiClient, env, widgets compartilhados      |
| `lib/data/`       | Dart           | DTOs JSON, repositórios, paths da API                      |
| `lib/features/`   | Dart           | Um pacote por feature: presentation + application          |
| `design/`         | PNG + HTML     | Referência visual exportada do Stitch (Kinetic Utility)    |

## Como funciona

```
Tap em Scan
   ↓
Permissão de câmera (1x)
   ↓
Preview ao vivo + framing brackets
   ↓
Tap no shutter → foto congela
   ↓
ML Kit (TextRecognizer, latin) processa imagem on-device
   ↓
Tokens viram retângulos azuis tappable (bg primary/20)
   ↓
Tap em token → push /result
   ↓
POST /translate (ou /sessions/{id}/cards) no backend
   ↓
Bottom sheet exibe Termo / Tradução / Contexto
   ↓
Tap "Adicionar ao deck" → card persistido na sessão
```

Exportação:

```
Detalhe da sessão → "Exportar"
   ↓
GET /sessions/{id}/export (streaming bytes)
   ↓
Bytes salvos em Documents (path_provider)
   ↓
Share.shareXFiles(...) → Anki / AirDrop / Drive / etc.
```

## Stack

- **Flutter 3.11+** / **Dart SDK ^3.11.5** — fixado no `pubspec.yaml`
- **flutter_riverpod** — gerenciamento de estado (AsyncNotifier, StateNotifier)
- **go_router** — rotas declarativas com `ShellRoute` para bottom nav iOS-like
- **http** — client REST simples (sem `dio`; o backend não exige interceptors)
- **dart:convert** + classes manuais — JSON sem code-gen
- **camera** — preview e captura
- **google_mlkit_text_recognition** — OCR on-device (cresce APK ~10–20MB)
- **share_plus + path_provider** — salvar `.apkg` e abrir share sheet
- **shared_preferences** — base URL / preferências leves
- **permission_handler** — fallback de "abrir Configurações" se câmera negada
- **flutter_svg** — render do logo SVG
- **flutter_test + mocktail** — testes (unit + widget)
- **flutter_lints** — lints estritos via `analysis_options.yaml`

## Setup

```bash
cd client
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

Para apontar para outro backend (ex: emulador Android contra host local):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator
flutter run --dart-define=API_BASE_URL=http://192.168.0.X:8000 # iOS device em LAN
```

Variáveis de ambiente lidas via `String.fromEnvironment` em `lib/core/env/env.dart`. **Não há `.env`** — só `--dart-define`.

### iOS

`ios/Runner/Info.plist` deve conter:

```xml
<key>NSCameraUsageDescription</key>
<string>ViktorAnkiPipe usa a câmera para capturar texto em inglês.</string>
```

### Android

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

`minSdkVersion >= 21` (já default em projetos novos).

## Comandos de desenvolvimento

```bash
# Rodar app (dev)
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# Build release Android
flutter build apk --release --dart-define=API_BASE_URL=https://meu-host

# Build release iOS
flutter build ios --release --dart-define=API_BASE_URL=https://meu-host

# Análise estática
flutter analyze

# Testes
flutter test
flutter test --coverage
flutter test test/features/sessions     # diretório
flutter test test/features/sessions/sessions_controller_test.dart -n "creates"  # filtro
```

## Estrutura do projeto

```
client/
├── pubspec.yaml
├── analysis_options.yaml
├── assets/
│   ├── fonts/Inter/                  # 4 weights .ttf
│   └── logo.svg
├── design/                           # referência do Stitch
│   ├── 01-sessions.png + .html
│   ├── 02-camera.png + .html
│   ├── 03-result.png + .html
│   └── logo.svg
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── env/env.dart              # API_BASE_URL
│   │   ├── theme/                    # Kinetic Utility (colors, typography, spacing, theme)
│   │   ├── router/                   # GoRouter + ShellRoute
│   │   ├── error/                    # ApiException
│   │   └── widgets/                  # AppShell, GlassAppBar, GroupedListCard, PrimaryButton
│   ├── data/
│   │   ├── api/                      # ApiClient, paths
│   │   ├── dto/                      # SessionDto, CardDto, ...
│   │   └── repositories/             # SessionRepository, CardRepository, TranslateRepository
│   └── features/
│       ├── sessions/                 # lista, criar, deletar
│       ├── camera/                   # preview, captura, OCR
│       ├── translation_result/       # sheet de tradução
│       ├── session_detail/           # cards da sessão
│       ├── ai_example/               # gerar frase exemplo
│       └── export/                   # `.apkg` + share
└── test/
    ├── smoke_test.dart
    ├── core/
    └── features/
```

> Cada feature segue **application/** + **presentation/**. DTOs vivem em `lib/data/`. Repositórios são únicos por bounded-context, não por feature.

## Endpoints consumidos

Espelho do backend ([`../server/CLAUDE.md`](../server/CLAUDE.md)):

| Quem chama                    | Método | Rota                             |
| ----------------------------- | ------ | -------------------------------- |
| `SessionsController`          | GET    | `/sessions`                      |
| `SessionsController`          | POST   | `/sessions`                      |
| `SessionsController`          | DELETE | `/sessions/{id}`                 |
| `SessionDetailController`     | GET    | `/sessions/{id}`                 |
| `TranslateRepository`         | POST   | `/translate`                     |
| `CardRepository.addBatch`     | POST   | `/sessions/{id}/cards`           |
| `CardRepository.delete`       | DELETE | `/sessions/{id}/cards/{card_id}` |
| `CardRepository.generateExample` | POST | `/cards/{card_id}/example`     |
| `ExportService`               | GET    | `/sessions/{id}/export`          |
| (smoke check, opcional)       | GET    | `/health`                        |

## Design system — Kinetic Utility

Fonte oficial: projeto Stitch `80654186402528267`. Exportado em `design/`.

Tokens principais (mapeados em `lib/core/theme/`):

| Token Stitch          | Cor / valor      | Dart helper                |
| --------------------- | ---------------- | -------------------------- |
| primary               | `#007AFF`        | `AppColors.primary`        |
| secondary             | `#5856D6`        | `AppColors.secondary`      |
| tertiary              | `#9E3D00`        | `AppColors.tertiary`       |
| background            | `#F2F2F7`        | `AppColors.background`     |
| surface (card)        | `#FFFFFF`        | `AppColors.surface`        |
| error                 | `#BA1A1A`        | `AppColors.error`          |
| margin-main           | 16               | `AppSpacing.lg`            |
| stack-md              | 12               | `AppSpacing.md`            |
| stack-lg              | 24               | `AppSpacing.xl`            |
| radius button         | 12               | `AppRadius.md`             |
| radius grouped card   | 16               | `AppRadius.lg`             |
| typography            | Inter            | `AppText.*` (8 estilos)    |

**Regras visuais:**

- iOS-inspired. Sem sombras em cards — depth via contraste branco/cinza.
- Bottom sheets e nav bars com `BackdropFilter(blur: 20)` (glassmorphism).
- Grouped list iOS: divider 0.5px alinhado ao texto (margem 20 à esquerda).
- Tap target mínimo 44px.
- Tipografia Inter substitui SF Pro nativo.

Detalhes completos: [`design/03-result.html`](design/03-result.html), tokens YAML embutidos no front matter do Stitch (em `.specs/project/PROJECT.md` há link).

## Decisões de design importantes

- **Sem login.** Pessoal/local. Base URL via `--dart-define`.
- **OCR no device.** Servidor nunca vê imagens. ML Kit cresce o APK, mas o trade-off vale: zero latência de rede no OCR.
- **Cliente burro.** Cache, dedup, tradução, IA, `.apkg` — tudo no server.
- **iOS-first em UX.** Mesmo no Android usamos paradigmas iOS porque o design system é assim e reduz fricção mental do usuário-alvo.
- **Riverpod + StateNotifier/AsyncNotifier.** Evita o boilerplate do Bloc; tipo-seguro; testável via `ProviderContainer`.
- **`http` em vez de `dio`.** Backend é trivial; um wrapper de 30 linhas resolve.
- **Sem code-gen JSON.** Modelos pequenos; `fromJson` manual mantém o tempo de build baixo.
- **Sem `flutter_native_splash`.** Splash mínima desenhada no Dart (logo SVG centralizado).

## Convenções de código

- **Lints estritos** — `flutter_lints` + regras adicionais em `analysis_options.yaml` (require_trailing_commas, prefer_const_*, no `print`).
- **Imports relativos dentro de uma feature**, absolutos cross-feature: `import 'package:client/data/dto/card_dto.dart'`. Nunca `import '../../../...'` para sair da feature.
- **Cross-domain por módulo**: `import 'package:client/features/sessions/application/sessions_controller.dart';` — não fazer reexport via barrel files.
- **Nomes em inglês** no código; copy/UI em PT-BR.
- **`final` sempre que possível**; campos não-mutáveis preferidos.
- **DTOs imutáveis** com `final` em todos os campos.
- **Schemas separados I/O**: `XDto` para resposta do backend, `XCreateBody` para POST.
- **Sem `Singleton` manual**: usar Riverpod `Provider` para singletons (ApiClient, repositories).
- **Type hints** em qualquer função pública; preferir `Future<T>` sobre `Future<void>` quando o valor importa.

## Padrões de teste

**Testes são obrigatórios.** Nenhuma feature vai para produção sem cobertura. Regra: se não tem teste, não está pronto.

- **Unit** — controllers/state e repositórios com `mocktail`. Mock do `ApiClient` é o padrão.
- **Widget** — telas via `WidgetTester` + `ProviderScope(overrides: ...)` para substituir providers reais por fakes.
- **Golden tests** — para overlays visuais (`ViewfinderOverlay`, `_OcrTokens`).
- **Sem testes de câmera real** — só unitários do `CameraController` com `CameraController` mockado. Câmera/OCR real é verificação manual.
- **Sem chamadas de rede reais** — `mocktail` mocka `http.Client` ou o `ApiClient` inteiro.
- **Cobertura alvo**: ≥ 70% por feature, ≥ 80% nos repositórios/controllers.

## Armadilhas conhecidas

- **APK cresce ~10–20MB** com `google_mlkit_text_recognition` pelos modelos nativos. Documentar no README do projeto.
- **iOS Info.plist obrigatório** — sem `NSCameraUsageDescription` o app crasha ao acessar câmera. Adicionar no setup.
- **CameraController + lifecycle** — sempre dispor em `inactive`/`paused`; sem isso o iOS reclama de "camera in use" ao retomar.
- **`getBytes` precisa de timeout maior** — `.apkg` pode levar segundos. Default 30s; usar 60–120s em `ApiClient.getBytes`.
- **`share_plus` + Android FileProvider** — o pacote já gera os XML automaticamente; só não funciona se o build é feito offline. Use `flutter clean && flutter pub get` se quebrar.
- **OCR bounding boxes** — vêm em coordenadas da imagem original (largura/altura raw da foto). Converter para tela exige fator de escala derivado do `RenderBox` real do widget e `BoxFit.cover`.
- **Riverpod 2.x AsyncNotifier** — `build()` é chamado uma vez; para refetch use `ref.invalidateSelf()` ou método próprio como `refresh()` que reseta `state`.
- **GoRouter ShellRoute** — guards de auth não se aplicam aqui (sem auth), mas se um dia adicionarmos: `redirect` no provider raiz, não dentro do shell.

## Fluxos comuns

### Adicionar uma nova tela

1. Criar pasta `lib/features/<feature>/{application,presentation,widgets}/`.
2. Definir `XController` em `application/` se houver estado.
3. Definir tela em `presentation/<screen>.dart`.
4. Adicionar rota em `lib/core/router/app_router.dart`.
5. Adicionar testes em `test/features/<feature>/`.

### Adicionar um endpoint da API

1. Definir DTO em `lib/data/dto/`.
2. Adicionar método ao repositório apropriado em `lib/data/repositories/`.
3. Se for novo bounded-context, criar novo repositório + provider.
4. Cobrir com unit test usando `mocktail`.

### Trocar o design system

Editar tokens em `lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`. Tudo no app refere via `AppColors.*` etc. — recompilar e está aplicado.

## Próximos passos pendentes

Em ordem (espelha `.specs/project/ROADMAP.md`):

1. **M0 — Foundation** ([`tasks`](../.specs/features/foundation/tasks.md)) — esqueleto do app, tema, router, ApiClient. Boilerplate atual ainda intacto.
2. **M1 — Sessions** ([`tasks`](../.specs/features/sessions/tasks.md)) — lista, criar, deletar, buscar.
3. **M2 — Camera + OCR** ([`tasks`](../.specs/features/camera-ocr/tasks.md)).
4. **M3 — Translation Result** ([`tasks`](../.specs/features/translation-result/tasks.md)).
5. **M4 — Session Detail + AI Example** ([`session-detail tasks`](../.specs/features/session-detail/tasks.md), [`ai-example tasks`](../.specs/features/ai-example/tasks.md)).
6. **M5 — Anki Export** ([`tasks`](../.specs/features/anki-export/tasks.md)) — depende de endpoints pendentes no servidor.
