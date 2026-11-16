# LiveBindingsExample (VCL)

Grade e campo de edicao ligados, pelo **LiveBindings** do Delphi, ao JSON que um
`TRALClient` recebe: `TRALJSONBindSourceAdapter` (pacote `RALClientLiveBindingsPackage`)
-> `TAdapterBindSource` -> `TLinkGridToDataSource` e `TLinkControlToField`, tudo no
formulario (designer de LiveBindings). Um `TRALInProcServer` no proprio formulario faz o
papel da API, entao o exemplo roda sozinho.

- **Carregar** chama `RALJSONBindSourceAdapter1.Execute` (GET `pessoas`).
- Edite na grade ou no campo; **Ver JSON** mostra o JSON com as edicoes (`ToJSON`).
- `FieldDefs` define os campos no design (aparecem no designer antes de haver dados).

Delphi XE3 em diante (testado no XE5, 10.2 e 13). Pacotes: `PascalRAL`,
`RALClientLiveBindingsPackage` e `InProcRAL`.

Guia: [LiveBindings](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/livebindings).
