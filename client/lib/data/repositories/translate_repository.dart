import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/data/api/api_paths.dart';

class TranslateRepository {
  const TranslateRepository(this._client);

  final ApiClient _client;

  Future<String> translate(String text) async {
    final res = await _client.postJson(ApiPaths.translate, {'q': text});
    return res['translated_text'] as String;
  }
}

final translateRepositoryProvider = Provider<TranslateRepository>(
  (ref) => TranslateRepository(ref.watch(apiClientProvider)),
);
