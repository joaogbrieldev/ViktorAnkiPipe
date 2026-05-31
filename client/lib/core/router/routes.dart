abstract final class Routes {
  static const sessions = '/sessions';
  static const sessionDetail = '/sessions/:id';
  static const scan = '/scan';
  static const cards = '/cards';
  static const result = '/result';

  static String sessionDetailPath(String id) => '/sessions/$id';
}
