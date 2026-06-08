import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/core/error/api_exception.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/word_selection.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/translate_repository.dart';
import 'package:client/features/translation_result/application/translation_controller.dart';

class MockCardRepository extends Mock implements CardRepository {}

class MockTranslateRepository extends Mock implements TranslateRepository {}

CardDto _makeCard({
  String id = 'c1',
  String sessionId = 's1',
  String source = 'serendipity',
  String translated = 'serendipidade',
}) =>
    CardDto(
      id: id,
      sessionId: sessionId,
      sourceText: source,
      translatedText: translated,
      createdAt: DateTime(2024),
    );

const _sel = WordSelection(
  word: 'serendipity',
  contextLine: 'It was serendipity',
);

TranslationController _make({
  required MockCardRepository cards,
  required MockTranslateRepository translate,
  WordSelection sel = _sel,
}) =>
    TranslationController(cards, translate, sel);

void main() {
  late MockCardRepository mockCards;
  late MockTranslateRepository mockTranslate;

  setUp(() {
    mockCards = MockCardRepository();
    mockTranslate = MockTranslateRepository();
    registerFallbackValue(<CardCreateBody>[]);
  });

  group('initial state', () {
    test('starts with loading translation and null card', () {
      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      expect(ctrl.state.translation, isA<AsyncLoading<String>>());
      expect(ctrl.state.card, equals(const AsyncData<CardDto?>(null)));
    });
  });

  group('fetch', () {
    test('populates translation on success', () async {
      when(() => mockTranslate.translate('serendipity'))
          .thenAnswer((_) async => 'serendipidade');

      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      await ctrl.fetch();

      expect(ctrl.state.translation, equals(const AsyncData('serendipidade')));
      expect(ctrl.state.card, equals(const AsyncData<CardDto?>(null)));
    });

    test('sets translation to error on failure', () async {
      when(() => mockTranslate.translate(any())).thenThrow(
        const ApiException(statusCode: 503, message: 'unavailable'),
      );

      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      await ctrl.fetch();

      expect(ctrl.state.translation, isA<AsyncError<String>>());
      expect(ctrl.state.card, equals(const AsyncData<CardDto?>(null)));
    });

    test('re-fetch replaces error with new data', () async {
      var callCount = 0;
      when(() => mockTranslate.translate('serendipity')).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw const ApiException(statusCode: 503, message: 'err');
        }
        return 'serendipidade';
      });

      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      await ctrl.fetch();
      expect(ctrl.state.translation.hasError, isTrue);

      await ctrl.fetch();
      expect(ctrl.state.translation.valueOrNull, equals('serendipidade'));
    });
  });

  group('addToSession', () {
    test('sets card to data on success', () async {
      final card = _makeCard();
      when(
        () => mockCards.addBatch(
          sessionId: 's1',
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async => [card]);

      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      await ctrl.addToSession('s1');

      expect(ctrl.state.card, equals(AsyncData<CardDto?>(card)));
    });

    test('passes correct source text and context', () async {
      final card = _makeCard();
      when(
        () => mockCards.addBatch(
          sessionId: any(named: 'sessionId'),
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async => [card]);

      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      await ctrl.addToSession('s1');

      final captured = verify(
        () => mockCards.addBatch(
          sessionId: 's1',
          items: captureAny(named: 'items'),
        ),
      ).captured;

      final items = captured.first as List<CardCreateBody>;
      expect(items.length, 1);
      expect(items.first.sourceText, 'serendipity');
      expect(items.first.context, 'It was serendipity');
    });

    test('sets card to error without changing translation', () async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');
      when(
        () => mockCards.addBatch(
          sessionId: any(named: 'sessionId'),
          items: any(named: 'items'),
        ),
      ).thenThrow(const ApiException(statusCode: 500, message: 'err'));

      final ctrl = _make(cards: mockCards, translate: mockTranslate);
      await ctrl.fetch();
      await ctrl.addToSession('s1');

      expect(ctrl.state.card, isA<AsyncError<CardDto?>>());
      expect(
        ctrl.state.translation.valueOrNull,
        equals('serendipidade'),
        reason: 'translation must not change when addToSession fails',
      );
    });
  });

  group('provider', () {
    test('uses pending translation selection from provider', () {
      final container = ProviderContainer(
        overrides: [
          cardRepositoryProvider.overrideWithValue(mockCards),
          translateRepositoryProvider.overrideWithValue(mockTranslate),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(translationControllerProvider);
      expect(state.selection.word, isEmpty);
    });
  });
}
