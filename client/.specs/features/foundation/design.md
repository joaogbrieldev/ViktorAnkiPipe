# Design: Foundation

## Estrutura de pastas

```
client/
├── lib/
│   ├── main.dart                     # runApp(ProviderScope(child: App()))
│   ├── app.dart                      # MaterialApp.router + ThemeData
│   ├── core/
│   │   ├── env/
│   │   │   └── env.dart              # const API_BASE_URL via String.fromEnvironment
│   │   ├── theme/
│   │   │   ├── app_colors.dart       # AppColors.primary, secondary, ...
│   │   │   ├── app_typography.dart   # TextTheme (Inter), text styles do design
│   │   │   ├── app_spacing.dart      # 4 / 8 / 12 / 16 / 24 / 34
│   │   │   └── app_theme.dart        # ThemeData light
│   │   ├── router/
│   │   │   ├── app_router.dart       # GoRouter raiz com ShellRoute
│   │   │   └── routes.dart           # const path strings
│   │   ├── error/
│   │   │   ├── api_exception.dart    # ApiException(statusCode, message)
│   │   │   └── result.dart           # sealed Result<T> = Ok<T> | Err<T> (sem packages)
│   │   └── widgets/
│   │       ├── app_scaffold.dart     # AppShell com bottom nav (3 tabs)
│   │       ├── glass_app_bar.dart    # AppBar com backdrop blur (iOS-style)
│   │       ├── grouped_list_card.dart # container white + radius 16 para listas
│   │       └── primary_button.dart   # FilledButton com 14h e radius 12
│   ├── data/
│   │   ├── api/
│   │   │   ├── api_client.dart       # HttpClientWrapper (get/post/delete)
│   │   │   └── api_paths.dart        # const _sessions = '/sessions' etc.
│   │   ├── dto/                      # (vazio por enquanto, populated por feature)
│   │   └── repositories/             # (idem)
│   └── features/                     # (placeholder por feature)
│       ├── sessions/
│       ├── camera/
│       ├── translation_result/
│       ├── session_detail/
│       └── export/
├── assets/
│   ├── fonts/Inter/                  # arquivos .ttf (Regular/Medium/SemiBold/Bold)
│   └── logo.svg
└── test/
    └── smoke_test.dart               # garante app inicializa
```

## Configuração

### pubspec.yaml — dependências

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.1
  go_router: ^14.6.0
  http: ^1.2.2
  camera: ^0.11.0
  google_mlkit_text_recognition: ^0.14.0
  share_plus: ^10.1.2
  path_provider: ^2.1.5
  shared_preferences: ^2.3.3
  flutter_svg: ^2.0.10

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - assets/logo.svg
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter/Inter-Regular.ttf
        - asset: assets/fonts/Inter/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter/Inter-Bold.ttf
          weight: 700
```

> Versões mínimas — usar `flutter pub upgrade --major-versions` se houver patches.

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    require_trailing_commas: true
    avoid_print: true
    always_declare_return_types: true
```

## Design Tokens (Kinetic Utility → Dart)

### `app_colors.dart`
```dart
class AppColors {
  static const primary = Color(0xFF007AFF);          // System Blue
  static const secondary = Color(0xFF5856D6);        // System Indigo
  static const background = Color(0xFFF2F2F7);       // System Grouped Background
  static const surface = Color(0xFFFFFFFF);          // cards
  static const onSurface = Color(0xFF1A1B1F);
  static const onSurfaceVariant = Color(0xFF414755);
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);
  static const error = Color(0xFFBA1A1A);
  static const tertiary = Color(0xFF9E3D00);
  // OCR overlay highlight (primary at 10% opacity, used over camera)
  static Color get ocrHighlight => primary.withOpacity(0.10);
}
```

### `app_typography.dart`
Mapeia 1-para-1 os tokens do design system. Cada estilo retorna um `TextStyle`
com `fontFamily: 'Inter'`, weight, size, height e letterSpacing exatos:

| Token Stitch          | TextStyle helper           |
| --------------------- | -------------------------- |
| `nav-title`           | `AppText.navTitle`         |
| `headline-lg-mobile`  | `AppText.headlineLgMobile` |
| `body-md`             | `AppText.bodyMd`           |
| `callout`             | `AppText.callout`          |
| `subhead`             | `AppText.subhead`          |
| `footnote`            | `AppText.footnote`         |
| `label-caps`          | `AppText.labelCaps`        |

### `app_spacing.dart`
```dart
class AppSpacing {
  static const xs = 4.0;     // stack-sm
  static const sm = 8.0;     // gutter
  static const md = 12.0;    // stack-md
  static const lg = 16.0;    // margin-main
  static const xl = 24.0;    // stack-lg
  static const safeBottom = 34.0;
}

class AppRadius {
  static const sm = 4.0;
  static const md = 12.0;    // buttons, inputs (10–12 no design)
  static const lg = 16.0;    // grouped cards
  static const full = 9999.0;
}
```

### `app_theme.dart`
```dart
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Inter',
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSurface: AppColors.onSurface,
  ),
  cardTheme: CardTheme(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),  // 14h * 4 = 56
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: AppText.navTitle,
    ),
  ),
  // ...inputDecoration, listTile, appBar...
);
```

## HTTP Client

`api_client.dart` — wrapper sobre `http.Client` que centraliza:

- Base URL via `Env.apiBaseUrl` (constante).
- Header `Content-Type: application/json` por padrão.
- `Future<T> get/post/delete/getBytes` com parsing.
- Lança `ApiException(statusCode, body)` se status ≥ 400.
- `timeout: Duration(seconds: 30)` para tradução; `60s` para `/export`.

```dart
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, dynamic>> getJson(String path) async { ... }
  Future<Map<String, dynamic>> postJson(String path, Object body) async { ... }
  Future<void> delete(String path) async { ... }
  Future<Uint8List> getBytes(String path, {Duration timeout = const Duration(seconds: 60)}) async { ... }
}

// Riverpod provider:
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
```

## Routing

```dart
final appRouter = GoRouter(
  initialLocation: '/sessions',
  routes: [
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/sessions', builder: (_, __) => const SessionsListScreen()),
        GoRoute(path: '/sessions/:id', builder: (_, s) => SessionDetailScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/scan', builder: (_, __) => const CameraScreen()),
        GoRoute(path: '/cards', builder: (_, __) => const CardsScreen()),
      ],
    ),
    GoRoute(path: '/result', builder: (_, s) => TranslationResultScreen(...)),  // fullscreen, fora do shell
  ],
);
```

`AppShell` é um `Scaffold` com `BottomNavigationBar` (Sessions / Scan / Cards) +
`backdrop-blur` para emular o nav iOS.

## Verificação manual
- `flutter analyze` zero issues.
- `flutter run` em iOS/Android abre splash → /sessions (placeholder).
- Trocar para `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
  altera a constante (não há request ainda, mas `Env.apiBaseUrl` reflete).
