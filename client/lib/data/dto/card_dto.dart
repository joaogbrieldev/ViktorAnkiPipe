class CardDto {
  const CardDto({
    required this.id,
    required this.sessionId,
    required this.sourceText,
    required this.translatedText,
    required this.createdAt,
    this.context,
    this.exampleSentence,
  });

  final String id;
  final String sessionId;
  final String sourceText;
  final String translatedText;
  final String? context;
  final DateTime createdAt;
  final String? exampleSentence;

  factory CardDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawSessionId = json['session_id'];
    final sourceText = json['source_text'];
    final translatedText = json['translated_text'];
    final createdAt = json['created_at'];

    if (rawId == null ||
        rawSessionId == null ||
        sourceText is! String ||
        translatedText is! String ||
        createdAt is! String) {
      throw const FormatException('Invalid card JSON: missing required fields');
    }

    String parseIntOrString(dynamic v) => switch (v) {
          int value => value.toString(),
          String value => value,
          _ => throw const FormatException('Invalid id type in card JSON'),
        };

    return CardDto(
      id: parseIntOrString(rawId),
      sessionId: parseIntOrString(rawSessionId),
      sourceText: sourceText,
      translatedText: translatedText,
      context: json['context'] as String?,
      createdAt: DateTime.parse(createdAt),
    );
  }

  CardDto copyWith({String? exampleSentence}) => CardDto(
        id: id,
        sessionId: sessionId,
        sourceText: sourceText,
        translatedText: translatedText,
        context: context,
        createdAt: createdAt,
        exampleSentence: exampleSentence ?? this.exampleSentence,
      );
}
