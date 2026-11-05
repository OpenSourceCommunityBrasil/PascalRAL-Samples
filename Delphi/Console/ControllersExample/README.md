# RALControllersExample (Delphi 2010 e posteriores)

Um CRUD de produtos escrito como controller (`Produtos.Controller.pas`): a classe
`TProdutoController` tem `[Path('/produtos')]` e metodos com `[GET]`, `[GET('/{id}')]`,
`[POST]` e `[DELETE('/{id}')]`; o `TRALControllerModule` cria as rotas, preenche os
parametros (caminho, query, corpo) e escreve o que o metodo devolve. `TProduto` e'
validado pelos atributos `[Required]`, `[MaxLength]` e `[Range]` (422 quando falha); a
excecao `ENaoEncontrado` vira 404 pelo `ExceptionMap`.

No Lazarus/FPC 3.2 nao ha atributos: veja o `ObjectsExample`, que faz o mesmo com rotas.

Pacotes: `PascalRAL`, `IndyRAL`, `RALModuleObjectsPackage` e
`RALModuleControllersPackage`.

Guia: [Controllers por atributos](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/controllers).
