# Tasks: Anki Export

## Backend (pré-requisito)

- [ ] **E-00** Confirmar com o server que `GET /sessions/{id}/export` está
       funcional. Ver `server/CLAUDE.md` "Próximos passos pendentes" — itens
       4, 5, 7. Pode bloquear esta feature.

## App

- [ ] **E-01** Criar `lib/features/export/application/export_service.dart`
       com `ExportService.export(sessionId, sessionName)`.
- [ ] **E-02** Provider Riverpod `exportServiceProvider`.
- [ ] **E-03** Em `SessionDetailScreen`: estado `_exporting`, `_lastExportedAt`,
       `_exportError`.
- [ ] **E-04** Adicionar `share_plus` ao pubspec (já planejado em Foundation
       — confirmar).
- [ ] **E-05** Implementar `_export()` que chama o serviço e abre Share.
- [ ] **E-06** Criar `ExportStatusChip` widget que reflete o estado.
- [ ] **E-07** Trocar botão "Exportar" por `LinearProgressIndicator` durante
       o download.

## Testes

- [ ] **E-08** `test/features/export/export_service_test.dart` — bytes
       retornados são gravados em arquivo.
- [ ] **E-09** Verificar build Android: `flutter build apk --debug` passa
       (FileProvider precisa estar configurado se ainda não estiver — o
       `share_plus` já gera os XML necessários).

## Verificação manual

- [ ] **E-10** iOS device: exportar deck de 5 cards → share sheet → Anki
       importa.
- [ ] **E-11** Android device: idem.
- [ ] **E-12** Desktop: receber `.apkg` no Mac e importar no Anki Desktop.
- [ ] **E-13** Re-exportar gera mesmo deck (não duplica) — depende do
       `model_id` constante no servidor.

## Dependências
- Server tarefas pendentes #4, #5, #7 do `server/CLAUDE.md`.
- Foundation, Session-detail.
