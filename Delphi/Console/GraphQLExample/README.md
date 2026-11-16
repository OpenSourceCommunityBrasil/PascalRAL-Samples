# RALGraphQLExample

Um endpoint **GraphQL** no RAL 2.0 (`TRALGraphQLModule`, pacote
`RALModuleGraphQLPackage`) em `http://localhost:8096/graphql`.

- Abra o endereco no navegador: o GraphiQL (da CDN unpkg) mostra o esquema em *Docs* e
  roda consultas.
- O esquema e SDL (`Schema`); os resolvers respondem JSON e os campos de baixo leem esse
  JSON, a menos que tenham resolver proprio (`Book.author`, `Author.books`).

```graphql
{ books(author: "Machado de Assis") { title year author { name books { title } } } }
mutation { addBook(book: {title: "Vidas Secas", year: 1938, author: "Graciliano Ramos"}) { id } }
```

Pelo `curl`:

```bash
curl -X POST localhost:8096/graphql -H "Content-Type: application/json" -d "{\"query\":\"{ book(id: 1) { title } }\"}"
```

Pacotes: `PascalRAL`, `RALModuleGraphQLPackage` e o motor (Indy no Delphi, fpHTTP no
Lazarus). Tabelas de banco como tipos: `TRALGraphQLDBBinding` (`RALModuleGraphQLDBPackage`).

Guia: [GraphQL](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/graphql).
