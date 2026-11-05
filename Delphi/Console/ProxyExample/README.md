# RALProxyExample

Um proxy reverso com o RAL 2.0 (`Proxy.Exemplo.pas`), tudo num processo so':

- dois servidores RAL "de tras" nas portas 8101 (A) e 8102 (B), cada um com o
  `TRALForwardedPlugin` confiando no proxy da mesma maquina (`loopback`): a rota
  `/quem` mostra o IP real do cliente, nao o do proxy;
- o servidor da frente na porta 8100 com um `TRALProxyModule`: `/api` vai para o
  `TRALUpstream` com A e B em round robin (`/api/quem` chega neles como `/quem`);
- verificacao ativa de saude (`/health` a cada 2 segundos): derrube o B com Enter e
  veja ele sair da roda, sem erro para quem chama `/api/quem`;
- estatistica em `/proxy/stats` (JSON) e `/proxy/stats?format=prometheus`.

Pacotes: `PascalRAL`, `IndyRAL`, `RALPluginForwardedPackage` e `RALModuleProxyPackage`.

Guias: [Balanceador e proxy reverso](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/balanceador),
[Atras de um proxy](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/atras-de-proxy).
