# WebSocketExample

Programa de console que mostra os recursos WebSocket do PascalRAL 2.0: `TRALWebSocketModule` (rota `/ws/echo` com permessage-deflate), `TRALHubModule` (hub em `/chat` com grupos, método `Chat.Send` e o script de navegador `ralhub.js`), além dos clientes `TRALWebSocketClient` e `TRALHubClient`. Pacotes: `RALModuleWebSocketPackage`, `RALNetPackage` e o do motor (IndyRAL).

## Como rodar

1. Instale/compile os pacotes acima e compile `RALWebSocketExample.dpr`.
2. Sem parâmetro: sobe o servidor na porta 8090 e espera ENTER. Abra http://localhost:8090/ em duas abas do navegador: o que for digitado numa aba aparece nas duas (sala `lobby`). O console mostra as conexões e desconexões do hub.
3. Com `--demo`: depois de subir, um `TRALHubClient` entra no grupo `lobby` e chama `Chat.Send`, um `TRALWebSocketClient` envia `ping` para `/ws/echo`; os eventos e o eco são impressos e o programa termina sozinho (código 0).
