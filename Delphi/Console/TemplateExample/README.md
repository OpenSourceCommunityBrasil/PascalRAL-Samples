# TemplateExample

Servidor de console que mostra o motor de templates Mustache do PascalRAL 2.0 (`TRALMustacheEngine`, pacote `RALModuleWebPackage`).

## Como rodar

1. Instale/compile os pacotes `PascalRAL`, `RALModuleWebPackage` e o do motor (`IndyRAL` no Delphi, `fpHTTPRAL` no Lazarus).
2. Compile e execute o projeto (`RALTemplateExample.dpr` ou `ralTemplateExample.lpr`). O servidor sobe na porta 8000.
3. Abra no navegador:
   - `http://localhost:8000/produtos`
   - `http://localhost:8000/ola?nome=<b>Ana</b>`

## O que olhar

- `CriarTemplates`: o `layout` (blocos `{{$title}}` e `{{$content}}`), o parcial `linha` e a página `produtos`. Com `Layout := 'layout'` a página entra como o bloco `content` do layout e o seu `{{$title}}` substitui o do layout.
- `/produtos`: `TRALTemplateMap` liga `produtos` a um dataset em memória (`TBufDataset` no Lazarus, `TClientDataSet` com `MidasLib` no Delphi), percorrido por `{{#produtos}}...{{/produtos}}`; `{{^produtos}}` aparece quando o dataset está vazio. O nome `Mouse <sem fio>` sai escapado.
- `/ola`: `RenderSource` renderiza um texto na hora, sem cache; `{{nome}}` escapa o HTML (`&lt;b&gt;`).
