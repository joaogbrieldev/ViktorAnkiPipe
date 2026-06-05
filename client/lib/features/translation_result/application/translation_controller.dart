import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/core/providers/pending_translation_provider.dart';
import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/word_selection.dart';
import 'package:client/data/repositories/card_repository.dart';
import 'package:client/data/repositories/translate_repository.dart';
import 'package:client/features/translation_result/application/translation_state.dart';

class TranslationController extends StateNotifier<TranslationState> {
  TranslationController(
    this._cards,
    this._translate,
    WordSelection selection,
  ) : super(TranslationState(selection: selection));

  final CardRepository _cards;
  final TranslateRepository _translate;

  Future<void> fetch() async {
    state = state.copyWith(translation: const AsyncValue.loading());
    try {
      final text = await _translate.translate(state.selection.word);
      state = state.copyWith(translation: AsyncValue.data(text));
    } catch (e, st) {
      state = state.copyWith(translation: AsyncValue.error(e, st));
    }
  }

  Future<void> addToSession(String sessionId) async {
    state = state.copyWith(card: const AsyncValue.loading());
    try {
      final created = await _cards.addBatch(
        sessionId: sessionId,
        items: [
          CardCreateBody(
            sourceText: state.selection.word,
            context: state.selection.contextLine,
          ),
        ],
      );
      state = state.copyWith(card: AsyncValue.data(created.first));
    } catch (e, st) {
      state = state.copyWith(card: AsyncValue.error(e, st));
    }
  }
}

final translationControllerProvider = StateNotifierProvider.autoDispose<
    TranslationController, TranslationState>(
  (ref) {
    final selection = ref.read(pendingTranslationProvider);
    return TranslationController(
      ref.watch(cardRepositoryProvider),
      ref.watch(translateRepositoryProvider),
      selection ?? const WordSelection(word: ''),
    );
  },
);
