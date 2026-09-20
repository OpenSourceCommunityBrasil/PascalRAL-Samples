# MsQuicBenchmark

Benchmark e teste do engine **MsQuic** (QUIC, RFC 9000) do PascalRAL, em dois
programas VCL: um servidor e um cliente. Os dois lados têm de ser RAL, porque o
que trafega sobre o QUIC é o frame binário do RAL, não HTTP/3.

## O que precisa

- **`msquic.dll`** ao lado de cada executável, da build **OpenSSL** do MsQuic
  (a build SChannel não tem TLS 1.3 no Windows 10). Baixe de
  <https://github.com/microsoft/msquic/releases> o pacote
  `msquic_windows_x64_Release_openssl.zip` (ou o x86 para 32 bits) e copie a
  DLL. O engine só carrega a biblioteca ao ligar o servidor ou na primeira
  requisição do cliente, então o programa abre sem ela.
- **Certificado e chave PEM** para o servidor. QUIC não tem modo sem TLS. Um
  par autoassinado serve; com o OpenSSL instalado:

  ```
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -subj "/CN=localhost" -days 3650
  openssl x509 -in cert.pem -noout -fingerprint -sha256
  ```

  A segunda linha imprime a impressão digital, que é o que vai no campo
  **Pin** do cliente para aceitar só esse certificado sem desligar a validação.
- **Firebird** (3 ou mais) para a aba de banco. O servidor cria o arquivo
  `benchmark.fdb` ao lado do executável e a tabela `BENCH` com 2000 registros
  de seis tipos diferentes. Usuário e senha ficam na tela do servidor.

## Servidor

Porta UDP, `PoolCount` (quantas threads respondem — uma basta para rota que só
computa, e é o que limita a rota `/lento`), certificado e chave, compressão e
criptografia com a chave. Sobe as rotas `/ping`, `/params`, `/multipart`,
`/eco` e `/lento`, publica o Firebird pelo DAO (`TRALFDConnection`, rota
`/RALConnBench`) e pelo DBWare (`TRALDBModule`, rotas sob `/db`), e mostra
conexões aceitas e requisições atendidas.

## Cliente

A barra de cima vale para as três abas: host, porta, timeout, compressão,
criptografia e chave (têm de bater com o servidor), **Validar certificado**
(cadeia do sistema, que recusa o autoassinado), **Pin** (SHA-256 do
certificado, aceita só ele) e o modo de conexão:

- *Uma conexão por thread*: `ShareConnection` desligado, cada thread de
  requisição abre a sua conexão QUIC.
- *Uma conexão por cliente, multiplexada*: `ShareConnection` ligado; cada
  cliente do benchmark tem uma conexão só, e as requisições simultâneas dele
  viajam como streams dela — o que um aparelho com várias telas abertas faz.

**Benchmark** — clientes × simultâneas por cliente × rajadas. Com `10 3 50`
sobem 10 clientes, cada um com 3 threads mandando uma requisição por vez, 50
vezes cada: 1500 requisições. Sai taxa de erro, vazão, tempo médio, mínimo e
máximo de resposta e o tempo total. A rota `lento` (50 ms) é para ver o efeito
do `PoolCount` do servidor.

**Testes** — ping pong, parâmetros (query, corpo e cookie devolvidos pelo
servidor), multipart (dois arquivos e um campo) e eco de 20 KB, com a saída no
memo. Cada botão cria um cliente novo, então mudar a barra de cima vale na
hora.

**Banco (Firebird)** — a mesma consulta pelos dois stacks, lado a lado: à
esquerda o DAO (`TRALFDQuery`, que é um `TFDQuery` apontado para um
`TRALClient`), à direita o DBWare (`TRALDBFDMemTable` + `TRALDBConnection`).
Edite na grade e grave com o `ApplyUpdates` de cada lado; a consulta reabre
para provar que foi.
