# RedisExample

Programa de console com o cliente Redis/Valkey do PascalRAL 2.0 (pacote `RALStoreRedisPackage`).

## O que ele faz

1. **Comandos:** texto com tempo de vida, contador, hash.
2. **Pipeline:** 1000 comandos numa ida e volta só, comparados com 1000 idas e voltas.
3. **Pub/sub:** um `TRALRedisSubscriber`, numa conexão só dele, recebe o que se publica.
4. **Dois servidores, um limite:** dois `TRALRedisStore`, como dois servidores teriam, somam o mesmo contador.

## Como rodar

Tenha um Redis ou Valkey acessível. O endereço vem de `RAL_REDIS_HOST`, `RAL_REDIS_PORT` e `RAL_REDIS_PASSWORD` (padrão `127.0.0.1:6379`, sem senha). Instale/compile `PascalRAL`, `RALNetPackage` e `RALStoreRedisPackage`, compile e execute.

Guia: [Redis e Valkey](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/redis).
