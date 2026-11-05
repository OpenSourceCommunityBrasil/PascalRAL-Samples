# Http2Benchmark

O **mesmo** benchmark do [`QuicBenchmark`](../QuicBenchmark/) ao lado, com os
motores trocados — é para isso que ele existe: rodar os dois, lado a lado, na
mesma máquina, e comparar QUIC com HTTP/2.

| projeto | engine do servidor | engine do cliente | transporte |
|---|---|---|---|
| `QuicBenchmark` | `TRALMsQuicServer` | MsQuic | QUIC (UDP), frame binário do RAL |
| **`Http2Benchmark`** | `TRALSynopseServer` (mORMot2) | **netHTTP** | TCP + TLS, HTTP/1.1 ou HTTP/2 |

As telas, as rotas, o banco e as contas são os mesmos, de propósito. O que muda
é o transporte, e por isso os números dos dois são comparáveis.

## O que precisa

- **Windows.** HTTP/2 aqui sai do `http.sys`, o driver HTTP do kernel — mORMot2
  não tem HTTP/2 próprio, e é por isso que `smHttpSys` é o único modo que o
  serve. O cliente netHTTP também lê a versão negociada só no Windows, pelo
  WinHTTP.
- **Um passo de administrador, uma vez por porta**: o botão **Preparar
  http.sys** do servidor. Ele sobe elevado um PowerShell (em janela própria — é
  como a elevação funciona) que cria um certificado autoassinado para
  `localhost` e para o nome da máquina, o torna confiável aqui, **apaga** as
  amarrações anteriores da porta, amarra o certificado **por endereço**
  (`ipport=0.0.0.0` e `[::]`) **e por nome** (`hostnameport`, que é SNI),
  reserva `https://+:porta/` e `https://localhost:porta/`, e grava `pin.txt` ao
  lado do executável com a impressão digital SHA-256.
  Sem a reserva, o servidor não sobe: `AddUrl` volta **5** (acesso negado).

- **Firebird** (3 ou mais) apenas para a aba de banco. Sem ele o servidor sobe
  igual e as rotas respondem — só a aba Banco fica sem resposta. O botão *Criar
  banco* cria `benchmark.fdb` e a tabela `BENCH` com 2000 registros de seis
  tipos diferentes; com o servidor já no ar, ele também reconecta o DAO, que é
  a única conexão que abre na subida (o DBWare pede a dele ao pool a cada
  requisição, e por isso nem percebe que o banco faltava).

Nada de DLL para copiar: ao contrário do QUIC, que precisa de `msquic.dll`, aqui
o TLS é do Windows (SChannel, pelo `http.sys`) e o cliente é o `THTTPClient` da
RTL sobre o WinHTTP.

### A armadilha dos 503, que custou uma tarde

Com o certificado amarrado **só por `ipport`**, um prefixo por **nome**
(`https://localhost:8443/`) é registrado sem erro, a fila fica ativa, o
`netsh http show servicestate` mostra tudo certo — e o http.sys responde **503 a
todo pedido**, sem entregar nada à aplicação. Parece servidor quebrado e não é:
reproduzido com um `HttpListener` do .NET, sem RAL nem mORMot2 no meio, no mesmo
prefixo. No curinga forte (`https://+:8443/`), o mesmo `HttpListener` recebe e
responde 200.

Daí duas escolhas deste exemplo: o **Domínio do http.sys** nasce `+`, que casa
por endereço e ainda deixa um cliente da rede chegar por IP — o que um benchmark
honesto precisa —, e a preparação amarra **também** por `hostnameport`, para
quem preferir pôr um nome ali.

E o outro que a preparação já resolve: o `netsh` **recusa** uma amarração que já
existe, e o estrago é silencioso — o certificado novo entra na loja, a porta
continua com o velho, e a segunda preparação parece não ter feito nada. Por isso
ela apaga antes de amarrar.

### Desfazendo tudo

Preparações repetidas — deste exemplo, do `RALDemoHTTP2`, de versões diferentes
do script — empilham certificados na loja da máquina e deixam a mesma porta com
amarrações apontando para certificados diferentes. O http.sys atende pela mais
específica, que pode não ser a que o cliente espera, e o sintoma é um handshake
que fecha com o certificado "errado" sem ninguém entender por quê.

[`DesfazerPreparacaoHttps`](../HTTP2/DesfazerPreparacaoHttps/) devolve a máquina
ao estado de antes: apaga as amarrações (por porta **e** por certificado, o que
pega uma esquecida em outra porta), as reservas de URL e os certificados
autoassinados de `localhost` / nome da máquina das lojas `My` e `Root`. Fica na
pasta do `RALDemoHTTP2` porque desfaz a preparação dos dois exemplos.

```powershell
.\DesfazerPreparacaoHttps.ps1                     # pergunta as portas, mostra e confirma
.\DesfazerPreparacaoHttps.ps1 -Listar             # só mostra o que encontrou
.\DesfazerPreparacaoHttps.ps1 -Portas 8443,9443   # sem perguntar as portas
.\DesfazerPreparacaoHttps.ps1 -Force              # apaga sem confirmar
```

Ele pergunta as portas (não há porta padrão), pede a elevação sozinho, lista tudo antes de apagar e só mexe em
certificado **autoassinado** cujo titular é um desses dois nomes — nunca numa CA
de verdade. Ainda assim, leia a lista antes de confirmar: se outro
desenvolvimento seu usa um autoassinado de `localhost`, ele aparece ali.

## Servidor

Porta TCP, `PoolCount` (quantas requisições são processadas ao mesmo tempo — uma
basta para rota que só computa, e é o que limita a rota `/lento`), **Modo**,
**Domínio do http.sys**, compressão e criptografia com a chave. Sobe as rotas
`/ping`, `/params`, `/multipart`, `/eco` e `/lento`, publica o Firebird pelo DAO
(`TRALFDConnection`, rota `/RALConnBench`) e pelo DBWare (`TRALDBModule`, rotas
sob `/db`).

**O modo manda no TLS**, e não o contrário:

| modo | como espera pelos sockets | esquema | HTTP/2 |
|---|---|---|---|
| `threads` | uma thread por conexão mantida viva | `http` | não |
| `async` | um laço de eventos (IOCP) | `http` | não |
| **`http.sys`** | fila do kernel | `https` | **sim, por ALPN** |

Os dois modos de socket leriam o certificado de `SSL.CertificateFile`, e este
benchmark não tem arquivo de certificado nenhum — o dele mora na loja da
máquina. Então eles sobem em `http` simples, e é isso que os torna úteis: são a
**linha de base HTTP/1.1**.

O **Domínio do http.sys** tem de ser o *mesmo texto* que a reserva do `netsh`
usou. O kernel casa prefixo por prefixo: um servidor pedindo `+` não é coberto
por uma reserva feita para `localhost`. O padrão é `+` — veja a armadilha dos
503 acima.

Uma nota sobre conferir com `curl`: o `curl.exe` que vem no Windows é compilado
com Schannel e **não tem HTTP/2** (`curl --version` não lista `h2` em
*Protocols*). Ele fala com este servidor normalmente, só que sempre em 1.1, e
`--http2` é ignorado em silêncio. Quem diz a verdade é o cliente do exemplo, que
lê a versão negociada do próprio WinHTTP.

O status mostra **`N req / C conn (R req/conn) - H h2`**, e a razão do meio é a
única resposta direta para "a multiplexação aconteceu?". Tudo sai do `OnRequest`
do servidor, o único ponto por onde passa rota, DAO e DBWare: `H` lê
`ARequest.ProtocolVersion` (no `http.sys` vem da flag do driver, não da linha de
pedido, que continua dizendo 1.1 mesmo em h2) e `C` conta valores distintos de
`ARequest.ClientInfo.ConnectionID` — no `http.sys`, endereço + porta de origem do
cliente, que **todos os streams de uma conexão h2 compartilham**. O
`QuicBenchmark` mostra a mesma razão, ali com os contadores do próprio engine
MsQuic.

A busca da conexão roda **sem trava**: o caminho comum é "já vista", e uma
medição não pode pagar um lock por requisição. A trava só aparece ao registrar
uma conexão nova, uma vez por conexão.

### A conta certa de conexões, e as duas que enganaram

O `http.sys` oferece dois ids de conexão, e nenhum dos dois serve:

- `ConnectionId` é **por stream** em HTTP/2 — cada requisição multiplexada ganha
  o seu. Com ele, 20 requisições sequenciais davam **1** conexão pedindo 1.1 e
  **20** pedindo h2, e 51 requisições simultâneas num cliente limitado a uma
  conexão contavam como 51. Pareceu que o WinHTTP não reusava conexão h2 — e ele
  reusa: o `RALDemoHTTP2`, que conta sockets TCP num relay, sempre mostrou.
- `RawConnectionId` acertou no Windows 10 e errou numa VPS com Windows Server:
  1500 requisições h2 como 1500 conexões, enquanto a tabela TCP do próprio
  servidor mostrava pico de **10** multiplexado e **30** sem.

O engine mORMot2 usa agora **endereço + porta de origem do cliente**, que é a
definição de conexão TCP: todos os streams de uma conexão chegam pela mesma
porta, e duas conexões vivas nunca dividem uma. De brinde, `ClientInfo.Port`
deixou de ser 0 nesse engine.

Para conferir por fora, no servidor, durante um benchmark em `/lento`:

```powershell
$pico = 0
while ($true) {
  $n = @(Get-NetTCPConnection -LocalPort 8443 -State Established -ErrorAction SilentlyContinue).Count
  if ($n -gt $pico) { $pico = $n }
  Write-Host ("`r agora: {0,4}   pico: {1,4}" -f $n, $pico) -NoNewline
  Start-Sleep -Milliseconds 200
}
```

A lição que vale para qualquer medição parecida: um número que contradiz um
instrumento independente é, primeiro, suspeita sobre o instrumento.
## Cliente

A barra de cima vale para as três abas: host, porta, timeout, compressão,
criptografia e chave (têm de bater com o servidor), **Esquema**, **Versão
HTTP**, **Validar certificado**, **Pin** e o modo de conexão.

**Versão HTTP** é o que o cliente *pede* (`TRALClient.HTTPVersion`). Pedir não é
obter: o que o ALPN fechou de verdade chega em `TRALResponse.ProtocolVersion`, e
é isso que o rótulo **HTTP/2: N de M** do benchmark conta. Se ele vier zerado,
confira as três coisas: esquema `https`, versão `2` aqui, servidor em
`http.sys`.

**Esquema** existe porque os modos de socket do servidor sobem em `http`. Pedir
HTTP/2 em `http` simples é recusado na hora, com a razão: sem TLS não há ALPN.

**Pin** é a impressão digital SHA-256 do certificado — o `pin.txt` que a
preparação gravou. Com ele valendo, só aquele certificado é aceito e o nome do
host deixa de importar. O certificado da preparação já vai para a loja `Root`
desta máquina, então **Validar certificado** também funciona sozinho, desde que
o host seja `localhost` (é o CN). Para chegar por IP, use o pin.

O modo de conexão:

- *Uma conexão por thread*: `ShareConnection` desligado. Cada thread de
  requisição usa o seu próprio transporte — e, sob HTTP/1.1, é o que dá
  paralelismo de verdade.
- *Uma conexão por cliente, multiplexada*: `ShareConnection` ligado. Cada
  cliente do benchmark tem um transporte só, e o WinHTTP é limitado a **uma**
  conexão por servidor (`WINHTTP_OPTION_MAX_CONNS_PER_SERVER`) — é isso que
  transforma h2 em multiplexação. Atenção ao par: com `ShareConnection` ligado e
  **HTTP/1.1**, essa mesma conexão única enfileira as requisições simultâneas em
  vez de as correr, e a vazão cai. É a comparação mais interessante da tela, e é
  a razão de os dois botões existirem.

As máquinas do benchmark não colapsam numa conexão só apesar de todas julgarem o
certificado igual: cada uma instala o seu próprio `OnValidateServerCert`, e
`CertPolicyKey` leva o endereço do método **e** o do objeto, então cada máquina
ganha o seu transporte. Mesmo truque do cliente QUIC.

**Benchmark** — clientes × simultâneas por cliente × rajadas. Com `10 3 50`
sobem 10 clientes, cada um com 3 threads mandando uma requisição por vez, 50
vezes cada: 1500 requisições. Sai taxa de erro, vazão, quantas voltaram em h2,
tempo médio, mínimo e máximo de resposta e o tempo total. A rota `lento` (50 ms)
é para ver o efeito do `PoolCount` do servidor.

**Testes** — ping pong, parâmetros (query, corpo e cookie devolvidos pelo
servidor), multipart (dois arquivos e um campo) e eco de 20 KB, com a saída no
memo; o ping e o eco também imprimem o protocolo negociado. Cada botão cria um
cliente novo, então mudar a barra de cima vale na hora.

**Banco (Firebird)** — a mesma consulta pelos dois stacks, lado a lado: à
esquerda o DAO (`TRALFDQuery`, que é um `TFDQuery` apontado para um
`TRALClient`), à direita o DBWare (`TRALDBFDMemTable` + `TRALDBConnection`).
Edite na grade e grave com o `ApplyUpdates` de cada lado; a consulta reabre para
provar que foi.

## Como comparar com o QUIC

Rode as duas medições com os **mesmos** três números, a mesma rota, a mesma
compressão e a mesma criptografia. Três combinações valem a pena, e as três
saem só da barra do cliente:

1. `https` + `1.1` + *uma conexão por thread* — a linha de base.
2. `https` + `2` + *uma conexão por cliente, multiplexada* — HTTP/2 fazendo o
   que ele existe para fazer.
3. o `QuicBenchmark` com *uma conexão por cliente, multiplexada* — o mesmo
   desenho sobre QUIC.

Onde os dois divergem, e vale saber antes de olhar os números: em HTTP/2 um
pacote perdido para a **conexão TCP inteira**, e com ela todas as requisições
multiplexadas nela; em QUIC cada requisição é um stream, e a perda atrasa só o
seu. Numa rede local isso não aparece. Também não se compara o custo de aperto
de mão numa medição longa: o 1-RTT do QUIC contra os 3 do TCP+TLS 1.2 se paga
uma vez e some em 1500 requisições — para ver essa diferença, meça uma rajada
curta com conexão nova.

E o de sempre: **a máquina que mede é a máquina que serve**. Um resultado com
servidor e cliente no mesmo micro compara os stacks, não a rede.
