# CryptoCurvesExample

Programa de console que usa as curvas e a cifra autenticada do PascalRAL 2.0 (pacote `RALCryptoCurvesPackage`: `RALEd25519`, `RALCurve25519`, `RALHKDF`, `RALAESGCM`). Tudo é impresso em hexadecimal e o programa sai ao terminar.

## O que ele faz

1. **Ed25519**: gera o par de chaves, assina uma mensagem e verifica; depois mostra a verificação falhando com a mensagem alterada.
2. **X25519**: Alice e Bob geram pares, trocam as chaves públicas e chegam ao mesmo segredo.
3. **HKDF-SHA256**: deriva uma chave de 32 bytes desse segredo.
4. **AES-256-GCM**: cifra e decifra um texto (devolve cifrado + tag de 16 bytes) e mostra a tag recusando um cifrado ou um cabeçalho autenticado alterados.

## Como rodar

Instale/compile `PascalRAL` e `RALCryptoCurvesPackage`, compile `RALCryptoCurvesExample.dpr` e execute. O IV do GCM tem 12 bytes e nunca pode se repetir com a mesma chave.
