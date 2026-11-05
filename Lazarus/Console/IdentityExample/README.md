# RALIdentityExample

Identidade num servidor RAL 2.0 (`Identidade.Exemplo.pas`):

- `TRALPasswordList`: as senhas da ana e da bia guardadas so' como hash
  Argon2id (`RALPasswordHash`), conferidas em tempo constante;
- `TRALServerJWTAuth`: o login (`POST /gettoken` com `usuario` e `senha`) emite o
  token com os papeis (`roles`) e o departamento; duas chaves em `Keys` (a mais
  nova assina, a antiga ainda confere) e a revogacao num `TRALMemoryStore`;
- `TRALTOTP`: a ana tem segundo fator; o programa mostra o `otpauth://` para o
  aplicativo autenticador e o codigo do momento; um codigo nao vale duas vezes;
- `/perfil` (qualquer usuario), `/admin` (`RequireRoles('admin')`), `/vendas`
  (a politica `vendas` do `TRALAuthorizationPlugin`: papel vendas ou admin e
  `dept` comercial ou ti), `POST /sair` (revoga o token usado), `POST
  /sair-de-todos` (o admin desloga a bia de todos os aparelhos);
- com `RAL_OIDC_ISSUER`, `RAL_OIDC_CLIENT` e `RAL_OIDC_SECRET` no ambiente, o
  `TRALOIDCLogin` faz o login pelo provedor em `/oidc/login` (o token vai no
  cookie). Registre no provedor a volta `http://localhost:8000/oidc/callback`.

Pacotes: `PascalRAL`, `fphttpral`, `RALPluginAuthPackage` e
`RALCryptoPasswordPackage`.

Experimente:

```
curl -d "usuario=bia&senha=senha-da-bia" http://localhost:8000/gettoken
curl -H "Authorization: Bearer <token>" http://localhost:8000/vendas
curl -H "Authorization: Bearer <token>" http://localhost:8000/admin     (403)
curl -X POST -H "Authorization: Bearer <token>" http://localhost:8000/sair
curl -H "Authorization: Bearer <token>" http://localhost:8000/perfil    (401)
```

Guias: [Papeis e politicas](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/autorizacao),
[Senhas, revogacao e TOTP](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/senhas),
[OpenID Connect](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/oidc).
