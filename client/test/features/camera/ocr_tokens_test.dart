import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/features/camera/application/camera_state.dart';
import 'package:client/features/camera/widgets/ocr_tokens.dart';

// Image size used throughout: 1080×1920 (portrait full-resolution capture).
const _imageSize = Size(1080, 1920);

// Test device size that approximates a real iPhone viewport (390×693).
const _deviceSize = Size(390, 693);

const _singleWord = DetectedWord(
  text: 'hello',
  boundingBox: Rect.fromLTWH(100, 100, 50, 20),
  contextLine: 'hello world',
);

/// Sets the tester surface to [_deviceSize] and registers a teardown to reset.
void _useDeviceSize(WidgetTester tester) {
  tester.view.physicalSize = _deviceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildOcrTokensWidget({
  List<DetectedWord> words = const [_singleWord],
  void Function(DetectedWord)? onTap,
}) {
  return MaterialApp(
    home: OcrTokens(
      words: words,
      imageSize: _imageSize,
      onTap: onTap ?? (word) {},
    ),
  );
}

void main() {
  group('coordinate mapping', () {
    testWidgets(
        'token is placed at the proportionally correct screen position',
        (tester) async {
      _useDeviceSize(tester);
      await tester.pumpWidget(buildOcrTokensWidget());

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(OcrTokens),
          matching: find.byType(Positioned),
        ),
      );

      // BoxFit.cover math for 1080×1920 → 390×693:
      //   scale = max(390/1080, 693/1920) ≈ 0.3611
      //   dx ≈ 0, dy ≈ 0  (near-identical aspect ratios)
      //   screenLeft = 100 * 0.3611 ≈ 36.1
      //   screenTop  = 100 * 0.3611 ≈ 36.1
      //   screenW    =  50 * 0.3611 ≈ 18.1
      //   screenH    =  20 * 0.3611 ≈  7.2
      expect(positioned.left, closeTo(36.1, 0.5));
      expect(positioned.top, closeTo(36.1, 0.5));
      expect(positioned.width, closeTo(18.1, 0.5));
      expect(positioned.height, closeTo(7.2, 0.5));
    });
  });

  group('interaction', () {
    testWidgets('calls onTap with the correct DetectedWord', (tester) async {
      _useDeviceSize(tester);
      DetectedWord? tapped;
      await tester.pumpWidget(
        buildOcrTokensWidget(onTap: (w) => tapped = w),
      );

      // Tap the center of the first token (≈36.1, 36.1 with size ≈18.1×7.2)
      await tester.tapAt(const Offset(45, 40));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.text, equals('hello'));
    });

    testWidgets('renders one token per DetectedWord', (tester) async {
      _useDeviceSize(tester);
      final words = [
        const DetectedWord(
          text: 'hello',
          boundingBox: Rect.fromLTWH(100, 100, 50, 20),
        ),
        const DetectedWord(
          text: 'world',
          boundingBox: Rect.fromLTWH(200, 200, 60, 20),
        ),
      ];

      await tester.pumpWidget(buildOcrTokensWidget(words: words));

      expect(
        find.descendant(
          of: find.byType(OcrTokens),
          matching: find.byType(Positioned),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('renders nothing when words list is empty', (tester) async {
      _useDeviceSize(tester);
      await tester.pumpWidget(buildOcrTokensWidget(words: const []));

      expect(
        find.descendant(
          of: find.byType(OcrTokens),
          matching: find.byType(Positioned),
        ),
        findsNothing,
      );
    });
  });

  group('golden', () {
    testWidgets('OcrTokens overlay matches golden snapshot', (tester) async {
      _useDeviceSize(tester);
      await tester.pumpWidget(buildOcrTokensWidget());
      await expectLater(
        find.byType(OcrTokens),
        matchesGoldenFile('goldens/ocr_tokens_overlay.png'),
      );
    });
  });
}
