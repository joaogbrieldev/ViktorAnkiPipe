import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:client/core/error/api_exception.dart';
import 'package:client/data/api/api_client.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockHttpClient httpClient;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    httpClient = MockHttpClient();
    apiClient = ApiClient(client: httpClient);
  });

  group('ApiClient.getJson', () {
    test('returns parsed JSON on 200', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'id': '1', 'name': 'test'}),
          200,
        ),
      );

      final result = await apiClient.getJson('/test');
      expect(result['id'], '1');
    });

    test('throws ApiException on 404', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () => apiClient.getJson('/missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws ApiException on 500', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server error', 500));

      expect(
        () => apiClient.getJson('/error'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws FormatException on invalid JSON', () async {
      when(
        () => httpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('not-json', 200));

      expect(
        () => apiClient.getJson('/bad-json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ApiClient.postJson', () {
    test('sends body and returns parsed JSON on 200', () async {
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'created': true}), 200),
      );

      final result = await apiClient.postJson('/items', {'name': 'test'});
      expect(result['created'], true);
    });
  });

  group('ApiClient.delete', () {
    test('completes without error on 204', () async {
      when(
        () => httpClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('', 204));

      await expectLater(apiClient.delete('/items/1'), completes);
    });

    test('throws ApiException on 404', () async {
      when(
        () => httpClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      expect(
        () => apiClient.delete('/items/999'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
