# RALInProcTestExample

Teste de integracao **sem porta**: o servidor da aplicacao roda em memoria
(`TRALInProcServer`) e um `TRALClient` com `EngineType := 'InProc'` e
`BaseURL := 'inproc://loja'` fala com ele. A autenticacao Basic, os plugins e os
modulos rodam como na rede; so os bytes nao saem do processo. O mesmo codigo cabe
num teste do DUnitX, DUnit ou fpcunit.

Pacotes: `PascalRAL`, `InProcRAL` e `RALPluginAuthPackage`.

Guia: [Testes em memoria](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/testes-em-memoria).
