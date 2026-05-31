import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/data/api/api_paths.dart';

class CardRepository {
  const CardRepository(this._client);

  final ApiClient _client;

  Future<void> delete({
    required String sessionId,
    required String cardId,
  }) async {
    await _client.delete(ApiPaths.sessionCard(sessionId, cardId));
  }
}

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(apiClientProvider)),
);
