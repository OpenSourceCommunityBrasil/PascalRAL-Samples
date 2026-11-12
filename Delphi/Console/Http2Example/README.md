# Http2Example

Programa de console que serve e chama HTTP/2 com o PascalRAL 2.0 (pacote `NgHttp2RAL`). Servidor e cliente rodam no mesmo programa, que sai ao terminar.

## O que ele faz

1. Sobe um `TRALNgHttp2Server` na porta 8000 com as rotas `/hello` (uma resposta simples) e `/stream` (3 pedaços, 100 ms um do outro, com `BeginStream`/`Send`).
2. Chama as duas com um `TRALClient` de `EngineType` `NgHttp2`, em HTTP/2 sem TLS (h2c, `http://127.0.0.1:8000`).
3. Mostra as respostas e o `ProtocolVersion` de cada uma (`rhv2` é HTTP/2); os pedaços aparecem quando chegam.

Para usar TLS (h2), preencha `SSL.CertFile`, `SSL.KeyFile` e `SSL.Enabled := True` no servidor antes de ativá-lo (veja o comentário no fonte) e chame uma URL `https://`.

## Como rodar

A biblioteca nghttp2 precisa ser encontrada ao rodar (`libnghttp2.so.14` no Linux, `libnghttp2-14.dll` no Windows). Instale/compile `PascalRAL` e `NgHttp2RAL`, compile o projeto e execute.
