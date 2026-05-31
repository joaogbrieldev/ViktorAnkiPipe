import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/data/dto/session_dto.dart';
import 'package:client/data/repositories/session_repository.dart';
import 'package:client/features/sessions/presentation/sessions_list_screen.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

SessionDto _makeSession({
  String id = 's1',
  String name = 'Chapter 1',
  int cardCount = 2,
}) =>
    SessionDto(
      id: id,
      name: name,
      cardCount: cardCount,
      createdAt: DateTime(2024),
    );

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
        routes: [
          GoRoute(
            path: 'sessions/:id',
            builder: (_, state) => Scaffold(
              body: Text('detail:${state.pathParameters['id']}'),
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  late MockSessionRepository mockRepo;

  setUp(() {
    mockRepo = MockSessionRepository();
  });

  group('SessionsListScreen', () {
    testWidgets('renders list of mocked sessions', (tester) async {
      final sessions = [
        _makeSession(id: 's1', name: 'Chapter 1'),
        _makeSession(id: 's2', name: 'Chapter 2'),
      ];
      when(() => mockRepo.list()).thenAnswer((_) async => sessions);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionsListScreen(),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Chapter 2'), findsOneWidget);
    });

    testWidgets('tapping + button opens NewSessionSheet', (tester) async {
      when(() => mockRepo.list()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionsListScreen(),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Nova sessão'), findsOneWidget);
    });

    testWidgets('submitting sheet calls create', (tester) async {
      final created = _makeSession(id: 's-new', name: 'New Session');
      when(() => mockRepo.list()).thenAnswer((_) async => []);
      when(() => mockRepo.create('New Session')).thenAnswer(
        (_) async => created,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionsListScreen(),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('session_name_field')),
        'New Session',
      );
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.create('New Session')).called(1);
    });

    testWidgets('swiping tile reveals delete background', (tester) async {
      final sessions = [_makeSession(id: 's1', name: 'Chapter 1')];
      when(() => mockRepo.list()).thenAnswer((_) async => sessions);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionsListScreen(),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('Chapter 1'),
        const Offset(-300, 0),
      );
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      when(() => mockRepo.list()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionsListScreen(),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma sessão'), findsOneWidget);
    });

    testWidgets('shows error view when repository throws', (tester) async {
      when(() => mockRepo.list()).thenThrow(Exception('network error'));

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionsListScreen(),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha ao carregar sessões'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}
