import 'package:client/data/dto/card_dto.dart';
import 'package:client/data/dto/session_dto.dart';

class SessionDetailDto {
  const SessionDetailDto({
    required this.session,
    required this.cards,
  });

  final SessionDto session;
  final List<CardDto> cards;

  factory SessionDetailDto.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    final cards = rawCards is List
        ? rawCards.cast<Map<String, dynamic>>().map(CardDto.fromJson).toList()
        : <CardDto>[];

    return SessionDetailDto(
      session: SessionDto.fromJson(json),
      cards: cards,
    );
  }

  SessionDetailDto copyWith({List<CardDto>? cards}) => SessionDetailDto(
        session: session,
        cards: cards ?? this.cards,
      );
}
