# Tasks: Foundation

> Cada tarefa é atômica e verificável em isolamento.
> Marque `[x]` quando concluída.

## Setup do projeto

- [x] **F-01** Limpar `lib/main.dart` (remover counter app gerado).
  - Verificação: `lib/main.dart` tem só `runApp(const ProviderScope(child: App()))`.
- [x] **F-02** Adicionar deps em `pubspec.yaml` (lista completa em design.md).
  - Verificação: `flutter pub get` resolve sem erro; `pubspec.lock` atualiza.
- [x] **F-03** Substituir `analysis_options.yaml` pela versão estrita.
  - Verificação: `flutter analyze` roda; lints listados ativos.
- [x] **F-04** Baixar fontes Inter (Regular, Medium, SemiBold, Bold) para
       `assets/fonts/Inter/`. Origem: rsms/inter (GitHub).
  - Verificação: 4 `.ttf` presentes; `flutter pub get` mostra fontes em build log.
- [x] **F-05** Copiar `client/design/logo.svg` para `assets/logo.svg` e declarar
       em pubspec.
  - Verificação: `flutter_svg` carrega o asset em um widget de teste.

## Tokens e theme

- [x] **F-06** `lib/core/theme/app_colors.dart` com paleta Kinetic Utility.
  - Verificação: usar uma cor (`AppColors.primary`) em um widget de smoke test.
- [x] **F-07** `lib/core/theme/app_typography.dart` com `AppText.*` styles.
  - Verificação: imprimir `AppText.headlineLgMobile.fontSize` ⇒ `28.0`.
- [x] **F-08** `lib/core/theme/app_spacing.dart` (constants).
- [x] **F-09** `lib/core/theme/app_theme.dart` exportando `lightTheme`.
  - Verificação: smoke test instancia `MaterialApp(theme: lightTheme)` sem erro.

## Env e HTTP

- [x] **F-10** `lib/core/env/env.dart` com `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000')`.
  - Verificação: rodar `--dart-define=API_BASE_URL=foo` altera o getter.
- [x] **F-11** `lib/core/error/api_exception.dart` (classe simples).
- [x] **F-12** `lib/core/error/result.dart` — sealed `Result<T>` opcional
       (pode ser substituído por try/catch nos repositórios; decidir caso a caso).
- [x] **F-13** `lib/data/api/api_paths.dart` com strings de paths.
- [x] **F-14** `lib/data/api/api_client.dart` — wrapper sobre `http.Client`
       com `getJson`/`postJson`/`delete`/`getBytes` e `ApiException` para 4xx/5xx.
  - Verificação: teste unitário com `mocktail` mocka `http.Client` e valida
    erro 404 vira `ApiException`.

## Routing e shell

- [x] **F-15** `lib/core/router/routes.dart` (path constants).
- [x] **F-16** `lib/core/router/app_router.dart` com `GoRouter` raiz +
       `ShellRoute` para bottom nav.
  - Verificação: `appRouter.routerDelegate.currentConfiguration` mostra
    `/sessions` como rota inicial em smoke test.
- [x] **F-17** `lib/core/widgets/app_shell.dart` — `Scaffold` com
       `BottomNavigationBar` de 3 tabs (Sessions/Scan/Cards) e backdrop blur.
  - Verificação: tocar nas tabs muda a rota (testar com `widgetTester.tap`).
- [x] **F-18** Placeholder screens para `/sessions`, `/scan`, `/cards`
       (cada uma só com `Center(child: Text('TODO'))`).

## Widgets de base

- [x] **F-19** `lib/core/widgets/glass_app_bar.dart` — `PreferredSizeWidget`
       com `BackdropFilter` (blur 20), border 0.5px, alinhado ao spec.
- [x] **F-20** `lib/core/widgets/grouped_list_card.dart` — container branco,
       radius 16, padding 0, divider `0.5px` entre filhos (ml 20 para alinhar
       com texto, como no design).
- [x] **F-21** `lib/core/widgets/primary_button.dart` — wrap de `FilledButton`
       com ícone opcional, height fixa 56 (h-14 no Tailwind), radius 12.

## App entrypoint

- [x] **F-22** `lib/app.dart` — `App` é `MaterialApp.router(theme: lightTheme, routerConfig: appRouter)`.
- [x] **F-23** `lib/main.dart` reduzido para `runApp(const ProviderScope(child: App()))`.

## Testes

- [x] **F-24** `test/smoke_test.dart` — testa que `ProviderScope(child: App())`
       monta sem exceções.
- [x] **F-25** `test/api_client_test.dart` — testes unitários do `ApiClient`
       (status 200, 404, 500, parsing JSON inválido).

## Verificação final

- [x] **F-26** `flutter analyze` ⇒ 0 issues.
- [x] **F-27** `flutter test` ⇒ tudo verde.
- [ ] **F-28** `flutter run` em iOS sim e Android emulator abre app sem crash.

## Dependências entre tasks
- F-04 → F-07 (typography precisa das fontes)
- F-06..F-09 → F-22 (theme depende de tokens)
- F-10..F-14 → demais features dependem do `ApiClient`
- F-15..F-18 → F-22
- F-19..F-21 → consumidas pelas features de UI

## Notas
Quando todas as tarefas estiverem `[x]`, a feature foundation está pronta.
A próxima feature ([sessions](../sessions/spec.md)) pode começar.
