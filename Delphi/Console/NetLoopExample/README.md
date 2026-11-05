# RALNetLoopExample

A rede propria do RAL 2.0 (`RALNetPackage`), sem motor HTTP (`Eco.Servidor.pas`):

- `TRALSocketLoop` aceita na porta 7000 e divide as conexoes entre duas threads de
  `poll`; a cada 5 segundos o relogio mostra quantas estao abertas;
- `TEcoConexao` (descende de `TRALSocketLoopConnection`) e' o protocolo: devolve cada
  linha em maiusculas, e `sair` responde `tchau` e fecha depois que a resposta sai
  (`CloseAfterFlush`); quando o servidor para, cada conexao ouve `servidor parando`
  (`Stopping`);
- o programa ainda conecta um cliente com `TRALSocket`/`TRALSocketChannel` e mostra a
  resposta.

Teste com `telnet localhost 7000` (ou `nc localhost 7000`).

E' o mesmo molde do broker MQTT do RAL. Pacotes: `PascalRAL` e `RALNetPackage`.

Guia: [internos-utils](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/internos-utils).
