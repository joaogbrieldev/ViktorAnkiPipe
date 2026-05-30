# Feature: Câmera + OCR

## Objetivo
Capturar imagem da câmera, rodar OCR on-device (Google ML Kit) e expor cada
palavra detectada como token selecionável. Tocar em uma palavra abre o
sheet de tradução (próxima feature [translation-result](../translation-result/spec.md)).

## Escopo
- Tela `CameraScreen` em `/scan` (tab bottom nav).
- Preview ao vivo da câmera traseira, edge-to-edge.
- Overlay com framing brackets (4 cantos arredondados em primary).
- Hint pill no topo "Aponte para o texto para traduzir" sobre backdrop blur.
- Botão fechar (X) à esquerda → volta para `/sessions`.
- Botão flashlight à direita (toggle).
- Bottom controls: thumbnail (placeholder), shutter circle, flip camera.
- Ao tocar shutter: tira foto, congela frame, dispara `TextRecognizer` do
  ML Kit, e mostra retângulos tappable sobre cada palavra detectada.
- Botões inferiores no estado "frame congelado": "Refazer" (X) e "Concluir".
- Permissão de câmera é solicitada em foreground (com fallback se negada).

## Fora do escopo
- OCR contínuo em tempo real (apenas após shutter). Backlog futuro.
- Captura de PDF/galeria.
- Crop manual da região da foto.
- Persistência da foto.

## Critérios de aceitação
1. Ao abrir `/scan` pela primeira vez, o app pede permissão de câmera.
   Negada → tela com botão "Abrir Settings".
2. Concedida, mostra preview ao vivo full-screen com overlay.
3. Flash toggle alterna entre ligado/desligado quando suportado.
4. Tap em flip alterna entre câmera traseira/frontal (se disponível).
5. Tap no shutter:
   - tira foto;
   - mostra spinner discreto sobre o frame congelado ("Detectando…");
   - em <2s em um device razoável, exibe palavras como retângulos azuis
     com 10% de opacity (alinhados aos bounding boxes do ML Kit).
6. Cada token (palavra) é tappable; ao tocar, abre o sheet de tradução.
   (Sheet em si é a outra feature; aqui só dispara `onWordSelected(text, contextLine)`).
7. "Refazer" descarta o frame congelado e volta ao preview ao vivo.
8. Sair da tab (ir para Sessions/Cards) **pausa** a câmera; voltar retoma.
9. Sem crash em devices que não têm flash.

## Dependências
- Foundation.
- Permissões: `camera` (iOS NSCameraUsageDescription, Android `CAMERA` permission).
- Translation-result vai consumir o callback de seleção de palavra.

## Design de referência
[`client/design/02-camera.png`](../../../client/design/02-camera.png).
HTML em [`client/design/02-camera.html`](../../../client/design/02-camera.html).

Elementos visuais a preservar:
- Pill central no topo "Aponte para o texto para traduzir" em
  `bg-black/40 backdrop-blur-lg`, texto branco subhead.
- Brackets: 32×32, 2px border, primary-container, radius 8.
- Tokens detectados (após captura): `bg-primary/20 border-primary/30`
  rounded 2px, blur, com label opcional.
- Shutter externo 80×80 ring branca semi-transparente; círculo interno branco.
- Thumbnail à esquerda (placeholder com `surface-container-highest`).
- Bottom nav tab "Scan" ativa (primary-fixed-dim).
