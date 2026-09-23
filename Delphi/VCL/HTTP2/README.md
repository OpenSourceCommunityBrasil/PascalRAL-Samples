# RALDemoHTTP2

Servidor e cliente no mesmo executável, para ver o HTTP/2 do PascalRAL funcionando e medir o que ele muda. Quatro abas:

1. **Servidor** — sobe o `TRALSynopseServer` nos três modos (`smThreads`, `smAsync`, `smHttpSys`). Só o `smHttpSys` serve HTTP/2, porque quem o implementa é o kernel do Windows; o mORMot2 não tem h2 próprio.
2. **Rotas** — chamadas comuns com parâmetro tipado e com erro. Cada resposta mostra o protocolo **negociado**, lido de `TRALResponse.ProtocolVersion`.
3. **Banco** — os dois stacks de banco do RAL sobre a mesma conexão: o DAO (`TRALFDQuery` sobre `TRALFDConnection`) e o DBWare (`TRALDBFDMemTable` sobre `TRALDBModule`), cada um com o seu caminho de volta ao servidor.
4. **HTTP/1.1 x HTTP/2** — a medição, explicada abaixo.

## Antes de rodar

O botão **Preparar**, na aba Servidor, faz tudo o que o HTTP/2 precisa e pede elevação uma vez só:

- cria um certificado autoassinado para `localhost` e o torna confiável nesta máquina;
- amarra o certificado à porta 8443 com `netsh http add sslcert`;
- reserva a URL com `netsh http add urlacl`.

Sem isso o servidor sobe, mas em HTTP/1.1: o h2 se negocia por ALPN, que só existe dentro do TLS, e no `smHttpSys` o certificado **não** vem de `SSL.CertificateFile` — vem da loja da máquina, amarrado à porta de fora.

O TLS só fica disponível no modo HTTP.sys, e é por isso: os modos de socket leem o certificado de arquivo, e este exemplo não traz nenhum.

## A aba de medição

Cinco linhas, na ordem em que uma aplicação costuma evoluir:

| Linha | O que é |
|---|---|
| Indy 1.1 | um socket por `TRALClient` — o Indy não sabe compartilhar, e é de onde a maioria dos projetos vem |
| netHTTP sem share h2 | a armadilha: h2 sem compartilhar é igual ao anterior, e ainda deixa as conexões abertas |
| netHTTP com share 1.1 | o que o `ShareConnection` compra sozinho |
| netHTTP com share h2 | uma conexão só, multiplexada |
| netHTTP com share h2 + mantida viva | a mesma, sem deixar esfriar entre as rodadas |

Três colunas contam coisas diferentes: **abertas no total** é quantas vezes se pagou handshake; **ao mesmo tempo (pico)** é quantas existiram no mesmo instante; **tempo** é só o trabalho — as pausas são descontadas.

Duas peças existem para a medição não mentir:

- **O relay local** conta as conexões e simula o custo de abrir uma. Contar por fora (netstat) engana, porque conexão ociosa fecha sozinha e TIME_WAIT continua aparecendo. O atraso é aplicado **ao abrir**, não a cada trecho encaminhado — atrasando cada trecho, o medidor puniria justamente a multiplexação.
- **A pausa entre rodadas** deixa as conexões esfriarem, como um servidor, um proxy ou o NAT de uma operadora fazem com keep-alive ocioso. Sem ela o HTTP/1.1 sai medido melhor do que é: as conexões dele ficam quentes a rajada inteira e o handshake é pago uma vez na vida.

A última linha usa o `KeepAliveInterval`. No Android isso é o engine OkHttp mandando frames PING de HTTP/2; no Windows é `WINHTTP_OPTION_HTTP2_KEEPALIVE`, que existe a partir do Windows 11 — onde não existe, o exemplo cai num batimento imitado com um pedido leve, e a coluna de avisos diz qual dos dois rodou.

## A linha do Indy

Precisa de OpenSSL 1.0.2 (`libeay32.dll` e `ssleay32.dll`) ao lado do executável — o engine Indy fala TLS por OpenSSL, e o Windows não traz esse par. Sem eles a linha não quebra a medição: a coluna de avisos diz exatamente quais arquivos faltam.
