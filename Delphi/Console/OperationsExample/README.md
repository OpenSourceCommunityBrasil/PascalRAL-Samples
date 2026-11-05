# RALOperationsExample

Um servidor RAL 2.0 pronto para producao (`Operacao.Exemplo.pas`):

- `TRALLogPlugin`: uma linha por pedido no console (formato combined);
- `ErrorFormat := efProblemJSON`: os erros saem no JSON da RFC 9457; o
  `ExceptionMap` transforma `EValidacao` em 422 (`/validar`);
- `TRALRateLimitPlugin`: 30 pedidos por minuto por IP, e `/instavel` so 5 a cada
  10 segundos (429 com `Retry-After`);
- `TRALResponseCachePlugin`: `/produtos` fica 15 segundos no cache
  (`X-Cache: HIT`, `Age`); toda resposta GET ganha `ETag` e responde 304 a
  `If-None-Match`;
- `TRALHealthPlugin`: `/health/live` e `/health/ready` (com uma verificacao);
- `TRALMetricsPlugin`: `/metrics` para o Prometheus;
- `TRALTracePlugin`: `traceparent` e `traceresponse`;
- `/chamar`: um `TRALClient` com `Retry.MaxAttempts := 3` chama `/instavel`, que
  falha duas vezes a cada tres.

Pacotes: `PascalRAL`, `IndyRAL`, `RALPluginObservabilityPackage`,
`RALPluginTrafficPackage` e `RALPluginCachePackage`.

Teste o 304 com: `curl -i -H 'If-None-Match: "<o ETag da primeira resposta>"' http://localhost:8000/produtos`.

Guia: [Operacao](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/operacao).
