# DataAPIExample

Programa de console que mostra a *data API* do PascalRAL 2.0 (`TRALDBCrudModule`, pacote `RALDBPackage` mais o link do seu componente de acesso): REST pronto sobre tabelas, sem escrever rota nem `SELECT`. Veja a página [Recursos REST sobre tabelas](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/dbware-recursos) da wiki.

O programa cria, ao lado do executável, o banco SQLite `produtos.db` (se ele ainda não existir) com a tabela `produtos` (`id`, `nome`, `preco`, `estoque`, `versao`) e sobe o servidor na porta 8000 com dois recursos:

| rota | o que é |
|---|---|
| `/produtos` | todos os verbos; `versao` é o `VersionField` (vira o ETag) |
| `/baratos` | só leitura; `BaseFilter` `preco < 10` e só as colunas `id`, `nome` e `preco` |

## Como rodar

1. Instale/compile os pacotes `PascalRAL`, `raldbpackage`, `raldbsqldbpackage` e `fpHTTPRAL`.
2. Compile e execute `ralDataAPIExample.lpr`. No Linux o programa usa `/usr/lib/x86_64-linux-gnu/libsqlite3.so.0` (ajuste o `LibLocation` no fonte se a sua for outra); no Windows, coloque `sqlite3.dll` ao lado do executável.
3. Teste de outro terminal com os `curl` abaixo. ENTER encerra o servidor.

## Exemplos

Listar, ler um registro, inserir, trocar, alterar e apagar:

```
curl http://127.0.0.1:8000/produtos
curl -i http://127.0.0.1:8000/produtos/1
curl -i -X POST http://127.0.0.1:8000/produtos -H "Content-Type: application/json" -d '{"nome":"Regua","preco":3.5,"estoque":30}'
curl -X PUT http://127.0.0.1:8000/produtos/7 -H "Content-Type: application/json" -d '{"nome":"Regua 30cm"}'
curl -X PATCH http://127.0.0.1:8000/produtos/7 -H "Content-Type: application/json" -d '{"preco":4.2}'
curl -i -X DELETE http://127.0.0.1:8000/produtos/7
```

O `POST` responde 201, com `Location: /produtos/7` e o registro. O `PUT` troca o registro todo (o que o corpo não traz vira nulo); o `PATCH` altera só o que o corpo traz. O `DELETE` responde 204, e 404 se o registro não existe.

Filtros da sintaxe simples:

```
curl "http://127.0.0.1:8000/produtos?preco_gt=10&_sort=-preco"
curl "http://127.0.0.1:8000/produtos?nome_cont=a&_fields=id,nome&_limit=3"
curl "http://127.0.0.1:8000/produtos?id_in=1,2,3"
curl "http://127.0.0.1:8000/produtos?_page=2&_per_page=2"
curl -i "http://127.0.0.1:8000/produtos?estoque_lt=100"
```

A última mostra o cabeçalho `X-Total-Count` (`TotalCount` está ligado). Todos os sufixos: `_gt`, `_gte`, `_lt`, `_lte`, `_ne`, `_like`, `_cont`, `_sw`, `_ew`, `_in`, `_nin`, `_null`.

RQL (o filtro todo no parâmetro `rql`):

```
curl "http://127.0.0.1:8000/produtos?rql=and(gt(preco,10),lt(estoque,100))"
curl "http://127.0.0.1:8000/produtos?rql=or(eq(nome,Caneta),starts(nome,Ca))&filter-syntax=rql"
curl "http://127.0.0.1:8000/produtos?rql=sort(-preco),limit(3)"
```

ETag e `If-Match` (concorrência otimista; `versao` cresce a cada escrita):

```
curl -i http://127.0.0.1:8000/produtos/1                    # ETag: "1"
curl -i -X PATCH http://127.0.0.1:8000/produtos/1 -H "If-Match: \"1\"" -H "Content-Type: application/json" -d '{"preco":2.75}'   # 200, ETag: "2"
curl -i -X PATCH http://127.0.0.1:8000/produtos/1 -H "If-Match: \"1\"" -H "Content-Type: application/json" -d '{"preco":2.99}'   # 412: a versao agora e 2
```

O recurso só de leitura e os erros:

```
curl http://127.0.0.1:8000/baratos
curl -i -X DELETE http://127.0.0.1:8000/baratos/1           # 405
curl -i "http://127.0.0.1:8000/produtos?senha=1"            # 400: coluna desconhecida
```
