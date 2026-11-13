# MailboxServerExample

Programa de console com um pequeno servidor de e-mail feito com o PascalRAL 2.0 (pacote `RALModuleMailPackage`): recebe por SMTP, guarda em caixas postais e serve por IMAP, tudo no mesmo programa.

## O que ele faz

1. Sobe um `TRALSMTPServer` na porta 2525 que aceita destinatários de `example.com` e guarda cada mensagem na caixa de entrada do usuário (a parte antes do `@`), num `TRALMailStore` na pasta `mailboxes`.
2. Sobe um `TRALIMAPServer` na porta 1143 sobre o mesmo armazenamento, com o usuário `ana` e a senha `secret`.
3. Envia duas mensagens para `ana@example.com` com um `TRALSMTPClient`.
4. Lê a caixa com um `TRALIMAPClient`: quantas há, assunto e texto de cada uma; marca a primeira como lida e move a segunda para a pasta `Archive`.

As caixas ficam guardadas entre uma execução e outra (com os mesmos UIDs): rode duas vezes e veja as mensagens se acumularem. Qualquer programa de e-mail (Thunderbird, por exemplo) pode se conectar ao IMAP enquanto o programa roda, se você trocar o fim do programa por uma espera.

## Para usar de verdade

Sem TLS o exemplo roda sem OpenSSL; para uso real, preencha `SSL.CertFile`, `SSL.KeyFile` e `SSL.Enabled := True` nos dois servidores (as portas 465 e 993 abrem também), tire o `AllowPlainAuthWithoutTLS` e use TLS nos clientes. O `TRALPOP3Server` funciona do mesmo jeito que o IMAP.

## Como rodar

Abra o `.lpi` com os pacotes `PascalRAL`, `RALNetPackage`, `RALCryptoCurvesPackage`, `RALHostingJobQueuePackage` e `RALModuleMailPackage` instalados no Lazarus, compile e execute (no Linux o programa já usa `cthreads`).
