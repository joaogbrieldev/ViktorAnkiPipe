import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/dto/session_detail_dto.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/session_repository.dart';

class SessionDetailController
    extends FamilyAsyncNotifier<SessionDetailDto, String> {
  @override
  Future<SessionDetailDto> build(String arg) =>
      ref.read(sessionRepositoryProvider).getById(arg);

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteCard(String cardId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        cards: current.cards.where((c) => c.id != cardId).toList(),
      ),
    );
    try {
      await ref.read(cardRepositoryProvider).delete(
            sessionId: arg,
            cardId: cardId,
          );
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> setExampleFor(String cardId, String example) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        cards: current.cards
            .map((c) => c.id == cardId ? c.copyWith(exampleSentence: example) : c)
            .toList(),
      ),
    );
  }
}

final sessionDetailControllerProvider = AsyncNotifierProvider.family<
    SessionDetailController, SessionDetailDto, String>(
  SessionDetailController.new,
);
