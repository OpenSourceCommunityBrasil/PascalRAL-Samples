# RALObjectsExample

Objetos no corpo num servidor RAL 2.0 (`Objetos.Exemplo.pas`):

- `POST /pedidos`: a rota tem `BodyClass = 'TPedido'` e `OnReplyObject`; o RAL le o
  JSON (ou um formulario) num `TPedido`, confere as `ValidationRules` (cliente
  obrigatorio com ate 40 letras, e-mail valido, ao menos um item) e so entao chama o
  handler. Regra quebrada: 422 em `problem+json` com os erros por campo; JSON
  quebrado: 400;
- a resposta sai no formato do `Accept`: JSON (padrao), YAML ou CSV;
- `RALObjectSettings.JSON.Naming := onCamel`: as propriedades viram `cliente`,
  `email`, `itens`;
- `/swagger`: o esquema de `TPedido` com as regras.

Pacotes: `PascalRAL`, `IndyRAL`, `RALModuleObjectsPackage` e
`RALModuleSwaggerPackage`.

Guias: [Objetos no corpo](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/objetos),
[Validacao](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/validacao).
