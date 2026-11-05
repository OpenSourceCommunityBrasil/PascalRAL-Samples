# RALRoutingExample

Rotas do RAL 2.0 (`Rotas.Exemplo.pas`):

- `/produtos/:id<int:range(1,9999)>`: o RAL confere o tipo e o intervalo
  (`/produtos/abc` e `/produtos/0` respondem 404 sem chegar no seu codigo);
- `/pedidos/:status?`: parte opcional (`/pedidos` e `/pedidos/abertos`);
- `/arquivos/*caminho`: o curinga pega o resto do caminho;
- grupo `admin` com prefixo `/admin` e um `OnBeforeExecute` que exige o cabecalho
  `X-Chave: segredo` (sem ele, 403);
- versoes: `/v1/clientes` e `/v2/clientes` em rotas diferentes; a v1 e obsoleta
  (cabecalho `Deprecation: true`);
- `QUERY /busca` com corpo;
- `/ping` com procedimento anonimo, onde o compilador tem (Delphi; no Lazarus com FPC 3.2 a rota nao existe).

Teste o QUERY com: `curl -X QUERY -d 'cidade=Recife' http://localhost:8000/busca`.

Guia: [Rotas avancadas](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/rotas-avancadas).
