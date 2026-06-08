import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/core/providers/active_session_provider.dart';
import 'package:client/core/providers/pending_translation_provider.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/word_selection.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/translate_repository.dart';
import 'package:client/features/translation_result/presentation/translation_result_screen.dart';

class MockCardRepository extends Mock implements CardRepository {}

class MockTranslateRepository extends Mock implements TranslateRepository {}

const _kSel = WordSelection(
  word: 'serendipity',
  contextLine: 'It was serendipity that we met',
);

CardDto _makeCard() => CardDto(
      id: 'c1',
      sessionId: 's1',
      sourceText: 'serendipity',
      translatedText: 'serendipidade',
      createdAt: DateTime(2024),
    );

Widget _buildApp({
  required MockTranslateRepository translate,
  required MockCardRepository cards,
  String? activeSessionId,
}) {
  // Parent + child routes so GoRouter has a stack to pop back to.
  final router = GoRouter(
    initialLocation: '/result',
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, state) =>
            const Scaffold(body: Text('previous screen')),
        routes: [
          GoRoute(
            path: 'result',
            builder: (ctx, state) => const TranslationResultScreen(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      pendingTranslationProvider.overrideWith((_) => _kSel),
      activeSessionProvider.overrideWith((_) => activeSessionId),
      translateRepositoryProvider.overrideWithValue(translate),
      cardRepositoryProvider.overrideWithValue(cards),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockCardRepository mockCards;
  late MockTranslateRepository mockTranslate;

  setUp(() {
    mockCards = MockCardRepository();
    mockTranslate = MockTranslateRepository();
    registerFallbackValue(<CardCreateBody>[]);
  });

  group('TranslationResultScreen', () {
    testWidgets('renders all 3 section card labels after translation loads',
        (tester) async {
      when(() => mockTranslate.translate('serendipity'))
          .thenAnswer((_) async => 'serendipidade');

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.text('TERMO SELECIONADO'), findsOneWidget);
      expect(find.text('TRADUÇÃO'), findsOneWidget);
      expect(find.text('CONTEXTO NO LIVRO'), findsOneWidget);
    });

    testWidgets('shows selected word in Termo Selecionado card', (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.text('serendipity'), findsWidgets);
    });

    testWidgets('shows translated text in Tradução card', (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.text('serendipidade'), findsOneWidget);
    });

    testWidgets('shows loading indicator while translating', (tester) async {
      // Never resolves so the loading state persists during the test.
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) => Completer<String>().future);

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error view with retry when translation fails',
        (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.text('Erro ao traduzir'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets(
        'CTA shows "Adicionar ao deck" when session is active', (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');

      await tester.pumpWidget(
        _buildApp(
          translate: mockTranslate,
          cards: mockCards,
          activeSessionId: 's1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adicionar ao deck'), findsOneWidget);
    });

    testWidgets('CTA shows "Escolher sessão" when no active session',
        (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escolher sessão'), findsOneWidget);
    });

    testWidgets(
        'tapping CTA calls addBatch and shows snackbar when session active',
        (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');
      when(
        () => mockCards.addBatch(
          sessionId: 's1',
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async => [_makeCard()]);

      await tester.pumpWidget(
        _buildApp(
          translate: mockTranslate,
          cards: mockCards,
          activeSessionId: 's1',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cta_button')));
      await tester.pumpAndSettle();

      verify(
        () => mockCards.addBatch(
          sessionId: 's1',
          items: any(named: 'items'),
        ),
      ).called(1);
    });

    testWidgets('retry button re-calls fetch on translation error',
        (tester) async {
      var callCount = 0;
      when(() => mockTranslate.translate(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('network error');
        return 'serendipidade';
      });

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.text('Erro ao traduzir'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('serendipidade'), findsOneWidget);
      expect(find.text('Erro ao traduzir'), findsNothing);
    });

    testWidgets('context line is rendered as RichText', (tester) async {
      when(() => mockTranslate.translate(any()))
          .thenAnswer((_) async => 'serendipidade');

      await tester.pumpWidget(
        _buildApp(translate: mockTranslate, cards: mockCards),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsWidgets);
    });
  });
}
