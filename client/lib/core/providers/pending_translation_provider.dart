import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client/data/dto/word_selection.dart';

final pendingTranslationProvider = StateProvider<WordSelection?>((ref) => null);
