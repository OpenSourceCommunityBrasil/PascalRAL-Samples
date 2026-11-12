# WebPagesExample

Programa de console que mostra as páginas web do PascalRAL 2.0: `TRALMustacheEngine` com os templates criados no código (layout com HTMX, página e parcial da lista), `TRALViewModule` (views `/`, `/items`, `/login`, `/logout`, `/upload`), `TRALWebModule` com sessões em `TRALFileStore` (`SessionStorage := wssStore`), `TRALCSRFPlugin` (token em `{{{csrf_field}}}` e no cabeçalho `X-CSRF-Token` do HTMX) e `TRALUploadScanPlugin` com `TRALClamAVScanner`. Pacotes: `pascalral`, `RALNetPackage`, `RALModuleWebPackage` e o do motor (`fpHTTPRAL`).

## Como rodar

1. Instale/compile os pacotes acima e compile `ralWebPagesExample.lpr`.
2. Rode: o servidor sobe na porta 8000 e espera ENTER. Abra http://localhost:8000/.
3. A lista de tarefas fica numa só variável da sessão; o formulário `hx-post` troca apenas a lista (a view responde só o fragmento quando o pedido é HTMX) e dispara o evento `itemAdded`. O login chama `RegenerateSession` e o logout `EndSession`. Um POST sem o token CSRF recebe 403.
4. Upload: o arquivo passa pelo ClamAV em 127.0.0.1:3310. Com o `clamd` rodando, um arquivo com a string de teste EICAR é recusado; sem o `clamd` o envio é aceito (`ScanFailAction := sfaAccept`).
5. Para guardar a sessão no navegador em vez do servidor, troque para `wssCookie` e defina `SessionSecret` (comentado no código).
