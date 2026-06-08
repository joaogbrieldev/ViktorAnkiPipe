import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/session_detail_dto.dart';
import 'package:client/data/dto/session_dto.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/session_repository.dart';
import 'package:client/features/ai_example/presentation/example_section.dart';
import 'package:client/features/session_detail/application/session_detail_controller.dart';

class MockCardRepository extends Mock implements CardRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

CardDto _card({String? example}) => CardDto(
      id: 'c1',
      sessionId: 's1',
      sourceText: 'serendipity',
      translatedText: 'serendipidade',
      createdAt: DateTime(2024),
      exampleSentence: example,
    );

SessionDetailDto _detail({CardDto? card}) => SessionDetailDto(
      session: SessionDto(
        id: 's1',
        name: 'Test',
        cardCount: 1,
        createdAt: DateTime(2024),
      ),
      cards: [card ?? _card()],
    );

Widget _buildApp({
  required Widget child,
  required MockCardRepository cardRepo,
  required MockSessionRepository sessionRepo,
}) {
  return ProviderScope(
    overrides: [
      cardRepositoryProvider.overrideWithValue(cardRepo),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockCardRepository mockCardRepo;
  late MockSessionRepository mockSessionRepo;

  setUp(() {
    mockCardRepo = MockCardRepository();
    mockSessionRepo = MockSessionRepository();
  });

  group('ExampleSection', () {
    testWidgets('shows generate button when card has no example', (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => _detail());

      await tester.pumpWidget(
        _buildApp(
          child: ExampleSection(card: _card(), sessionId: 's1'),
          cardRepo: mockCardRepo,
          sessionRepo: mockSessionRepo,
        ),
      );

      expect(find.text('Gerar frase de exemplo'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    });

    testWidgets('shows existing example when card has one', (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => _detail(card: _card(example: 'A pleasant surprise.')));

      await tester.pumpWidget(
        _buildApp(
          child: ExampleSection(
            card: _card(example: 'A pleasant surprise.'),
            sessionId: 's1',
          ),
          cardRepo: mockCardRepo,
          sessionRepo: mockSessionRepo,
        ),
      );

      // Regerar button only appears when example exists
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('A pleasant surprise.'), findsOneWidget);
    });

    testWidgets('tapping generate calls generateExample and updates UI',
        (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => _detail());
      when(() => mockCardRepo.generateExample(cardId: 'c1'))
          .thenAnswer((_) async => 'A happy coincidence.');

      await tester.pumpWidget(
        _buildApp(
          child: ExampleSection(card: _card(), sessionId: 's1'),
          cardRepo: mockCardRepo,
          sessionRepo: mockSessionRepo,
        ),
      );

      await tester.tap(find.text('Gerar frase de exemplo'));
      await tester.pumpAndSettle();

      // After generation, Regerar button appears and example is displayed
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('A happy coincidence.'), findsOneWidget);
      verify(() => mockCardRepo.generateExample(cardId: 'c1')).called(1);
    });

    testWidgets('calls setExampleFor on sessionDetailController after generate',
        (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => _detail());
      when(() => mockCardRepo.generateExample(cardId: 'c1'))
          .thenAnswer((_) async => 'A happy coincidence.');

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cardRepositoryProvider.overrideWithValue(mockCardRepo),
            sessionRepositoryProvider.overrideWithValue(mockSessionRepo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                home: Scaffold(
                  body: ExampleSection(card: _card(), sessionId: 's1'),
                ),
              );
            },
          ),
        ),
      );

      await container
          .read(sessionDetailControllerProvider('s1').future)
          .catchError((_) => _detail());

      await tester.tap(find.text('Gerar frase de exemplo'));
      await tester.pumpAndSettle();

      final state =
          container.read(sessionDetailControllerProvider('s1')).valueOrNull;
      expect(state?.cards.first.exampleSentence, 'A happy coincidence.');
    });

    testWidgets('shows snackbar on error', (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => _detail());
      when(() => mockCardRepo.generateExample(cardId: 'c1'))
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(
        _buildApp(
          child: ExampleSection(card: _card(), sessionId: 's1'),
          cardRepo: mockCardRepo,
          sessionRepo: mockSessionRepo,
        ),
      );

      await tester.tap(find.text('Gerar frase de exemplo'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível gerar exemplo'), findsOneWidget);
    });

    testWidgets('tapping regerar regenerates example', (tester) async {
      when(() => mockSessionRepo.getById('s1'))
          .thenAnswer((_) async => _detail(card: _card(example: 'Old example.')));
      when(() => mockCardRepo.generateExample(cardId: 'c1'))
          .thenAnswer((_) async => 'New example sentence.');

      await tester.pumpWidget(
        _buildApp(
          child: ExampleSection(
            card: _card(example: 'Old example.'),
            sessionId: 's1',
          ),
          cardRepo: mockCardRepo,
          sessionRepo: mockSessionRepo,
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('New example sentence.'), findsOneWidget);
    });
  });
}
