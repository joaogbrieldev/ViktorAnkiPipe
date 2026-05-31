class SessionDto {
  const SessionDto({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.createdAt,
    this.source,
  });

  final String id;
  final String name;
  final String? source;
  final int cardCount;
  final DateTime createdAt;

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final name = json['name'];
    final createdAt = json['created_at'];

    if (rawId == null || name is! String || createdAt is! String) {
      throw const FormatException('Invalid session JSON: missing required fields');
    }

    final id = switch (rawId) {
      int value => value.toString(),
      String value => value,
      _ => throw const FormatException('Invalid session JSON: missing required fields'),
    };

    return SessionDto(
      id: id,
      name: name,
      source: json['source'] as String?,
      cardCount: (json['card_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static Map<String, dynamic> toCreateBody(String name) => {'name': name};
}
