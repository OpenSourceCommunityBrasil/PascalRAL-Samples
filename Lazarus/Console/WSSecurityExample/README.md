# RALWSSecurityExample

Servico SOAP que exige o **WS-Security UsernameToken** (`TRALServerWSSecurityAuth`,
so a senha em resumo: ela nunca viaja) e o `TRALSOAPClient` que manda o login com
`Security.PasswordType := wptDigest`. Os usuarios vem de `OnGetPassword`; a
operacao sabe quem entrou por `ARequest.Core.Identity.Name`. Senha errada e senha
em texto sao recusadas com a falha `wsse:FailedAuthentication`.

No fim, o `Body` da resposta sai na forma canonica exclusiva (`RALXMLC14N`), o que
uma assinatura XML resume.

Servidor e cliente rodam no mesmo processo pelo motor InProc (`inproc://calc`),
sem porta; com um motor de rede o codigo e' o mesmo.

Pacotes: `PascalRAL`, `InProcRAL`, `RALModuleXMLPackage` e `RALModuleSOAPPackage`.

Guias: [WS-Security](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/ws-security)
e [XML](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/xml).
