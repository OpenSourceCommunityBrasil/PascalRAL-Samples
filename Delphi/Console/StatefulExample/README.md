# StatefulExample

Programa de console com recursos com estado do PascalRAL 2.0 (pacote `RALModuleStatefulPackage`), sobre o motor InProc (nenhuma porta é aberta).

## O que ele faz

`TCart` é uma classe com as rotas `cart/add` e `cart` escritas como métodos e a lista de itens num campo comum. O `TRALStatefulModule` (`Lifetime = mlPerSession`) dá a cada sessão de usuário o seu próprio `TCart`: os usuários `ana` e `bia` enchem os carrinhos e cada uma vê só o seu. O programa guarda e devolve o cookie de sessão, como um navegador faria.

## Como rodar

Instale/compile `PascalRAL`, `InProcRAL` e `RALModuleStatefulPackage`, compile e execute.

Guia: [Recursos com estado](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/recursos-com-estado).
