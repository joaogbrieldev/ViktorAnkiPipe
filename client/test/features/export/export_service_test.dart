import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/features/export/application/export_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  setUpAll(() => registerFallbackValue(const Duration()));

  late MockApiClient mockClient;
  late Directory tempDir;
  final capturedFiles = <List<XFile>>[];
  final capturedSubjects = <String?>[];

  setUp(() async {
    mockClient = MockApiClient();
    tempDir = await Directory.systemTemp.createTemp('export_test_');
    capturedFiles.clear();
    capturedSubjects.clear();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  ExportService makeService() => ExportService(
        mockClient,
        getDocumentsDir: () async => tempDir,
        shareFiles: (files, {subject}) async {
          capturedFiles.add(files);
          capturedSubjects.add(subject);
        },
      );

  void stubBytes(List<int> bytes) {
    when(
      () => mockClient.getBytes(any(), timeout: any(named: 'timeout')),
    ).thenAnswer((_) async => Uint8List.fromList(bytes));
  }

  group('export', () {
    test('calls getBytes with correct session path', () async {
      when(
        () => mockClient.getBytes(
          '/sessions/s1/export',
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

      await makeService().export(sessionId: 's1', sessionName: 'My Book');

      verify(
        () => mockClient.getBytes(
          '/sessions/s1/export',
          timeout: any(named: 'timeout'),
        ),
      ).called(1);
    });

    test('writes bytes to .apkg file in documents dir', () async {
      final bytes = [0xAA, 0xBB, 0xCC];
      stubBytes(bytes);

      await makeService().export(sessionId: 's1', sessionName: 'My Book');

      final files = tempDir.listSync();
      expect(files.length, 1);
      final file = files.first as File;
      expect(file.path, endsWith('.apkg'));
      expect(await file.readAsBytes(), bytes);
    });

    test('slugifies session name for filename', () async {
      stubBytes([1]);

      await makeService()
          .export(sessionId: 's1', sessionName: 'Harry Potter & Co.');

      expect(
        tempDir.listSync().first.path,
        endsWith('harry_potter_co.apkg'),
      );
    });

    test('re-export overwrites existing file', () async {
      stubBytes([1]);
      final service = makeService();
      await service.export(sessionId: 's1', sessionName: 'My Book');

      stubBytes([2, 3]);
      await service.export(sessionId: 's1', sessionName: 'My Book');

      final files = tempDir.listSync();
      expect(files.length, 1);
      expect(await (files.first as File).readAsBytes(), [2, 3]);
    });

    test('passes file and subject to share', () async {
      stubBytes([]);

      await makeService().export(sessionId: 's1', sessionName: 'My Book');

      expect(capturedFiles.length, 1);
      expect(capturedFiles.first.first.path, endsWith('.apkg'));
      expect(capturedSubjects.first, 'Importe no Anki');
    });

    test('returns DateTime of export', () async {
      stubBytes([]);
      final before = DateTime.now();

      final result =
          await makeService().export(sessionId: 's1', sessionName: 'Test');

      expect(result.millisecondsSinceEpoch,
          greaterThanOrEqualTo(before.millisecondsSinceEpoch));
    });

    test('throws CancelledExportException when cancelled before write', () async {
      stubBytes([1]);

      final cancellation = ExportCancellation()..cancelled = true;

      await expectLater(
        makeService().export(
          sessionId: 's1',
          sessionName: 'Test',
          cancellation: cancellation,
        ),
        throwsA(isA<CancelledExportException>()),
      );
      expect(capturedFiles, isEmpty);
    });

    test('deletes written file when cancelled after write', () async {
      stubBytes([1]);

      final cancellation = ExportCancellation();
      final service = ExportService(
        mockClient,
        getDocumentsDir: () async {
          cancellation.cancelled = true;
          return tempDir;
        },
        shareFiles: (files, {subject}) async {},
      );

      await expectLater(
        service.export(
          sessionId: 's1',
          sessionName: 'Test',
          cancellation: cancellation,
        ),
        throwsA(isA<CancelledExportException>()),
      );

      expect(tempDir.listSync(), isEmpty);
    });
  });

  group('slug', () {
    test('lowercases and replaces spaces with underscores', () async {
      stubBytes([]);

      await makeService()
          .export(sessionId: 's1', sessionName: 'The Great Gatsby');

      expect(
        tempDir.listSync().first.path,
        endsWith('the_great_gatsby.apkg'),
      );
    });

    test('strips non-word characters', () async {
      stubBytes([]);

      await makeService()
          .export(sessionId: 's1', sessionName: "Don't Stop!");

      expect(
        tempDir.listSync().first.path,
        endsWith('dont_stop.apkg'),
      );
    });
  });
}
