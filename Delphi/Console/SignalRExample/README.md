# RALSignalRExample

Um hub **SignalR** no RAL 2.0 (`TRALSignalRModule`, pacote `RALModuleSignalRPackage`):
os clientes oficiais da Microsoft conectam em `http://localhost:8095/chat`.

- `http://localhost:8095/`: uma pagina de chat com o cliente oficial do navegador
  (`signalr.min.js`, da CDN do jsDelivr).
- Metodos do hub: `SendMessage(user, text)` (todos recebem `ReceiveMessage`),
  `Echo(text)` (devolve o texto) e o stream `Counter(n)`.

Cliente Node (`npm install @microsoft/signalr`):

```js
const signalR = require("@microsoft/signalr");
const c = new signalR.HubConnectionBuilder().withUrl("http://localhost:8095/chat").build();
c.on("ReceiveMessage", (u, m) => console.log(u + ": " + m));
await c.start();
console.log(await c.invoke("Echo", "oi"));
c.stream("Counter", 3).subscribe({ next: x => console.log(x), complete: () => c.stop(), error: e => console.error(e) });
```

Pacotes: `PascalRAL`, `RALNetPackage`, `RALModuleWebSocketPackage`,
`RALModuleSignalRPackage` e o motor (Indy no Delphi, fpHTTP no Lazarus).

Guia: [SignalR](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/signalr).
