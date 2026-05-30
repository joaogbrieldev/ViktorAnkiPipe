# Tasks: Camera + OCR

> Cada tarefa é atômica e verificável em isolamento.

## Setup nativo

- [ ] **C-01** iOS: adicionar `NSCameraUsageDescription` em `Info.plist`.
  - Verificação: `flutter run` em iOS device abre prompt de permissão.
- [ ] **C-02** Android: confirmar permissão `CAMERA` em `AndroidManifest.xml`
       e `minSdkVersion >= 21`.
  - Verificação: build Android com `flutter build apk --debug` passa.
- [ ] **C-03** Documentar em `client/CLAUDE.md` que o build cresce ~10-20MB
       por causa do ML Kit (ver "Armadilhas").

## State

- [ ] **C-04** Definir classes `CameraState`, `DetectedWord`, `WordSelection`
       em `lib/features/camera/application/camera_state.dart`.
- [ ] **C-05** Criar `lib/features/camera/application/camera_controller.dart`
       com `StateNotifier<CameraState>`:
  - `initialize()` lista câmeras, abre traseira.
  - `dispose()` libera controller e `TextRecognizer`.
  - métodos `toggleFlash`, `flipCamera`.
- [ ] **C-06** Implementar `capture()` e `_runOcr(file)` (ML Kit).
  - Verificação: teste unitário com `CameraController` mockado garante
    `state.words` populado após sucesso.
- [ ] **C-07** Provider Riverpod `activeSessionProvider`, `pendingTranslationProvider`.

## UI

- [ ] **C-08** Substituir placeholder de `/scan` por `CameraScreen` em
       `lib/features/camera/presentation/camera_screen.dart`.
- [ ] **C-09** Implementar `ViewfinderOverlay` (4 cantos brackets).
  - Verificação: golden test do overlay 390×844.
- [ ] **C-10** Implementar `_TopBar` (close + hint pill + flash) com
       backdrop blur sobre os botões.
- [ ] **C-11** Implementar `_BottomControls` (thumbnail / shutter / flip).
- [ ] **C-12** Implementar `_OcrTokens` que converte boundingBox da imagem
       para coordenadas de tela usando `imageSize` real e `RenderBox`.
  - Verificação: para um `DetectedWord` em `Rect(100, 100, 50, 20)` numa
    imagem 1080×1920 renderizada em 390×693 (BoxFit.cover), o token
    aparece na posição proporcional correta.
- [ ] **C-13** Estado "review" (após captura): trocar bottom controls para
       "Refazer" / "N palavras detectadas" / "Concluir".
- [ ] **C-14** Lifecycle: `WidgetsBindingObserver` dispõe câmera em
       `inactive`/`paused` e reinicia em `resumed`.

## Permissões

- [ ] **C-15** Em erro de permissão (`CameraException` com código de denied),
       mostrar `CameraDeniedView` com botão "Abrir Configurações"
       (`permission_handler.openAppSettings`).
  - Adicionar `permission_handler: ^11.3.1` ao pubspec.

## Integração

- [ ] **C-16** `_OcrTokens.onTap` seta `pendingTranslationProvider` e chama
       `context.push('/result')`.
- [ ] **C-17** Quando a sessão "ativa" está definida (vinda de
       `/sessions/{id}/scan`), gravar em `activeSessionProvider` no
       `initState`.

## Testes

- [ ] **C-18** `test/features/camera/camera_controller_test.dart` — estado
       transita corretamente em `capture()`.
- [ ] **C-19** `test/features/camera/ocr_tokens_test.dart` — golden test
       de overlay com bounding boxes mockados.

## Verificação manual

- [ ] **C-20** iOS real device: tab Scan → permissão → preview → shutter →
       texto detectado dentro de 2s.
- [ ] **C-21** Android real device: idem.
- [ ] **C-22** Background → reabrir → sem crash, câmera retoma.

## Dependências
- Depende de **Foundation** (Foundation completa, M0).
- Bloqueia [translation-result](../translation-result/spec.md) (sheet consome
  `pendingTranslationProvider`).
