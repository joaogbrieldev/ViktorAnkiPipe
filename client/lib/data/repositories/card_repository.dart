import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/data/api/api_paths.dart';
import 'package:client/data/dto/card_dto.dart';

class CardRepository {
  const CardRepository(this._client);

  final ApiClient _client;

  Future<List<CardDto>> addBatch({
    required String sessionId,
    required List<CardCreateBody> items,
  }) async {
    final res = await _client.postJson(
      ApiPaths.sessionCards(sessionId),
      {'items': items.map((i) => i.toJson()).toList()},
    );
    return (res['items'] as List)
        .map((j) => CardDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete({
    required String sessionId,
    required String cardId,
  }) async {
    await _client.delete(ApiPaths.sessionCard(sessionId, cardId));
  }

  Future<String> generateExample({required String cardId}) async {
    final res = await _client.postJson(ApiPaths.cardExample(cardId), const {});
    return res['example_sentence'] as String;
  }
}

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(apiClientProvider)),
);
