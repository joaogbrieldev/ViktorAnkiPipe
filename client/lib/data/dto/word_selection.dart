class WordSelection {
  const WordSelection({
    required this.word,
    this.contextLine,
    this.sessionId,
    this.capturedImagePath,
  });

  final String word;
  final String? contextLine;
  final String? sessionId;
  final String? capturedImagePath;
}
