import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/data/api/api_paths.dart';
import 'package:client/data/dto/session_detail_dto.dart';
import 'package:client/data/dto/session_dto.dart';

class SessionRepository {
  const SessionRepository(this._client);

  final ApiClient _client;

  Future<List<SessionDto>> list() async {
    final data = await _client.getJsonList(ApiPaths.sessions);
    return data.cast<Map<String, dynamic>>().map(SessionDto.fromJson).toList();
  }

  Future<SessionDto> create(String name) async {
    final data = await _client.postJson(
      ApiPaths.sessions,
      SessionDto.toCreateBody(name),
    );
    return SessionDto.fromJson(data);
  }

  Future<SessionDetailDto> getById(String id) async {
    final data = await _client.getJson(ApiPaths.sessionById(id));
    return SessionDetailDto.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiPaths.sessionById(id));
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(apiClientProvider)),
);
