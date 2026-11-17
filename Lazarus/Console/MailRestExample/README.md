# MailRestExample

Programa de console que manda e-mail por HTTP com o PascalRAL 2.0 (pacote `RALModuleMailPackage`). Servidor SMTP, cliente SMTP e servidor HTTP rodam no mesmo programa; ele fica no ar até o Enter.

## O que ele faz

1. Sobe um `TRALSMTPServer` na porta 2525 (sem TLS) que mostra cada mensagem que chega, para o exemplo rodar sem servidor de e-mail de verdade.
2. Aponta um `TRALSMTPClient` para ele (`Security := msNone`).
3. Liga um `TRALMailRestModule` ao servidor HTTP (porta 8000, Indy no Delphi e fpHTTP no Lazarus): `POST /mail/send` com JSON ou formulário (multipart/urlencoded) monta a mensagem e a envia pelo cliente. `DefaultFrom` é o autor padrão, `AllowedFrom` limita o `from` aceito e `OnBeforeSend` pode alterar ou recusar a mensagem.
4. A rota `POST /contact` usa um `TRALSendMail` criado em código: `Message` é o modelo, `OnPrepare` ajusta a cópia de cada envio e `Send` envia.

## Para experimentar

```
curl -X POST http://127.0.0.1:8000/mail/send -H "Content-Type: application/json" -d '{"to":"bob@example.com","subject":"Hello","text":"Hi Bob"}'
curl -X POST http://127.0.0.1:8000/mail/send -F to=bob@example.com -F subject=Report -F text=attached -F file=@report.csv
curl -X POST http://127.0.0.1:8000/contact -d "message=Please call me"
```

## Como rodar

Instale/compile `PascalRAL`, a engine (`IndyRAL` ou `fphttpral`), `RALNetPackage`, `RALHostingJobQueuePackage` e `RALModuleMailPackage`, compile o projeto e execute. No Lazarus, `RALMailActions` usa o `ActnList` da LCL (por isso o `Interfaces` e o pacote LCL).
