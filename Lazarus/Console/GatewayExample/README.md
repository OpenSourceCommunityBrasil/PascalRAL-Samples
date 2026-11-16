# ralgatewayexample

Aplicacoes **SCGI** e **uwsgi** RAL 2.0 no mesmo programa: o nginx recebe o HTTP e
passa os pedidos pela porta 4000 (SCGI) ou 3031 (uwsgi), uma conexao por pedido.

```nginx
location /scgi/ {
  include scgi_params;
  scgi_pass 127.0.0.1:4000;
  scgi_buffering off;    # para o /scgi/relogio chegar ao vivo
}
location /uwsgi/ {
  include uwsgi_params;
  uwsgi_pass 127.0.0.1:3031;
  uwsgi_buffering off;
}
```

`/scgi/ping` e `/uwsgi/ping` respondem `pong`; `/scgi/relogio` e `/uwsgi/relogio`
mandam um evento por segundo (SSE). `PathBase` tira o prefixo que o nginx repassa.

Pacotes: `PascalRAL`, `RALNetPackage`, `SCGIRAL` e `UwsgiRAL`.

Guia: [SCGI e uwsgi](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/scgi-uwsgi).
