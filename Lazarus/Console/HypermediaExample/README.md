# HypermediaExample

Programa de console com hipermídia do PascalRAL 2.0 (pacote `RALModuleHypermediaPackage`), sobre o motor InProc (nenhuma porta é aberta).

## O que ele faz

A rota `/clientes/:id` responde JSON puro. O `TRALHypermediaPlugin` reescreve a mesma resposta conforme o `Accept` que o cliente manda: JSON como está, HAL (`_links`), JSON:API (`data`, `links`) e uma página HTML feita a partir dos dados, com o link `pedidos` declarado no recurso. O programa pede os quatro e mostra o tipo e o corpo de cada resposta.

## Como rodar

Instale/compile `PascalRAL`, `InProcRAL`, `RALNetPackage`, `RALStoragePackage`, `RALModuleWebPackage` e `RALModuleHypermediaPackage`, compile e execute.

Guia: [HAL, JSON:API e HTML](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/hipermidia).
