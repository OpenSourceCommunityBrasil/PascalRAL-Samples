# ChatBotExample

Robô do Telegram em programa de console com o PascalRAL 2.0 (pacotes `RALModuleChatPackage` e `RALModuleChatTelegramPackage`). Recebe as mensagens perguntando ao Telegram (polling), então não precisa de servidor nem de endereço público.

## O que ele faz

1. **`/start`:** cumprimenta e mostra dois botões; a escolha chega em `OnCallback`.
2. **`/time`:** responde com a hora do computador.
3. **Texto:** devolve o que a pessoa escreveu e quantas mensagens aquela conversa já mandou, um valor guardado na sessão da conversa (`Sessions`), gravada em `chatbot.sessions` para sobreviver a um reinício.
4. **Foto:** responde com o tamanho da imagem.

## Como rodar

1. No Telegram, converse com **@BotFather**, mande `/newbot` e guarde o token que ele devolve.
2. Ponha o token na variável de ambiente `TELEGRAM_TOKEN` (o programa nunca o mostra nem grava).
3. Instale/compile `PascalRAL`, o motor de cliente (`NetHttpRAL` no Delphi, `fphttpral` no Lazarus, com a OpenSSL ao lado do executável no Windows), `RALModuleChatPackage` e `RALModuleChatTelegramPackage`, compile e execute.
4. Converse com o robô no Telegram; Enter no console encerra.

Para receber por webhook em vez de polling, veja a página [Chatbot no Telegram](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/chatbot-telegram) da wiki.
