import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/features/camera/application/camera_controller.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockCameraController extends Mock implements CameraController {}

class MockCameraValue extends Mock implements CameraValue {}

class MockTextRecognizer extends Mock implements TextRecognizer {}

class MockRecognizedText extends Mock implements RecognizedText {}

class MockTextBlock extends Mock implements TextBlock {}

class MockTextLine extends Mock implements TextLine {}

class MockTextElement extends Mock implements TextElement {}

// ── Constants ────────────────────────────────────────────────────────────────

const backCam = CameraDescription(
  name: '0',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

void main() {
  late MockCameraController mockController;
  late MockCameraValue mockValue;
  late MockTextRecognizer mockRecognizer;

  setUpAll(() {
    registerFallbackValue(FlashMode.off);
    registerFallbackValue(ResolutionPreset.high);
    registerFallbackValue(backCam);
    registerFallbackValue(InputImage.fromFilePath(''));
  });

  setUp(() {
    mockController = MockCameraController();
    mockValue = MockCameraValue();
    mockRecognizer = MockTextRecognizer();

    when(() => mockValue.isInitialized).thenReturn(true);
    when(() => mockValue.isTakingPicture).thenReturn(false);
    when(() => mockController.value).thenReturn(mockValue);
    when(() => mockController.initialize()).thenAnswer((_) async {});
    when(() => mockController.dispose()).thenAnswer((_) async {});
    when(() => mockController.takePicture()).thenAnswer(
      (_) async => XFile('/fake/image.jpg'),
    );
    when(() => mockRecognizer.close()).thenAnswer((_) async {});
    when(() => mockRecognizer.processImage(any())).thenAnswer((_) async {
      final result = MockRecognizedText();
      when(() => result.blocks).thenReturn([]);
      return result;
    });
  });

  CameraNotifier makeNotifier({RecognizedText? recognizedText}) {
    if (recognizedText != null) {
      when(() => mockRecognizer.processImage(any()))
          .thenAnswer((_) async => recognizedText);
    }
    return CameraNotifier(
      camerasFactory: () async => [backCam],
      controllerFactory: (desc, preset) => mockController,
      recognizerFactory: () => mockRecognizer,
      imageSizeResolver: (file) async => const Size(1080, 1920),
    );
  }

  ProviderContainer makeContainer(CameraNotifier notifier) {
    final container = ProviderContainer(
      overrides: [
        cameraNotifierProvider.overrideWith((ref) => notifier),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('initialize()', () {
    test('sets controller and clears permissionDenied on success', () async {
      final notifier = makeNotifier();
      await notifier.initialize();

      expect(notifier.state.controller, equals(mockController));
      expect(notifier.state.permissionDenied, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('sets permissionDenied when camera access is denied', () async {
      final notifier = CameraNotifier(
        camerasFactory: () async => [backCam],
        controllerFactory: (desc, preset) =>
            throw CameraException('CameraAccessDenied', 'denied'),
        imageSizeResolver: (file) async => const Size(1080, 1920),
      );

      await notifier.initialize();

      expect(notifier.state.permissionDenied, isTrue);
      expect(notifier.state.controller, isNull);
    });

    test('sets error when no cameras are available', () async {
      final notifier = CameraNotifier(
        camerasFactory: () async => [],
        controllerFactory: (desc, preset) => mockController,
        imageSizeResolver: (file) async => const Size(1080, 1920),
      );

      await notifier.initialize();

      expect(notifier.state.error, isNotNull);
      expect(notifier.state.controller, isNull);
    });
  });

  group('capture()', () {
    test('does nothing when controller is null', () async {
      final notifier = makeNotifier();
      // Do NOT call initialize() — controller stays null.
      await notifier.capture();

      expect(notifier.state.isProcessing, isFalse);
      verifyNever(() => mockController.takePicture());
    });

    test('populates words after successful OCR', () async {
      final element = MockTextElement();
      when(() => element.text).thenReturn('hello');
      when(() => element.boundingBox)
          .thenReturn(const Rect.fromLTWH(100, 100, 50, 20));

      final line = MockTextLine();
      when(() => line.text).thenReturn('hello');
      when(() => line.elements).thenReturn([element]);

      final block = MockTextBlock();
      when(() => block.lines).thenReturn([line]);

      final recognizedText = MockRecognizedText();
      when(() => recognizedText.blocks).thenReturn([block]);

      final notifier = makeNotifier(recognizedText: recognizedText);
      await notifier.initialize();
      await notifier.capture();

      expect(notifier.state.isProcessing, isFalse);
      expect(notifier.state.capturedFrame, isNotNull);
      expect(notifier.state.imageSize, equals(const Size(1080, 1920)));
      expect(notifier.state.words.length, equals(1));
      expect(notifier.state.words.first.text, equals('hello'));
      expect(
        notifier.state.words.first.boundingBox,
        equals(const Rect.fromLTWH(100, 100, 50, 20)),
      );
    });

    test('sets capturedFrame with empty words when OCR finds nothing',
        () async {
      final notifier = makeNotifier();
      await notifier.initialize();
      await notifier.capture();

      expect(notifier.state.isProcessing, isFalse);
      expect(notifier.state.capturedFrame, isNotNull);
      expect(notifier.state.words, isEmpty);
    });
  });

  group('reset()', () {
    test('clears capturedFrame and words but keeps controller', () async {
      final notifier = makeNotifier();
      await notifier.initialize();
      await notifier.capture();
      expect(notifier.state.capturedFrame, isNotNull);

      notifier.reset();

      expect(notifier.state.capturedFrame, isNull);
      expect(notifier.state.words, isEmpty);
      expect(notifier.state.controller, equals(mockController));
    });
  });

  group('toggleFlash()', () {
    test('switches between off and torch', () async {
      when(() => mockController.setFlashMode(any())).thenAnswer((_) async {});
      final notifier = makeNotifier();
      await notifier.initialize();

      expect(notifier.state.flashMode, equals(FlashMode.off));

      await notifier.toggleFlash();
      expect(notifier.state.flashMode, equals(FlashMode.torch));

      await notifier.toggleFlash();
      expect(notifier.state.flashMode, equals(FlashMode.off));
    });
  });

  group('provider', () {
    test('initial state has no controller and is not processing', () {
      final notifier = makeNotifier();
      final container = makeContainer(notifier);

      final state = container.read(cameraNotifierProvider);
      expect(state.controller, isNull);
      expect(state.isProcessing, isFalse);
      expect(state.words, isEmpty);
    });
  });
}
