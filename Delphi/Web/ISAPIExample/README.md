# RALISAPIExample

Uma extensao **ISAPI** para o IIS com o RAL 2.0 (`TRALWebBrokerServer`): a DLL e'
carregada uma vez pelo IIS, o servidor fica ativo enquanto ela estiver carregada
(os plugins guardam estado entre pedidos) e cada pedido passa pelo
`TRALWebBrokerModule`.

No IIS: *ISAPI and CGI Restrictions* libera a DLL, um *Handler Mapping* do tipo
`ISAPI-dll` a executa; depois `http://localhost/ral/RALISAPIExample.dll/ping`.

O mesmo servidor vira modulo do Apache 2.4 trocando o `Web.Win.ISAPIApp` pelo
`Web.ApacheApp` + `Web.HTTPD24Impl` (veja a wiki).

Pacotes: `PascalRAL` e `WebBrokerRAL`.

Guia: [IIS e Apache](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/iis-apache).
