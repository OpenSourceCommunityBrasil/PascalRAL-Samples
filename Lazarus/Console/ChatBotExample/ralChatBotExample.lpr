program ralChatBotExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  {$IFDEF FPC}RALfpHTTPClient, RALfpHTTPServer,{$ELSE}RALnetHTTPClient, RALIndyServer,{$ENDIF}
  RALTypes, RALServer, RALChatMessage, RALChatChannel, RALChatBot, RALChatTelegram,
  RALChatWebhook, RALChatWhatsApp, RALChatMeta;

// A bot with PascalRAL (packages RALModuleChatPackage, RALModuleChatTelegramPackage and
// RALModuleChatMetaPackage) on up to three channels, each one used only when its
// environment variables are set (nothing is written in the source or to the screen):
//  - Telegram (TELEGRAM_TOKEN) receives by polling, so it needs no server;
//  - WhatsApp (WHATSAPP_TOKEN, WHATSAPP_APP_SECRET, WHATSAPP_VERIFY_TOKEN,
//    WHATSAPP_PHONE_ID) and Messenger (MESSENGER_TOKEN, MESSENGER_APP_SECRET,
//    MESSENGER_VERIFY_TOKEN, MESSENGER_PAGE_ID) receive by webhook: the program starts a
//    server on PORT (default 8080) that Meta must reach, so publish it with HTTPS
//    (a tunnel or a reverse proxy) and tell the address in PUBLIC_URL to print the
//    exact webhook URLs;
//  - WHATSAPP_TEMPLATE (default hello_world) and WHATSAPP_TEMPLATE_LANG (default
//    en_US) name the approved template that /template sends.
// The commands and behaviors below are the same on every channel:
//  - /start greets and offers two buttons; the button answers come to OnCallback;
//  - /time answers with the time of the computer;
//  - /template (WhatsApp) sends the approved template to this chat, the only kind of
//    message WhatsApp lets a business start outside the 24 hour window;
//  - any other text is echoed back with how many messages this chat has sent,
//    a value kept in the bot's session of the conversation;
//  - a picture is answered with its size.
// The token comes from the environment variable TELEGRAM_TOKEN: ask @BotFather in
// Telegram for one (/newbot). It is never written to the screen or to a log.

var
  GLock: TCriticalSection;

procedure Log(const AText: string);
begin
  GLock.Acquire;
  try
    WriteLn(AText);
    Flush(Output);
  finally
    GLock.Release;
  end;
end;

type
  TDemo = class
  public
    Bot: TRALChatBot;
    procedure Start(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage;
      var AHandled: Boolean);
    procedure Time(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage;
      var AHandled: Boolean);
    procedure Template(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage;
      var AHandled: Boolean);
    procedure Message(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage);
    procedure Callback(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage);
    procedure Error(Sender: TObject; AChannel: TRALChatChannel; const AText: string);
  end;

// the handlers run on the polling thread of the channel, not on the main thread

procedure TDemo.Start(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage;
  var AHandled: Boolean);
var
  vAnswer: TRALChatMessage;
begin
  vAnswer := TRALChatMessage.Create;
  try
    vAnswer.Text := 'Hello! I am a PascalRAL bot. Do you like Pascal?';
    vAnswer.AddButton('yes', 'Yes');
    vAnswer.AddButton('very', 'Very much');
    Bot.Reply(AMessage, vAnswer); // the bot copies it
  finally
    vAnswer.Free;
  end;
end;

procedure TDemo.Time(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage;
  var AHandled: Boolean);
begin
  Bot.Reply(AMessage, StringRAL('It is ' + FormatDateTime('hh:nn:ss', Now) + ' here.'));
end;

procedure TDemo.Template(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage;
  var AHandled: Boolean);
var
  vName, vLang: string;
  vTemplate: TRALChatMessage;
begin
  if not (AChannel is TRALChatWhatsApp) then
  begin
    Bot.Reply(AMessage, 'Templates exist only on WhatsApp.');
    Exit;
  end;
  vName := GetEnvironmentVariable('WHATSAPP_TEMPLATE');
  if vName = '' then
    vName := 'hello_world';
  vLang := GetEnvironmentVariable('WHATSAPP_TEMPLATE_LANG');
  if vLang = '' then
    vLang := 'en_US';
  // a template with variables takes them in the array, in order: ['Ana', '#123']
  vTemplate := TRALChatWhatsApp.TemplateMessage(AMessage.ChatId, StringRAL(vName),
    StringRAL(vLang), []);
  try
    Bot.Send(string(AMessage.ChannelName), vTemplate); // the bot copies it
  finally
    vTemplate.Free;
  end;
end;

procedure TDemo.Message(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage);
var
  vCount: Integer;
begin
  Log(Format('%s/%s: %s', [string(AMessage.ChannelName), string(AMessage.ChatId),
    string(AMessage.Text)]));
  case AMessage.Kind of
    ckText:
    begin
      vCount := StrToIntDef(string(Bot.Sessions.GetValue(AMessage.ChannelName,
        AMessage.ChatId, 'count')), 0) + 1;
      Bot.Sessions.SetValue(AMessage.ChannelName, AMessage.ChatId, 'count',
        StringRAL(IntToStr(vCount)));
      Bot.Reply(AMessage, StringRAL(Format('You said "%s" (message %d of this chat).',
        [string(AMessage.Text), vCount])));
    end;
    ckImage:
      Bot.Reply(AMessage, StringRAL(Format('A picture of %d bytes, thank you.',
        [AMessage.Media.Size])));
  else
    Bot.Reply(AMessage, 'I only understand text and pictures.');
  end;
end;

procedure TDemo.Callback(Sender: TObject; AChannel: TRALChatChannel; AMessage: TRALChatMessage);
begin
  if AMessage.CallbackData = 'very' then
    Bot.Reply(AMessage, 'Me too!')
  else
    Bot.Reply(AMessage, 'Good.');
end;

procedure TDemo.Error(Sender: TObject; AChannel: TRALChatChannel; const AText: string);
begin
  Log('error: ' + AText);
end;

function Env(const AName: string): StringRAL;
begin
  Result := StringRAL(GetEnvironmentVariable(AName));
end;

// the address Meta must call, from PUBLIC_URL or the local one
function BaseUrl(APort: Integer): string;
begin
  Result := GetEnvironmentVariable('PUBLIC_URL');
  if Result = '' then
    Result := 'http://localhost:' + IntToStr(APort);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

var
  FDemo: TDemo;
  FBot: TRALChatBot;
  FTelegram: TRALChatTelegram;
  FWhatsApp: TRALChatWhatsApp;
  FMessenger: TRALChatMeta;
  FServer: TRALServer;
  FModule: TRALChatWebhookModule;
  FCmd: TRALChatCommand;
  FReport: StringRAL;
  FPort: Integer;
  FWorking: Boolean;
begin
  FWorking := False;
  FTelegram := nil;
  FWhatsApp := nil;
  FMessenger := nil;
  FServer := nil;
  FModule := nil;
  GLock := TCriticalSection.Create;
  FDemo := TDemo.Create;
  FBot := TRALChatBot.Create(nil);
  try
    FDemo.Bot := FBot;
    FBot.OnMessage := FDemo.Message;
    FBot.OnCallback := FDemo.Callback;
    FBot.OnError := FDemo.Error;
    // the step of each conversation survives a restart of the program
    FBot.PersistFile := 'chatbot.sessions';

    FCmd := FBot.Commands.Add;
    FCmd.Name := 'start';
    FCmd.Match := cmmCommand;
    FCmd.Pattern := 'start';
    FCmd.OnExecute := FDemo.Start;
    FCmd := FBot.Commands.Add;
    FCmd.Name := 'time';
    FCmd.Match := cmmCommand;
    FCmd.Pattern := 'time';
    FCmd.OnExecute := FDemo.Time;
    FCmd := FBot.Commands.Add;
    FCmd.Name := 'template';
    FCmd.Match := cmmCommand;
    FCmd.Pattern := 'template';
    FCmd.OnExecute := FDemo.Template;

    // Telegram: polling
    if Env('TELEGRAM_TOKEN') = '' then
      Log('Telegram skipped: TELEGRAM_TOKEN is not set.')
    else
    begin
      FTelegram := TRALChatTelegram.Create(nil);
      FTelegram.TokenSource := tsEnvironment;
      FTelegram.TokenName := 'TELEGRAM_TOKEN';
      FTelegram.ReceiveMode := crmPolling;
      FTelegram.Bot := FBot;
      FBot.Channels.Add.Channel := FTelegram;
    end;

    // WhatsApp: webhook
    if (Env('WHATSAPP_TOKEN') = '') or (Env('WHATSAPP_APP_SECRET') = '') or
      (Env('WHATSAPP_VERIFY_TOKEN') = '') or (Env('WHATSAPP_PHONE_ID') = '') then
      Log('WhatsApp skipped: set WHATSAPP_TOKEN, WHATSAPP_APP_SECRET, ' +
        'WHATSAPP_VERIFY_TOKEN and WHATSAPP_PHONE_ID.')
    else
    begin
      FWhatsApp := TRALChatWhatsApp.Create(nil);
      FWhatsApp.TokenSource := tsEnvironment;
      FWhatsApp.TokenName := 'WHATSAPP_TOKEN';
      FWhatsApp.AppSecret := Env('WHATSAPP_APP_SECRET');
      FWhatsApp.VerifyToken := Env('WHATSAPP_VERIFY_TOKEN');
      FWhatsApp.PhoneNumberId := Env('WHATSAPP_PHONE_ID');
      FBot.Channels.Add.Channel := FWhatsApp;
    end;

    // Messenger (and Instagram messages): webhook
    if (Env('MESSENGER_TOKEN') = '') or (Env('MESSENGER_APP_SECRET') = '') or
      (Env('MESSENGER_VERIFY_TOKEN') = '') or (Env('MESSENGER_PAGE_ID') = '') then
      Log('Messenger skipped: set MESSENGER_TOKEN, MESSENGER_APP_SECRET, ' +
        'MESSENGER_VERIFY_TOKEN and MESSENGER_PAGE_ID.')
    else
    begin
      FMessenger := TRALChatMeta.Create(nil);
      FMessenger.TokenSource := tsEnvironment;
      FMessenger.TokenName := 'MESSENGER_TOKEN';
      FMessenger.AppSecret := Env('MESSENGER_APP_SECRET');
      FMessenger.VerifyToken := Env('MESSENGER_VERIFY_TOKEN');
      FMessenger.PageId := Env('MESSENGER_PAGE_ID');
      FBot.Channels.Add.Channel := FMessenger;
    end;

    if (FTelegram = nil) and (FWhatsApp = nil) and (FMessenger = nil) then
    begin
      WriteLn('No channel configured. Set TELEGRAM_TOKEN, or the WHATSAPP_* or the ' +
        'MESSENGER_* variables (see the README).');
      Exit;
    end;

    if FTelegram <> nil then
    begin
      if not FTelegram.TestToken(FReport) then
      begin
        WriteLn('Telegram refused the token: ', string(FReport));
        Exit;
      end;
      WriteLn(string(FReport));
      FTelegram.Active := True;
      FWorking := True;
    end;

    if (FWhatsApp <> nil) or (FMessenger <> nil) then
    begin
      FPort := StrToIntDef(GetEnvironmentVariable('PORT'), 8080);
      FServer := {$IFDEF FPC}TRALfpHttpServer{$ELSE}TRALIndyServer{$ENDIF}.Create(nil);
      FModule := TRALChatWebhookModule.Create(nil);
      FModule.Workers := 2;
      FModule.Bot := FBot;
      FModule.Server := FServer;
      FServer.Port := FPort;
      FServer.Active := True;
      FWorking := True;
      // in the Meta app (developers.facebook.com), Webhooks: the callback URL and the
      // verify token (the value of the variable); the signature is checked with the
      // App Secret, a request without a valid one is refused
      if FWhatsApp <> nil then
        Log('WhatsApp webhook URL: ' + BaseUrl(FPort) + '/' + string(FWhatsApp.ChannelName) +
          ' (object whatsapp_business_account, field messages)');
      if FMessenger <> nil then
        Log('Messenger webhook URL: ' + BaseUrl(FPort) + '/' + string(FMessenger.ChannelName) +
          ' (object page, fields messages, messaging_postbacks)');
    end;

    if FWorking then
    begin
      Log('Talk to the bot; press Enter here to stop.');
      ReadLn;
    end;
    if FServer <> nil then
      FServer.Active := False;
    if FTelegram <> nil then
      FTelegram.Active := False;
    FBot.Stop;
  finally
    FModule.Free;
    FServer.Free;
    FMessenger.Free;
    FWhatsApp.Free;
    FTelegram.Free;
    FBot.Free;
    FDemo.Free;
    GLock.Free;
  end;
end.
