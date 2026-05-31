import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/core/error/api_exception.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/session_detail_dto.dart';
import 'package:client/data/dto/session_dto.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/session_repository.dart';
import 'package:client/features/session_detail/application/session_detail_controller.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockCardRepository extends Mock implements CardRepository {}

SessionDto _session({String id = 's1'}) => SessionDto(
      id: id,
      name: 'Test',
      cardCount: 0,
      createdAt: DateTime(2024),
    );

CardDto _card({String id = 'c1', String sessionId = 's1'}) => CardDto(
      id: id,
      sessionId: sessionId,
      sourceText: 'hello',
      translatedText: 'olá',
      createdAt: DateTime(2024),
    );

SessionDetailDto _detail({List<CardDto>? cards}) => SessionDetailDto(
      session: _session(),
      cards: cards ?? [_card(id: 'c1'), _card(id: 'c2')],
    );

void main() {
  late MockSessionRepository mockSessionRepo;
  late MockCardRepository mockCardRepo;
  late ProviderContainer container;

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    mockCardRepo = MockCardRepository();
    container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
        cardRepositoryProvider.overrideWithValue(mockCardRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('build', () {
    test('loads session detail from repository', () async {
      final detail = _detail();
      when(() => mockSessionRepo.getById('s1')).thenAnswer((_) async => detail);

      final result = await container.read(
        sessionDetailControllerProvider('s1').future,
      );

      expect(result.session.id, 's1');
      expect(result.cards.length, 2);
    });

    test('exposes error when repository throws', () async {
      when(() => mockSessionRepo.getById('s1')).thenThrow(
        const ApiException(statusCode: 404, message: 'Not found'),
      );

      await container
          .read(sessionDetailControllerProvider('s1').future)
          .catchError((_) => _detail());

      final state = container.read(sessionDetailControllerProvider('s1'));
      expect(state.hasError, isTrue);
    });
  });

  group('deleteCard', () {
    test('optimistically removes card from list', () async {
      final detail = _detail();
      when(() => mockSessionRepo.getById('s1')).thenAnswer((_) async => detail);
      when(
        () => mockCardRepo.delete(sessionId: 's1', cardId: 'c1'),
      ).thenAnswer((_) async {});

      await container.read(sessionDetailControllerProvider('s1').future);
      await container
          .read(sessionDetailControllerProvider('s1').notifier)
          .deleteCard('c1');

      final state =
          container.read(sessionDetailControllerProvider('s1')).valueOrNull!;
      expect(state.cards.length, 1);
      expect(state.cards.first.id, 'c2');
    });

    test('rolls back when delete fails', () async {
      final detail = _detail();
      when(() => mockSessionRepo.getById('s1')).thenAnswer((_) async => detail);
      when(
        () => mockCardRepo.delete(sessionId: 's1', cardId: 'c1'),
      ).thenThrow(const ApiException(statusCode: 500, message: 'error'));

      await container.read(sessionDetailControllerProvider('s1').future);

      try {
        await container
            .read(sessionDetailControllerProvider('s1').notifier)
            .deleteCard('c1');
      } catch (_) {}

      final state =
          container.read(sessionDetailControllerProvider('s1')).valueOrNull!;
      expect(state.cards.length, 2);
    });
  });

  group('setExampleFor', () {
    test('updates example sentence in-memory', () async {
      final detail = _detail(cards: [_card(id: 'c1')]);
      when(() => mockSessionRepo.getById('s1')).thenAnswer((_) async => detail);

      await container.read(sessionDetailControllerProvider('s1').future);
      await container
          .read(sessionDetailControllerProvider('s1').notifier)
          .setExampleFor('c1', 'Hello world!');

      final state =
          container.read(sessionDetailControllerProvider('s1')).valueOrNull!;
      expect(state.cards.first.exampleSentence, 'Hello world!');
    });
  });

  group('refresh', () {
    test('reloads detail from repository', () async {
      var callCount = 0;
      final batches = [
        _detail(cards: [_card(id: 'c1')]),
        _detail(cards: [_card(id: 'c1'), _card(id: 'c2')]),
      ];
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => batches[callCount++]);

      await container.read(sessionDetailControllerProvider('s1').future);
      await container
          .read(sessionDetailControllerProvider('s1').notifier)
          .refresh();

      final state =
          container.read(sessionDetailControllerProvider('s1')).valueOrNull!;
      expect(state.cards.length, 2);
    });
  });
}
