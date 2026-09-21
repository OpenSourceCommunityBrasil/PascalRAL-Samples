# QuicBenchmark

Benchmark e teste do QUIC (RFC 9000) do PascalRAL, em três programas:

| projeto | onde | o que é |
|---|---|---|
| `MsQuicServer` | `Delphi/VCL/QuicBenchmark/` | o servidor, engine **MsQuic** |
| `MsQuicClient` | `Delphi/VCL/QuicBenchmark/` | o cliente de desktop, engine **MsQuic** |
| `KwikQuicClient` | `Delphi/FMX/QuicBenchmark/` | o cliente de **Android**, engine **Kwik** |

O cliente Android está na árvore **FMX** porque é o que ele é; os outros dois
são VCL. São o mesmo benchmark, separados só pela biblioteca visual.

Os dois clientes falam com o **mesmo** servidor e fazem as mesmas coisas. Não
se parecem por acaso: os dois montam o frame pela mesma unit do RAL
(`RALQuicFrame`), então o servidor não sabe qual dos dois está do outro lado.

Os dois lados têm de ser RAL, porque o que trafega sobre o QUIC é o frame
binário do RAL, não HTTP/3 — curl, navegador, proxy reverso e CDN não leem.

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

## Cliente Android (KwikQuicClient)

Fica em **`Delphi/FMX/QuicBenchmark/KwikQuicClient`** — é FMX, então mora na
árvore FMX. As mesmas quatro funções do cliente VCL, no telefone, contra o
mesmo servidor daqui.

**Por que outro engine.** O MsQuic é uma biblioteca C, e no Android isso
significaria uma `libmsquic.so` compilada com o NDK — plataforma que o próprio
projeto do MsQuic não sustenta e para a qual ninguém publica binário. O
**Kwik** é QUIC em Java puro. E nenhuma pilha oficial do Android serve no
lugar: OkHttp, Cronet e `HttpEngine` são clientes HTTP e não expõem stream
crua, que é do que este frame precisa.

**Não precisa baixar nada.** Os cinco jars já estão em `KwikQuicClient/java/`
(648 KB no total) e o `.dproj` já os declara como `JavaReference`:

| jar | o que é |
|---|---|
| `kwik-0.11.jar` | o QUIC |
| `agent15-3.3.jar` | o TLS 1.3 que o Kwik usa |
| `hkdf-2.0.0.jar`, `io.whitfin.siphash-2.0.1.jar` | as duas dependências deles |
| `ralkwik.jar` | a ponte JNI do RAL, compilada de `PascalRAL/src/engine/kwik/java/pascalral/` |

Nenhum deles é nativo, então o mesmo conjunto serve para qualquer ABI. O Kwik
é **LGPL v3**; os outros quatro são Apache 2.0.

**Precisa de Android 8 (API 26)** ou mais novo — o `java.time` que o Kwik usa
na configuração da conexão só chega aí.

**O que muda na tela.** O cliente VCL tem a configuração numa barra em cima;
no telefone não cabe, então ela virou a primeira aba. As duas grades do banco,
que no VCL ficam lado a lado, viraram duas abas internas pelo mesmo motivo.

**Host.** Aponte para o **IP do micro na rede**, não `localhost` — o telefone
é outra máquina. O certificado autoassinado não tem esse IP no nome, então use
o campo **Pin** com a impressão digital, que é justamente o caso de uso dele:
com o pin valendo, o nome do host deixa de importar.

**Compilar e instalar.** Abra `KwikQuicClient.dproj` na IDE, escolha a
plataforma **Android 64-bit**, o aparelho no *Target* e mande **Run**. A IDE
compila, empacota e instala. Por `msbuild` fora da IDE o `.so` compila e linka,
mas o empacotamento do APK não fecha: a lista de deploy dos recursos do Android
(ícones, splash, styles) é montada pela própria IDE ao abrir o projeto.
