# RALModuleExample

Exemplo de um módulo próprio no RAL 2.0 (`Saudacao.Module.pas`): uma classe de
rota com um dado por rota, uma resposta com um `Answer` que só o módulo tem,
`BeforeExecute` (acrescenta `X-Modulo`), `HandleException` (responde 422 em JSON),
`DefaultContentType` e o ciclo de vida do servidor (`ServerActivating` e
`ServerDeactivating`). A rota `ping` usa o handler de sempre do núcleo.

Rode e abra:

- `http://localhost:8000/saudacao/ola/ana` -> `ola ana ola ana`
- `http://localhost:8000/saudacao/ping` -> `pong`
- `http://localhost:8000/saudacao/falha` -> 422 `{"erro":"falha de proposito"}`

Guia: [Criando um módulo](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/criar-modulo).
