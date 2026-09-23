# QuicBenchmark — cliente Android

`KwikQuicClient` é a metade **Android** do benchmark QUIC do PascalRAL: FMX,
engine **Kwik**, com as mesmas quatro funções do cliente de desktop.

**O servidor não está aqui.** Ele e o cliente VCL ficam em
**`Delphi/VCL/QuicBenchmark/`**, e é lá que está o
[README completo](../../VCL/QuicBenchmark/README.md) — certificado, Firebird,
o que cada aba faz e como rodar. Leia aquele primeiro; este arquivo só existe
para você não procurar o servidor nesta pasta.

Os dois clientes falam com o **mesmo** `MsQuicServer`. Não se parecem por
acaso: os dois montam o frame pela mesma unit do RAL (`RALQuicFrame`), então o
servidor não sabe qual dos dois está do outro lado.

## O mínimo para rodar

1. Suba o `MsQuicServer` no micro (a pasta VCL).
2. Abra `KwikQuicClient.dproj`, plataforma **Android 64-bit**, e mande **Run**.
   Os cinco jars já estão em `KwikQuicClient/java/` e o `.dproj` já os declara
   — não precisa baixar nada.
3. Na aba **Conexao** do aplicativo, ponha o **IP do micro na rede** (não
   `localhost`, o telefone é outra máquina) e o **Pin** com a impressão digital
   do certificado, que é como se aceita um autoassinado alcançado por IP.

Precisa de **Android 8 (API 26)** ou mais novo. O Kwik é **LGPL v3**.
