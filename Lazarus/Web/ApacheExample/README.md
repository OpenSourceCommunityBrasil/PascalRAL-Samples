# ralapacheexample

Um modulo do **Apache 2.4** com o RAL 2.0 (`TRALWebBrokerServer` sobre o
`custapache24` do fcl-web). O Apache carrega a biblioteca uma vez; o servidor fica
ativo enquanto ela estiver carregada.

```apache
LoadModule ral_module /caminho/libralapacheexample.so
<Location /ral>
  SetHandler ral-handler
</Location>
```

Depois `http://localhost/ral/ping`. No Linux a biblioteca precisa de codigo
relocavel (`-Cg`, ja ligado no projeto).

Pacotes: `PascalRAL` e `webbrokerral`.

Guia: [IIS e Apache](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/iis-apache).
