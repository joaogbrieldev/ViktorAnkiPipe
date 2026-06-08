import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/session_detail_dto.dart';
import 'package:client/data/dto/session_dto.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/session_repository.dart';
import 'package:client/features/session_detail/presentation/session_detail_screen.dart';
import 'package:client/features/sessions/application/sessions_controller.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

class MockCardRepository extends Mock implements CardRepository {}

SessionDto _session() => SessionDto(
      id: 's1',
      name: 'Chapter 1',
      cardCount: 2,
      createdAt: DateTime(2024),
    );

CardDto _card({String id = 'c1'}) => CardDto(
      id: id,
      sessionId: 's1',
      sourceText: 'hello',
      translatedText: 'olá',
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
            path: 'scan',
            builder: (context, state) =>
                const Scaffold(body: Text('Scan screen')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockSessionRepository mockSessionRepo;
  late MockCardRepository mockCardRepo;

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    mockCardRepo = MockCardRepository();
  });

  group('SessionDetailScreen', () {
    testWidgets('renders session name and cards', (tester) async {
      final detail = SessionDetailDto(
        session: _session(),
        cards: [_card(id: 'c1'), _card(id: 'c2')],
      );
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => detail);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionDetailScreen(id: 's1'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1'), findsWidgets);
      expect(find.text('hello'), findsWidgets);
    });

    testWidgets('shows empty state when no cards', (tester) async {
      final detail = SessionDetailDto(
        session: _session(),
        cards: const [],
      );
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => detail);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionDetailScreen(id: 's1'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum card ainda'), findsOneWidget);
    });

    testWidgets('tapping card opens detail sheet', (tester) async {
      final detail = SessionDetailDto(
        session: _session(),
        cards: [_card()],
      );
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => detail);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionDetailScreen(id: 's1'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('hello').first);
      await tester.pumpAndSettle();

      expect(find.text('Palavra'), findsOneWidget);
      expect(find.text('Tradução'), findsOneWidget);
    });

    testWidgets('swipe on card tile reveals delete background', (tester) async {
      final detail = SessionDetailDto(
        session: _session(),
        cards: [_card()],
      );
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => detail);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionDetailScreen(id: 's1'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('hello').first,
        const Offset(-300, 0),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(Dismissible),
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error view when repository throws', (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(
        _buildTestApp(
          child: const SessionDetailScreen(id: 's1'),
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha ao carregar sessão'), findsOneWidget);
    });

    testWidgets('delete button removes session and navigates back', (
      tester,
    ) async {
      final detail = SessionDetailDto(
        session: _session(),
        cards: [_card()],
      );
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => detail);
      when(() => mockSessionRepo.list()).thenAnswer((_) async => [_session()]);
      when(() => mockSessionRepo.delete('s1')).thenAnswer((_) async {});

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/sessions',
            builder: (context, state) =>
                const Scaffold(body: Text('Sessions list')),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => SessionDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
        initialLocation: '/sessions/s1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Excluir sessão'), findsOneWidget);

      await tester.tap(find.byTooltip('Excluir sessão'));
      await tester.pumpAndSettle();

      expect(find.text('Deletar sessão?'), findsOneWidget);

      await tester.tap(find.text('Deletar'));
      await tester.pumpAndSettle();

      verify(() => mockSessionRepo.delete('s1')).called(1);
      expect(find.text('Sessions list'), findsOneWidget);
    });
  });
}
