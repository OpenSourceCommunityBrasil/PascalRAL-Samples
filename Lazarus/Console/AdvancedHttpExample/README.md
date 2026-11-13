# AdvancedHttpExample

> **Experimental.** O motor AdvancedHTTP (pacote `AdvancedHTTPRAL`, sobre a biblioteca AdvancedHTTPServer) exige o **FPC 3.3.1 ou mais novo**; com outro compilador a unit do motor compila vazia e este programa não compila. A biblioteca tem defeitos no Windows (trava requisições em keep-alive, perde o corpo das respostas em TLS, derruba o processo com corpo de requisição em chunks) e só um servidor pode estar ativo por processo.

Programa de console que serve e chama HTTP com o motor AdvancedHTTP do PascalRAL 2.0. Servidor e cliente rodam no mesmo programa, que sai ao terminar.

## O que ele faz

1. Sobe um `TRALAdvancedHTTPServer` na porta 8000 com as rotas `/hello` (uma resposta simples) e `/stream` (3 pedaços, 100 ms um do outro, com `BeginStream`/`Send`).
2. Chama as duas, uma de cada vez, com um `TRALClient` de `EngineType` `fpHTTP` (não há cliente AdvancedHTTP).
3. Mostra as respostas; os pedaços aparecem quando chegam, com a hora de cada um.

Para usar HTTPS (fora do Windows), preencha `SSL.CertFile`, `SSL.KeyFile` (PEM, chave sem senha) e `SSL.Enabled := True` no servidor antes de ativá-lo, e chame uma URL `https://`.

## Como rodar

Com o FPC 3.3.1+, a pasta `src` da [AdvancedHTTPServer](https://github.com/CynicRus/AdvancedHTTPServer) no caminho de unidades e os pacotes `PascalRAL`, `AdvancedHTTPRAL` e `fpHTTPRAL` instalados, compile o projeto e execute.
