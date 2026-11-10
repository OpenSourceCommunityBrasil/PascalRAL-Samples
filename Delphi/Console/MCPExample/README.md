# MCPExample

Programa de console que mostra o servidor MCP (Model Context Protocol) do PascalRAL 2.0: `TRALMCPServer` com `TRALMCPModule` (HTTP) e `TRALMCPStdio` (entrada e saída padrão), mais o `TRALMCPClient`. Pacotes: `RALModuleMCPPackage`, `RALModuleJSONRPCPackage` e o do motor (`IndyRAL`).

**Só a revisão `2026-07-28` do protocolo é falada.** Um cliente que peça outra versão recebe o erro -32022 (versão não suportada).

## O que o servidor oferece

- Ferramentas: `somar` (dois inteiros `a` e `b`), `hora` (sem parâmetros; chama `ACall.Progress`) e `saudar` (parâmetro `nome` opcional; se não vier, pede o nome ao cliente por `ACall.Elicit`, o fluxo MRTR: a chamada termina pedindo a entrada e o cliente repete com a resposta).
- Recurso `app://config` e prompt `revisar_codigo` (argumento `codigo`).

## Como rodar

1. Instale/compile os pacotes acima e compile `RALMCPExample.exe`.
2. Sem parâmetro: sobe o HTTP na porta 8000, em `/mcp`, e no mesmo processo o `TRALMCPClient` chama as ferramentas (o `OnInputRequest` responde o nome do `saudar`), lê o recurso e o prompt e imprime tudo; depois espera ENTER. Um número como parâmetro troca a porta (`RALMCPExample.exe 8765`).
3. Com `--stdio`: serve por entrada e saída padrão (`TRALMCPStdio.Run`), uma mensagem JSON por linha. Nada além de mensagens MCP vai ao stdout.

## Configurar um cliente de IA (stdio)

Clientes MCP iniciam o executável e falam com ele por stdio. Num arquivo de configuração no formato `mcpServers` (Claude Desktop, Claude Code, Cursor...):

```json
{
  "mcpServers": {
    "pascalral-exemplo": {
      "command": "C:\\caminho\\RALMCPExample.exe",
      "args": ["--stdio"]
    }
  }
}
```

Para `saudar` pedir o nome, o cliente precisa declarar a capacidade `elicitation`; sem ela o servidor responde -32021 (capacidade ausente).

## Testar o HTTP com curl

```
curl -X POST http://localhost:8000/mcp -H "Content-Type: application/json" \
  -H "MCP-Protocol-Version: 2026-07-28" -H "Mcp-Method: tools/call" -H "Mcp-Name: somar" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"somar","arguments":{"a":2,"b":3},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientCapabilities":{}}}}'
```

O `_meta` com a versão e as capacidades do cliente é obrigatório em toda requisição (o servidor não guarda sessão), e os cabeçalhos `MCP-Protocol-Version`, `Mcp-Method` e `Mcp-Name` têm de bater com o corpo, senão a resposta é o erro -32020. A resposta traz `"text":"5"`.

## O que olhar

- `Tools.AddTool` + `Params.AddParam` declaram a ferramenta; `Resources.AddResource` e `Prompts.AddPrompt` fazem o mesmo para recurso e prompt.
- Os manipuladores rodam nas threads do servidor: não escreva no console de dentro deles.
- `ACall.Progress` só vira notificação quando o cliente pede progresso e o transporte transmite (stdio, ou HTTP em motor com transmissão ao vivo).
