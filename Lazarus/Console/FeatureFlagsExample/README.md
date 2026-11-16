# FeatureFlagsExample

Programa de console com feature flags do PascalRAL 2.0 (pacote `RALPluginFeatureFlagsPackage`), sobre o motor InProc (nenhuma porta é aberta).

## O que ele faz

1. **`checkout-novo`** está ligado para 30% dos usuários, sempre os mesmos, e para `ana`; o programa mostra quem, entre 20 clientes, tem o recurso.
2. **`relatorio`** vem do arquivo `flags.json` (pela configuração externa, `TRALConfig`) e guarda a rota `/relatorio`: desligado, ela responde 404.
3. O programa reescreve o arquivo ligando o recurso e, sem reiniciar, a mesma rota passa a responder 200.

## Como rodar

Instale/compile `PascalRAL`, `InProcRAL`, `RALHostingPackage` e `RALPluginFeatureFlagsPackage`, compile e execute.

Guia: [Feature flags](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/feature-flags).
