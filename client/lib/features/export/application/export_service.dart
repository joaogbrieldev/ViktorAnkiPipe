import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:client/data/api/api_client.dart';
import 'package:client/data/api/api_paths.dart';

class CancelledExportException implements Exception {
  const CancelledExportException();
}

class ExportCancellation {
  bool cancelled = false;
}

class ExportService {
  ExportService(
    this._client, {
    Future<Directory> Function()? getDocumentsDir,
    Future<void> Function(List<XFile>, {String? subject})? shareFiles,
  })  : _getDocumentsDir = getDocumentsDir ?? getApplicationDocumentsDirectory,
        _shareFiles = shareFiles ?? _defaultShare;

  final ApiClient _client;
  final Future<Directory> Function() _getDocumentsDir;
  final Future<void> Function(List<XFile>, {String? subject}) _shareFiles;

  static Future<void> _defaultShare(
    List<XFile> files, {
    String? subject,
  }) =>
      Share.shareXFiles(files, subject: subject);

  Future<DateTime> export({
    required String sessionId,
    required String sessionName,
    ExportCancellation? cancellation,
  }) async {
    final bytes = await _client.getBytes(ApiPaths.sessionExport(sessionId));

    if (cancellation?.cancelled == true) throw const CancelledExportException();

    final dir = await _getDocumentsDir();
    final file = File('${dir.path}/${_toSlug(sessionName)}.apkg');
    await file.writeAsBytes(bytes, flush: true);

    if (cancellation?.cancelled == true) {
      await file.delete();
      throw const CancelledExportException();
    }

    await _shareFiles(
      [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: 'Importe no Anki',
    );

    return DateTime.now();
  }

  static String _toSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.watch(apiClientProvider)),
);
