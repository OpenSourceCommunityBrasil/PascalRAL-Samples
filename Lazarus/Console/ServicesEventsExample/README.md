# ServicesEventsExample

Programa de console com o contêiner de serviços e o barramento de eventos do PascalRAL 2.0 (pacotes `RALHostingContainerPackage` e `RALModuleEventBusPackage`), sobre o motor InProc (nenhuma porta é aberta).

## O que ele faz

1. **`TRALServiceContainer`:** um serviço de numeração (`slSingleton`, um só para o programa) e um balcão de pedidos (`slPerRequest`, criado em cada pedido HTTP e liberado quando ele termina; o console mostra os dois momentos). O balcão pede ao contêiner a numeração de que depende.
2. **A rota `/pedido`** pede o balcão ao contêiner, registra o pedido e publica o evento `pedido/criado` num `TRALEventBus`.
3. **A "nota fiscal"** assinou `pedido/#` e reage na thread do barramento (`edAsync`), sem a rota saber que ela existe.

## Como rodar

Instale/compile `PascalRAL`, `InProcRAL`, `RALHostingContainerPackage` e `RALModuleEventBusPackage`, compile e execute.

Guias: [Serviços](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/servicos) e [Barramento de eventos](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/eventos).
