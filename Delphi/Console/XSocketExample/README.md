# XSocketExample

Programa de console que serve e chama HTTP com o motor XSocket do PascalRAL 2.0 (pacote `XSocketRAL`, sobre a biblioteca Delphi-Cross-Socket). Servidor e cliente rodam no mesmo programa, que sai ao terminar. Só Delphi 11 ou mais novo.

## O que ele faz

1. Sobe um `TRALXSocketServer` na porta 8000 com as rotas `/hello` (uma resposta simples) e `/stream` (3 pedaços, 100 ms um do outro, com `BeginStream`/`Send`).
2. Chama `/hello` com um `TRALClient` de `EngineType` `XSocket`.
3. Chama `/stream` com o cliente `Indy`: o cliente XSocket entrega o corpo inteiro no fim e não faz fluxo, então os pedaços só aparecem um a um (com a hora de chegada) pelo Indy.

Para usar HTTPS, preencha `SSL.CertFile`, `SSL.KeyFile` (PEM, chave sem senha) e `SSL.Enabled := True` no servidor antes de ativá-lo (veja o comentário no fonte) e chame uma URL `https://`; o OpenSSL 3 precisa ser encontrado ao rodar. O cliente XSocket não confere o certificado do servidor.

## Como rodar

A biblioteca [Delphi-Cross-Socket](https://github.com/winddriver/Delphi-Cross-Socket) precisa estar no caminho de bibliotecas do Delphi (as pastas `Net`, `Utils` e `DelphiToFPC`). Instale/compile `PascalRAL` e `XSocketRAL`, compile o projeto e execute.
