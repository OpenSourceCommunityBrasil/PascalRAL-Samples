# MailExample

Programa de console que envia e recebe e-mail com o PascalRAL 2.0 (pacote `RALModuleMailPackage`). Servidor, cliente e fila rodam no mesmo programa, que sai ao terminar.

## O que ele faz

1. Sobe um `TRALSMTPServer` na porta 2525 (só a porta comum, sem TLS) que aceita destinatários de `example.com`, recusa os outros com 550 e mostra cada mensagem que chega, conferindo a assinatura DKIM com um `TRALDKIMVerifier`.
2. Cria uma chave Ed25519 para o `TRALDKIMSigner` e mostra o registro TXT que iria no DNS (`q1._domainkey.example.com`).
3. Envia com um `TRALSMTPClient` uma mensagem com texto, HTML e um anexo CSV, assinada com DKIM, para um destinatário aceito e outro recusado, e mostra a resposta do servidor a cada um (`Results`).
4. Põe mais três mensagens num `TRALMailQueue`, que as envia em segundo plano; os eventos `OnDelivered`/`OnBounced` mostram o resultado.

## Com um provedor de verdade

No cliente, troque `Host`, `Port` e `Security` (`msStartTLS` na 587 ou `msImplicitTLS` na 465) e preencha `UserName` e `Password` (no Gmail, uma senha de app, ou `AccessToken` com OAuth2). Com TLS, a OpenSSL precisa estar ao lado do executável. Para o servidor aceitar TLS e login (portas 587 e 465), veja o comentário no fonte.

## Como rodar

Abra o `.lpi` com os pacotes `PascalRAL`, `RALNetPackage`, `RALCryptoCurvesPackage`, `RALHostingJobQueuePackage` e `RALModuleMailPackage` instalados no Lazarus, compile e execute (no Linux o programa já usa `cthreads`).
