import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/core/error/api_exception.dart';
import 'package:client/data/repositories/session_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

const _session1 = {
  'id': 's1',
  'name': 'Chapter 1',
  'card_count': 3,
  'created_at': '2024-01-10T08:00:00.000Z',
};

const _session2 = {
  'id': 's2',
  'name': 'Chapter 2',
  'card_count': 0,
  'created_at': '2024-01-11T09:00:00.000Z',
};

void main() {
  late MockApiClient mockClient;
  late SessionRepository repository;

  setUp(() {
    mockClient = MockApiClient();
    repository = SessionRepository(mockClient);
  });

  group('SessionRepository.list', () {
    test('returns parsed sessions on 200', () async {
      when(() => mockClient.getJsonList('/sessions')).thenAnswer(
        (_) async => [_session1, _session2],
      );

      final sessions = await repository.list();

      expect(sessions.length, 2);
      expect(sessions[0].id, 's1');
      expect(sessions[0].name, 'Chapter 1');
      expect(sessions[0].cardCount, 3);
      expect(sessions[1].id, 's2');
    });

    test('returns empty list when backend returns []', () async {
      when(() => mockClient.getJsonList('/sessions')).thenAnswer(
        (_) async => [],
      );

      final sessions = await repository.list();
      expect(sessions, isEmpty);
    });

    test('propagates ApiException on 500', () async {
      when(() => mockClient.getJsonList('/sessions')).thenThrow(
        const ApiException(statusCode: 500, message: 'Server error'),
      );

      expect(
        () => repository.list(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('SessionRepository.create', () {
    test('posts body and returns parsed session on 201', () async {
      when(
        () => mockClient.postJson('/sessions', {'name': 'New Session'}),
      ).thenAnswer((_) async => {..._session1, 'name': 'New Session'});

      final session = await repository.create('New Session');
      expect(session.name, 'New Session');
      verify(
        () => mockClient.postJson('/sessions', {'name': 'New Session'}),
      ).called(1);
    });

    test('propagates ApiException on 422', () async {
      when(
        () => mockClient.postJson(any(), any()),
      ).thenThrow(
        const ApiException(statusCode: 422, message: 'Unprocessable'),
      );

      expect(
        () => repository.create('bad'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('SessionRepository.delete', () {
    test('calls delete endpoint with correct id', () async {
      when(() => mockClient.delete('/sessions/s1')).thenAnswer(
        (_) async {},
      );

      await repository.delete('s1');
      verify(() => mockClient.delete('/sessions/s1')).called(1);
    });

    test('propagates ApiException on 404', () async {
      when(() => mockClient.delete(any())).thenThrow(
        const ApiException(statusCode: 404, message: 'Not found'),
      );

      expect(
        () => repository.delete('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('propagates ApiException on 500', () async {
      when(() => mockClient.delete(any())).thenThrow(
        const ApiException(statusCode: 500, message: 'Error'),
      );

      expect(
        () => repository.delete('s1'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
