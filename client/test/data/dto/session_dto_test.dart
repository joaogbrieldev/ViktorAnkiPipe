import 'package:flutter_test/flutter_test.dart';

import 'package:client/data/dto/session_dto.dart';

void main() {
  group('SessionDto.fromJson', () {
    test('parses numeric id from backend', () {
      final dto = SessionDto.fromJson({
        'id': 1,
        'name': 'Test Session',
        'created_at': '2026-05-31T15:06:18',
      });

      expect(dto.id, '1');
      expect(dto.name, 'Test Session');
      expect(dto.createdAt, DateTime.parse('2026-05-31T15:06:18'));
    });

    test('parses all fields correctly', () {
      final dto = SessionDto.fromJson({
        'id': 'abc-123',
        'name': 'Test Session',
        'card_count': 5,
        'created_at': '2024-01-15T10:30:00.000Z',
      });

      expect(dto.id, 'abc-123');
      expect(dto.name, 'Test Session');
      expect(dto.cardCount, 5);
      expect(dto.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('defaults card_count to 0 when null', () {
      final dto = SessionDto.fromJson({
        'id': 'abc',
        'name': 'No cards',
        'card_count': null,
        'created_at': '2024-01-15T10:00:00.000Z',
      });

      expect(dto.cardCount, 0);
    });

    test('defaults card_count to 0 when absent', () {
      final dto = SessionDto.fromJson({
        'id': 'abc',
        'name': 'No cards',
        'created_at': '2024-01-15T10:00:00.000Z',
      });

      expect(dto.cardCount, 0);
    });

    test('throws FormatException when id is missing', () {
      expect(
        () => SessionDto.fromJson({
          'name': 'Missing id',
          'created_at': '2024-01-15T10:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when name is missing', () {
      expect(
        () => SessionDto.fromJson({
          'id': 'abc',
          'created_at': '2024-01-15T10:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when created_at is missing', () {
      expect(
        () => SessionDto.fromJson({
          'id': 'abc',
          'name': 'No date',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on invalid date string', () {
      expect(
        () => SessionDto.fromJson({
          'id': 'abc',
          'name': 'Bad date',
          'created_at': 'not-a-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SessionDto.toCreateBody', () {
    test('returns map with name key', () {
      final body = SessionDto.toCreateBody('My Session');
      expect(body, {'name': 'My Session'});
    });
  });
}
