import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/dto/session_dto.dart';
import 'package:client/data/repositories/session_repository.dart';

class SessionsController extends AsyncNotifier<List<SessionDto>> {
  @override
  Future<List<SessionDto>> build() =>
      ref.read(sessionRepositoryProvider).list();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> create(String name) async {
    final previous = state.valueOrNull ?? [];
    final session = await ref.read(sessionRepositoryProvider).create(name);
    state = AsyncData([session, ...previous]);
  }

  Future<void> delete(String id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData(previous.where((s) => s.id != id).toList());
    try {
      await ref.read(sessionRepositoryProvider).delete(id);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }
}

final sessionsControllerProvider =
    AsyncNotifierProvider<SessionsController, List<SessionDto>>(
  SessionsController.new,
);
