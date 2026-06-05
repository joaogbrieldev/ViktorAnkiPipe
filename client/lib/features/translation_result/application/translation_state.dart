import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/word_selection.dart';

class TranslationState {
  const TranslationState({
    required this.selection,
    this.translation = const AsyncValue.loading(),
    this.card = const AsyncValue.data(null),
  });

  final WordSelection selection;
  final AsyncValue<String> translation;
  final AsyncValue<CardDto?> card;

  TranslationState copyWith({
    AsyncValue<String>? translation,
    AsyncValue<CardDto?>? card,
  }) =>
      TranslationState(
        selection: selection,
        translation: translation ?? this.translation,
        card: card ?? this.card,
      );
}
