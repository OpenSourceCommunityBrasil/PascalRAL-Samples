# DesfazerPreparacaoHttps

Devolve a máquina ao estado de antes das preparações de HTTPS/HTTP/2 do
`http.sys` — as que o botão **Preparar** do [`RALDemoHTTP2`](../) e do
[`Http2Benchmark`](../../Http2Benchmark/) fazem.

## Por que existe

Cada preparação cria um certificado autoassinado, o torna confiável, amarra na
porta com `netsh http add sslcert` e reserva a URL com `netsh http add urlacl`.
Rodada de novo — outra porta, outra versão do script, outro dia — ela **empilha**:
os certificados velhos continuam nas lojas `My` e `Root`, e a mesma porta acaba
com amarrações apontando para certificados diferentes (uma em `0.0.0.0`, outra em
`127.0.0.1`, outra por SNI).

O http.sys atende pela amarração **mais específica**, que pode não ser a que o
cliente espera. O sintoma é o pior tipo: o handshake fecha, mas com um
certificado que não é o do `pin.txt` da última preparação, e nada no erro diz
isso. Medido nesta máquina em 22/09/2026: 5 amarrações na porta 8443 apontando
para 3 certificados diferentes, e 6 certificados de `localhost` duplicados nas
duas lojas.

## Como usar

```powershell
.\DesfazerPreparacaoHttps.ps1                     # pergunta as portas, mostra e confirma
.\DesfazerPreparacaoHttps.ps1 -Listar             # só mostra o que encontrou
.\DesfazerPreparacaoHttps.ps1 -Portas 8443,9443   # sem perguntar as portas
.\DesfazerPreparacaoHttps.ps1 -Force              # apaga sem confirmar
```

Sem `-Portas` ele **pergunta** quais portas limpar — não existe porta padrão,
de propósito: limpar a porta errada apagaria a preparação de outro serviço.
Pede a elevação sozinho. Apaga, nesta ordem:

1. as amarrações de certificado — **por porta e por certificado**, o que também
   pega uma esquecida em outra porta;
2. as reservas de URL das portas;
3. os certificados **autoassinados** cujo titular é `CN=localhost` ou
   `CN=<nome da máquina>`, das lojas `LocalMachine\My` e `LocalMachine\Root`.

Não casa rótulo nenhum da saída do `netsh` (acha cada bloco pelo token de 40
hexadecimais da impressão digital), então funciona com o Windows em qualquer
idioma.

## Antes de confirmar

- Ele **lista tudo e pergunta** — leia a lista. Só toca em autoassinado com um
  daqueles dois titulares, nunca numa CA de verdade, mas se algum outro
  desenvolvimento seu usa um autoassinado de `localhost`, ele aparece ali.
- Ele leva junto os certificados de preparações **antigas**, inclusive as do
  `RALDemoHTTP2`. Depois de limpar, para voltar a usar o modo `http.sys` é só
  rodar o **Preparar** do servidor — e aí ele nasce com uma amarração só, que é
  o estado que não confunde ninguém.
