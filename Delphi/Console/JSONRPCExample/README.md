# JSONRPCExample

Programa de console que mostra o JSON-RPC 2.0 do PascalRAL 2.0 (`TRALJSONRPCModule` e `TRALJSONRPCClient`, pacote `RALModuleJSONRPCPackage`). Ele sobe o servidor e, no mesmo processo, usa o cliente para chamar cada método, e depois sai.

## Como rodar

1. Instale/compile os pacotes `PascalRAL`, `RALModuleJSONRPCPackage` e o do motor (`IndyRAL`).
2. Compile e execute `RALJSONRPCExample.dpr`. O servidor sobe na porta 8000 e as chamadas saem impressas.
3. Para deixar o servidor no ar e testar de fora, rode com o parâmetro `--serve` (ENTER encerra):

```
curl -X POST http://localhost:8000/rpc -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "soma", "params": {"a": 2, "b": 3}, "id": 1}'
```

Resposta: `{"jsonrpc":"2.0","result":5,"id":1}`. Um lote é um array de chamadas, e uma notificação (sem `id`) responde 204 sem corpo.

## O que olhar

- Servidor: `Methods.AddMethod` declara `soma` (dois `jptInteger`), `saudacao` (um `jptString`), `agora` (sem parâmetros) e `falha`, que levanta `ERALJSONRPCError.CreateRPC(-1, 'Saldo insuficiente', '{"saldo": 10}')`. Com parâmetros declarados, o RAL confere quantidade e tipos antes do método e responde *Invalid params* (-32602).
- `ARequest.Param('a')` lê o parâmetro por nome ou por posição (`{"a":2,"b":3}` ou `[2,3]`); a resposta se dá em `AResult.SetXxx`.
- Cliente: `Call` (parâmetros e resultado em `TRALJSON`), `CallText` (em texto), `Notify` (sem resposta) e `NewBatch` (várias chamadas num só POST; `ErrorCode`/`Value` por posição). Um erro do servidor volta como `ERALJSONRPCError`.
- `RALJSONRPCRegisterObject` (só com RTTI estendida, `{$IFDEF RALHasExtRTTI}`, Delphi 2010 em diante) expõe os métodos públicos de `TCalculadora` como `calc.Somar` e `calc.Dividir`.
- Os métodos rodam nas threads do servidor: não escreva no console de dentro deles.
