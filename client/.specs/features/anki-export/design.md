# Design: Anki Export

## Serviço
`lib/features/export/application/export_service.dart`:
```dart
class ExportService {
  ExportService(this._api);
  final ApiClient _api;

  Future<File> export(String sessionId, String sessionName) async {
    final bytes = await _api.getBytes('/sessions/$sessionId/export', timeout: const Duration(seconds: 60));
    final dir = await getApplicationDocumentsDirectory();
    final slug = _slugify(sessionName);
    final file = File('${dir.path}/$slug.apkg');
    await file.writeAsBytes(bytes);
    return file;
  }

  String _slugify(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

final exportServiceProvider = Provider((ref) => ExportService(ref.read(apiClientProvider)));
```

## State

Estado simples local na tela de detalhe — não precisa de provider global.
`SessionDetailScreen` mantém:
```dart
DateTime? _lastExportedAt;
bool _exporting = false;
String? _exportError;
```

E expõe `_export()`:
```dart
Future<void> _export(SessionDetailDto detail) async {
  setState(() { _exporting = true; _exportError = null; });
  try {
    final file = await ref.read(exportServiceProvider).export(detail.session.id, detail.session.name);
    setState(() { _lastExportedAt = DateTime.now(); });
    await Share.shareXFiles([XFile(file.path)], text: 'Importe no Anki');
  } catch (e) {
    setState(() => _exportError = e.toString());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao exportar')));
  } finally {
    if (mounted) setState(() => _exporting = false);
  }
}
```

## UI

### Botão / chip
- No `_Header.actions` row, slot "Exportar":
  - default: outlined button "Exportar" com ícone download.
  - `_exporting == true`: substituído por `LinearProgressIndicator`
    com label "Exportando…".
- Abaixo das ações (ou no header), chip `ExportStatusChip`:
  - oculto se nenhuma exportação ainda;
  - "● Exportado às HH:MM" verde após sucesso;
  - "● Falha — tentar novamente" vermelho tappable após erro.

### Diretório de saída
`getApplicationDocumentsDirectory()` em iOS é dentro do sandbox do app —
`share_plus` consegue compartilhar de lá. Em Android, o share sheet
também aceita arquivos do directory app-private quando passado via XFile
(o pacote cuida do `FileProvider` automaticamente).

## Erros conhecidos

- **Tempo: o servidor monta o `.apkg` em memória** (genanki). Decks grandes
  (>500 cards) podem demorar — usar `timeout: 120s` se observado em prática.
- **Arquivos antigos**: o app não limpa exports anteriores. Adicionar
  rotina no startup que apaga `.apkg` mais antigos que 7 dias
  (opcional, backlog).

## Testes

- `export_service_test.dart` — mock `ApiClient.getBytes` retornando bytes
  válidos; valida que o arquivo é escrito.
- Integração manual (Share sheet exige device).

## Verificação manual
- Sessão com 5 cards: tap "Exportar" → share aparece → escolher Anki →
  Anki abre e oferece importar → deck aparece no Anki.
- Desktop: enviar `.apkg` para Mac via AirDrop → abrir no Anki Desktop
  → cards visíveis no formato esperado.
