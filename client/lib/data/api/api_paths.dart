abstract final class ApiPaths {
  static const sessions = '/sessions';
  static const translate = '/translate';

  static String sessionById(String id) => '/sessions/$id';
  static String sessionExport(String id) => '/sessions/$id/export';
  static String sessionCards(String id) => '/sessions/$id/cards';
  static String sessionCard(String id, String cardId) =>
      '/sessions/$id/cards/$cardId';
  static String cardExample(String cardId) => '/cards/$cardId/example';
  static const health = '/health';
}
