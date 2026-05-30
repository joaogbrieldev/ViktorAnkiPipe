# Design: Camera + OCR

## Pacotes

- `camera: ^0.11.0` (oficial Flutter).
- `google_mlkit_text_recognition: ^0.14.0`.
- Permissão: usar `permission_handler` se necessário — `camera` já trata,
  mas iOS pede `NSCameraUsageDescription` no `Info.plist`.

## iOS / Android setup

### iOS — `ios/Runner/Info.plist`
```xml
<key>NSCameraUsageDescription</key>
<string>ViktorAnkiPipe usa a câmera para capturar texto em inglês.</string>
```
### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

`google_mlkit_text_recognition` adiciona pesos ML nativos: documentar no
README que o APK aumenta ~10-20MB.

## Tela

### Estado
```dart
class CameraState {
  final CameraController? controller;
  final FlashMode flashMode;
  final XFile? capturedFrame;       // não-null = modo "review"
  final List<DetectedWord> words;   // populated após OCR
  final bool isProcessing;
  final String? error;
}

class DetectedWord {
  final String text;
  final Rect boundingBox;            // em pixels da imagem original
  final String? contextLine;         // linha completa onde a palavra apareceu
}
```

### Controller
`lib/features/camera/application/camera_controller.dart` —
`StateNotifier<CameraState>` com métodos:

- `initialize()` — inicializa CameraController, lista cameras disponíveis,
  abre a traseira por padrão.
- `toggleFlash()` — alterna `FlashMode.off` <-> `FlashMode.torch`.
- `flipCamera()` — fecha controller atual, abre o próximo (frente/trás).
- `capture()` — `controller.takePicture()` → `XFile` → `_runOcr(file)`.
- `reset()` — descarta `capturedFrame`, `words`, retorna a preview live.
- `dispose()` — fecha controller e recognizer.

### `_runOcr(XFile file)`
```dart
Future<void> _runOcr(XFile file) async {
  state = state.copyWith(isProcessing: true, capturedFrame: file);
  final input = InputImage.fromFilePath(file.path);
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(input);
    final words = <DetectedWord>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          words.add(DetectedWord(
            text: element.text,
            boundingBox: element.boundingBox,
            contextLine: line.text,
          ));
        }
      }
    }
    state = state.copyWith(words: words, isProcessing: false);
  } finally {
    await recognizer.close();
  }
}
```

## UI

### Layout

```
Stack(
  fit: StackFit.expand,
  children: [
    // 1. Preview live ou imagem congelada
    if (capturedFrame == null)
      CameraPreview(controller)
    else
      Image.file(File(capturedFrame.path), fit: BoxFit.cover),

    // 2. Overlay com brackets (apenas em modo preview)
    if (capturedFrame == null) const ViewfinderOverlay(),

    // 3. Tokens detectados (apenas em modo review)
    if (capturedFrame != null && words.isNotEmpty)
      _OcrTokens(words: words, onTap: _handleWordSelected, imageSize: capturedFrame.size),

    // 4. Top hint pill + close + flash
    Positioned(top: safeTop, left: 0, right: 0, child: _TopBar(...)),

    // 5. Bottom controls
    Positioned(bottom: 0, left: 0, right: 0, child: _BottomControls(...)),
  ],
);
```

### `ViewfinderOverlay`
Pinta 4 quadrados de 32×32 com 2px de borda primary-container nos cantos
do frame de 288×192 (w-72 h-48) centralizado, radius 8.

### `_OcrTokens`
Para cada `DetectedWord`:
- converte `boundingBox` (coordenadas da imagem) → coordenadas da tela
  (proporção entre `imageSize` e `RenderBox` do Stack);
- desenha um `GestureDetector` com `Container(decoration: BoxDecoration(
  color: AppColors.primary.withOpacity(0.20), border: ...))`;
- `onTap` chama o callback com `(text, contextLine)`.

### Bottom controls (modo preview)
- `Row` espaçada com `MainAxisAlignment.spaceAround`:
  - thumbnail placeholder (48×48, rounded 8, surface-container-highest);
  - shutter button: `GestureDetector` → 80×80 ring branca; círculo interno
    com `AnimatedContainer` que escurece levemente no `onTapDown`;
  - flip camera button.

### Bottom controls (modo review)
- `Row`:
  - botão "Refazer" (ícone X, texto, transparent) → `controller.reset()`;
  - centro: indicador "N palavras detectadas" (small chip);
  - botão "Concluir" → fecha a tela / volta para sessão atual.

### Permissões

- No `initialize()` o `CameraController` lança se permissão não foi concedida.
- Em catch, mostrar UI dedicada:
  ```
  Center(
    column: [
      Icon(camera_alt), 
      Text("Precisamos da câmera"), 
      PrimaryButton("Abrir Configurações") → permission_handler.openAppSettings,
    ],
  )
  ```

### Lifecycle
A tela implementa `WidgetsBindingObserver`:
- `didChangeAppLifecycleState(AppLifecycleState.inactive)` → dispose
  controller para liberar a câmera.
- `.resumed` → re-inicializa.

Idem para a navegação por tab: `AutoDisposeStateNotifier` garante que ao
sair de `/scan`, o controller é disposed.

## Integração com translation-result

A `CameraScreen` recebe um callback `onWordSelected(WordSelection sel)`
ou usa Riverpod para publicar a seleção:

```dart
class WordSelection {
  final String word;
  final String? contextLine;
  final String? sessionId;   // sessão "destino" se houver active session
}

final activeSessionProvider = StateProvider<String?>((ref) => null);
final pendingTranslationProvider = StateProvider<WordSelection?>((ref) => null);
```

Quando uma palavra é tocada:
1. seta `pendingTranslationProvider`;
2. navega `context.push('/result')`.

A tela `result` lê o provider e dispara a tradução.

## Testes

Testes da câmera real são difíceis (precisa de device). Testes possíveis:

- `OcrTokenLayout` — given a list de `DetectedWord` e um tamanho de imagem,
  o widget renderiza retângulos nas posições corretas (golden test).
- `CameraController` (state notifier) com `CameraController` mockado:
  `capture()` transita para `isProcessing=true`, depois `false` com `words`.

## Verificação manual
- Em iOS device, abrir app → tab Scan → permissão pedida → preview ao vivo.
- Apontar para texto impresso, tocar shutter → ~1s depois palavras
  aparecem como caixas azuis tappable.
- Tap em palavra → navega para `/result`.
- "Refazer" → volta para preview live.
- Background o app → câmera é liberada (sem warning).
