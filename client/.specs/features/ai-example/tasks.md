# Tasks: AI Example

- [x] **AI-01** Confirmar que `CardRepository.generateExample` está
       implementado (Translation-result tarefa R-02).
- [x] **AI-02** Adicionar `CardDto.copyWith` (se ainda não existir).
- [x] **AI-03** Criar `ExampleSection` widget em
       `lib/features/ai_example/presentation/example_section.dart`.
- [x] **AI-04** Integrar `ExampleSection` ao `CardDetailSheet` (substituindo
       o placeholder "Frase exemplo").
- [x] **AI-05** Teste unit: chamada do `generateExample` integra com
       `SessionDetailController.setExampleFor`.

## Verificação manual

- [ ] **AI-06** Card sem exemplo: tap "Gerar" → frase aparece.
- [ ] **AI-07** Tap "Regerar": frase é substituída.
- [ ] **AI-08** Backend offline: snackbar de erro, sem crash.

## Dependências
- Translation-result (CardRepository).
- Session-detail (hospeda o widget).
