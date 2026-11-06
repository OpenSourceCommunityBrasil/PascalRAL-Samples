# RALServiceExample

Um servidor RAL 2.0 que roda como **servico do Windows**, **daemon do systemd** ou no
console, com o mesmo executavel:

```
RALServiceExample install     (Windows: como administrador; Linux: grava a unidade .service)
RALServiceExample console     (roda aqui ate Ctrl+C)
RALServiceExample uninstall
```

- `TRALServiceHost`: parar o servico (ou `systemctl stop`, ou Ctrl+C) chama
  `Shutdown`: o `/lento` em curso termina com 200 e quem chega depois recebe 503;
- `TRALConfig`: a porta vem de `servico.json`, de `RAL_SERVER__PORT` ou de
  `--Server.Port=8080`, nessa ordem de prioridade crescente;
- `TRALScheduler`: um job a cada 30 s, que comeca e para com o servidor;
- `TRALSystemLog`: as linhas do host vao para o Event Log ou para o syslog/journal.

No Linux: `sudo ./RALServiceExample install && sudo systemctl daemon-reload && sudo systemctl
start RALServico`; `systemctl reload RALServico` recarrega a configuracao.

Pacotes: `PascalRAL`, `IndyRAL` e `RALHostingPackage`.

Guias: [Servico e daemon](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/servico),
[Configuracao](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/configuracao).
