import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/core/error/api_exception.dart';
import 'package:client/data/dto/session_dto.dart';
import 'package:client/data/repositories/session_repository.dart';
import 'package:client/features/sessions/application/sessions_controller.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

SessionDto _makeSession({
  String id = 's1',
  String name = 'Test',
  int cardCount = 0,
}) =>
    SessionDto(
      id: id,
      name: name,
      cardCount: cardCount,
      createdAt: DateTime(2024),
    );

void main() {
  late MockSessionRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockSessionRepository();
    container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('build (initial load)', () {
    test('loads sessions from repository', () async {
      final sessions = [_makeSession(id: 's1'), _makeSession(id: 's2')];
      when(() => mockRepo.list()).thenAnswer((_) async => sessions);

      final result = await container.read(
        sessionsControllerProvider.future,
      );

      expect(result.length, 2);
      expect(result[0].id, 's1');
    });

    test('exposes AsyncError when repository throws', () async {
      when(() => mockRepo.list()).thenThrow(
        const ApiException(statusCode: 500, message: 'err'),
      );

      await container.read(sessionsControllerProvider.future).catchError(
            (_) => <SessionDto>[],
          );

      final state = container.read(sessionsControllerProvider);
      expect(state.hasError, isTrue);
    });
  });

  group('create', () {
    test('prepends new session to list', () async {
      final existing = [_makeSession(id: 's1')];
      final created = _makeSession(id: 's2', name: 'New');
      when(() => mockRepo.list()).thenAnswer((_) async => existing);
      when(() => mockRepo.create('New')).thenAnswer((_) async => created);

      await container.read(sessionsControllerProvider.future);
      await container.read(sessionsControllerProvider.notifier).create('New');

      final state = container.read(sessionsControllerProvider).valueOrNull!;
      expect(state.first.id, 's2');
      expect(state.length, 2);
    });

    test('propagates error from repository without changing state', () async {
      final sessions = [_makeSession()];
      when(() => mockRepo.list()).thenAnswer((_) async => sessions);
      when(() => mockRepo.create(any())).thenThrow(
        const ApiException(statusCode: 422, message: 'invalid'),
      );

      await container.read(sessionsControllerProvider.future);

      expect(
        () => container.read(sessionsControllerProvider.notifier).create('x'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('delete', () {
    test('optimistically removes session from list', () async {
      final sessions = [
        _makeSession(id: 's1'),
        _makeSession(id: 's2'),
      ];
      when(() => mockRepo.list()).thenAnswer((_) async => sessions);
      when(() => mockRepo.delete('s1')).thenAnswer((_) async {});

      await container.read(sessionsControllerProvider.future);
      await container.read(sessionsControllerProvider.notifier).delete('s1');

      final state = container.read(sessionsControllerProvider).valueOrNull!;
      expect(state.length, 1);
      expect(state.first.id, 's2');
    });

    test('rolls back to previous state when delete fails', () async {
      final sessions = [_makeSession(id: 's1'), _makeSession(id: 's2')];
      when(() => mockRepo.list()).thenAnswer((_) async => sessions);
      when(() => mockRepo.delete('s1')).thenThrow(
        const ApiException(statusCode: 500, message: 'error'),
      );

      await container.read(sessionsControllerProvider.future);

      try {
        await container
            .read(sessionsControllerProvider.notifier)
            .delete('s1');
      } catch (_) {}

      final state = container.read(sessionsControllerProvider).valueOrNull!;
      expect(state.length, 2);
    });
  });

  group('refresh', () {
    test('reloads sessions from repository', () async {
      var callCount = 0;
      final batches = [
        [_makeSession(id: 's1')],
        [_makeSession(id: 's1'), _makeSession(id: 's2')],
      ];
      when(() => mockRepo.list()).thenAnswer((_) async => batches[callCount++]);

      await container.read(sessionsControllerProvider.future);
      await container.read(sessionsControllerProvider.notifier).refresh();

      final state = container.read(sessionsControllerProvider).valueOrNull!;
      expect(state.length, 2);
    });
  });
}
