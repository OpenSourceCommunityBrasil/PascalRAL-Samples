# RALProxy

Um balanceador de carga e proxy reverso no modelo do NGINX, feito com o RAL 2.0
(`RALModuleProxyPackage`: `TRALBalancer`, `TRALUpstream`, `TRALProxyConfig`).
O mesmo arquivo de configuração roda no Windows e no Linux.

## Arquivos

| arquivo | o quê |
|---|---|
| `RALProxy.dpr` (Delphi), `ralproxy.lpr` (Lazarus) | o programa de console |
| `RALProxyService.dpr` | o mesmo programa como serviço do Windows (só Delphi) |
| `RALProxy.App.pas` | o que os dois têm em comum: configuração, logs, recarga |
| `ralproxy.conf` | configuração de exemplo, comentada |
| `ralproxy.service` | unidade do systemd (Linux) |

Pacotes: `PascalRAL`, `RALNetPackage` e `RALModuleProxyPackage`. Nenhum motor
HTTP é necessário: o balanceador tem a sua própria escuta e as suas threads.
Para HTTPS (terminado aqui ou com os servidores de trás) a OpenSSL 1.1.1 ou
3.x precisa estar ao lado do programa ou no sistema.

## Uso

```
ralproxy -t -c ralproxy.conf     confere a configuração e sai (como nginx -t)
ralproxy -c ralproxy.conf        roda; Ctrl+C (ou SIGTERM) termina
```

Um erro na configuração diz o arquivo, a linha e a coluna:

```
ralproxy: ralproxy.conf:12:5: unknown directive "servr" in http
```

## Recarga sem cortar conexões

- **Linux:** `kill -HUP $(cat ralproxy.pid)` (ou `systemctl reload ralproxy`).
- **Windows:** salve o arquivo; ele é olhado a cada 2 segundos.

As portas que continuam ficam abertas e as conexões que já existem seguem
(o próximo pedido delas já usa as rotas novas); portas novas abrem, portas
retiradas fecham. Uma configuração com erro, ou com uma porta que não abre, é
recusada e a anterior continua rodando (o motivo vai para o `error_log`).

## Serviço do Windows

```
RALProxyService.exe /install     (como administrador)
sc start RALProxy
sc stop RALProxy
RALProxyService.exe /uninstall
```

O serviço lê o `ralproxy.conf` da pasta do executável.

## Daemon no Linux (systemd)

Veja os comandos no começo de `ralproxy.service`.

## O que a configuração aceita

A lista completa de diretivas, com exemplos, está na wiki:
https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/ralproxy
