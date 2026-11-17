# ChatBotExample

Robô de chat em programa de console com o PascalRAL 2.0 (pacotes `RALModuleChatPackage`, `RALModuleChatTelegramPackage` e `RALModuleChatMetaPackage`). Fala em até três canais ao mesmo tempo: Telegram, WhatsApp (Cloud API) e Messenger. Cada canal só é ligado se as suas variáveis de ambiente estiverem definidas; senão o programa avisa que o pulou. Nenhum segredo fica no código nem aparece na tela.

## O que ele faz

1. **`/start`:** cumprimenta e mostra dois botões; a escolha chega em `OnCallback`.
2. **`/time`:** responde com a hora do computador.
3. **`/template`:** (WhatsApp) envia o template aprovado para a conversa com `TRALChatWhatsApp.TemplateMessage`, o único tipo de mensagem que o WhatsApp deixa a empresa iniciar fora da janela de 24 horas.
4. **Texto:** devolve o que a pessoa escreveu e quantas mensagens aquela conversa já mandou, um valor guardado na sessão da conversa (`Sessions`), gravada em `chatbot.sessions` para sobreviver a um reinício.
5. **Foto:** responde com o tamanho da imagem.

## Variáveis de ambiente

| Canal | Variáveis |
| --- | --- |
| Telegram (polling, sem servidor) | `TELEGRAM_TOKEN` |
| WhatsApp (webhook) | `WHATSAPP_TOKEN`, `WHATSAPP_APP_SECRET`, `WHATSAPP_VERIFY_TOKEN`, `WHATSAPP_PHONE_ID` |
| Messenger (webhook) | `MESSENGER_TOKEN`, `MESSENGER_APP_SECRET`, `MESSENGER_VERIFY_TOKEN`, `MESSENGER_PAGE_ID` |
| Servidor do webhook | `PORT` (padrão 8080), `PUBLIC_URL` (endereço público com HTTPS, só para imprimir as URLs) |
| `/template` | `WHATSAPP_TEMPLATE` (padrão `hello_world`), `WHATSAPP_TEMPLATE_LANG` (padrão `en_US`) |

## Como rodar

1. **Telegram:** no Telegram, converse com **@BotFather**, mande `/newbot` e ponha o token em `TELEGRAM_TOKEN`.
2. **WhatsApp:** no app da Meta (developers.facebook.com) com o produto WhatsApp: `WHATSAPP_TOKEN` é o token de acesso (o temporário serve para testar; em produção use o de um usuário do sistema), `WHATSAPP_PHONE_ID` é o *Phone number ID* (não o número), `WHATSAPP_APP_SECRET` vem de Configurações do app > Básico > Chave secreta do app, e `WHATSAPP_VERIFY_TOKEN` é um texto qualquer que você inventa.
3. **Messenger:** no mesmo tipo de app, com o produto Messenger: `MESSENGER_TOKEN` é o token de acesso da página, `MESSENGER_PAGE_ID` o id da página, `MESSENGER_APP_SECRET` a chave secreta do app e `MESSENGER_VERIFY_TOKEN` outro texto que você inventa.
4. Instale/compile `PascalRAL`, os motores (`NetHttpRAL` e `IndyRAL` no Delphi, `fpHTTPRAL` no Lazarus, com a OpenSSL ao lado do executável no Windows), `RALModuleChatPackage`, `RALModuleChatTelegramPackage` e `RALModuleChatMetaPackage`, compile e execute.
5. O programa mostra as URLs do webhook. A Meta só chama endereços públicos com HTTPS: use um túnel (ngrok, cloudflared) ou um proxy reverso para a `PORT` e defina `PUBLIC_URL` com o endereço dele.
6. No painel do app da Meta, em **Webhooks**: coloque a URL mostrada (`<PUBLIC_URL>/whatsapp` ou `<PUBLIC_URL>/meta`) em *Callback URL* e o valor do `..._VERIFY_TOKEN` em *Verify token*, e verifique (o programa responde ao desafio `hub.challenge`). Assine o campo `messages` no WhatsApp (objeto `whatsapp_business_account`) e `messages` e `messaging_postbacks` no Messenger (objeto `page`).
7. Todo pedido é conferido pela assinatura `X-Hub-Signature-256` com o App Secret; um sem assinatura válida é recusado.
8. Converse com o robô; Enter no console encerra. No WhatsApp de testes, o número que vai receber precisa estar na lista de destinatários do app, e fora da janela de 24 horas só o `/template` chega.

Para receber o Telegram por webhook em vez de polling, veja a página [Chatbot no Telegram](https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/chatbot-telegram) da wiki.
