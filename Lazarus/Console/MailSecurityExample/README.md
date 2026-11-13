# MailSecurityExample

Programa de console que assina e cifra e-mail com o PascalRAL 2.0 (pacote `RALModuleMailPackage`), com S/MIME e com OpenPGP, sem OpenSSL nem GnuPG: a criptografia é do próprio RAL.

## O que ele faz

1. **S/MIME (`TRALSMIME`):** cria uma chave RSA de 2048 bits e um certificado para "Ana" (num uso real, o PFX de uma autoridade certificadora em `PFXFile`/`PFXPassword`), assina e cifra uma mensagem para ela mesma, grava em `smime.eml` e abre de volta, mostrando se veio cifrada, se a assinatura confere e se o certificado é confiável.
2. **OpenPGP (`TRALOpenPGP`):** cria uma chave Ed25519 com subchave Curve25519 para `ana@example.com` (num uso real, a chave exportada do GnuPG em `KeyFile`), assina e cifra (PGP/MIME) para os destinatários da mensagem, que o componente acha no chaveiro pelo e-mail, grava em `openpgp.eml` e abre de volta.

Os arquivos `.eml` podem ser enviados com `TRALSMTPClient.SendRaw` ou abertos num programa de e-mail que tenha a chave.

## Como rodar

Abra o `.lpi` com os pacotes `PascalRAL`, `RALNetPackage`, `RALCryptoCurvesPackage`, `RALHostingJobQueuePackage` e `RALModuleMailPackage` instalados no Lazarus, compile e execute (no Linux o programa já usa `cthreads`).
