# RALFastCGIExample

Uma aplicacao **FastCGI** RAL 2.0: o nginx (ou o Apache com `mod_proxy_fcgi`, ou o
IIS) recebe o HTTP e passa os pedidos pela porta 9000, numa conexao mantida.

```nginx
location /api/ {
  include fastcgi_params;
  fastcgi_param REQUEST_URI $request_uri;
  fastcgi_pass 127.0.0.1:9000;
  fastcgi_keep_conn on;
  fastcgi_buffering off;   # para o /api/relogio chegar ao vivo
}
```

`/api/ping` responde `pong`; `/api/relogio` manda um evento por segundo (SSE).

Pacotes: `PascalRAL`, `RALNetPackage` e `FastCGIRAL`.

Guia: [FastCGI](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/fastcgi).
