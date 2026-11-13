program RALChatBotExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  {$IFDEF FPC}RALfpHTTPClient,{$ELSE}RALnetHTTPClient,{$ENDIF}
  RALTypes, RALChatMessage, RALChatChannel, RALChatBot, RALChatTelegram;

// A Telegram bot with PascalRAL (packages RALModuleChatPackage and
// RALModuleChatTelegramPackage), receiving by polling, so it needs no server:
//  - /start greets and offers two buttons; the button answers come to OnCallback;
//  - /time answers with the time of the computer;
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

var
  FDemo: TDemo;
  FBot: TRALChatBot;
  FTelegram: TRALChatTelegram;
  FCmd: TRALChatCommand;
  FReport: StringRAL;
begin
  if GetEnvironmentVariable('TELEGRAM_TOKEN') = '' then
  begin
    WriteLn('Set the environment variable TELEGRAM_TOKEN to the token @BotFather gave you.');
    Exit;
  end;
  GLock := TCriticalSection.Create;
  FDemo := TDemo.Create;
  FBot := TRALChatBot.Create(nil);
  FTelegram := TRALChatTelegram.Create(nil);
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

    FTelegram.TokenSource := tsEnvironment;
    FTelegram.TokenName := 'TELEGRAM_TOKEN';
    FTelegram.ReceiveMode := crmPolling;
    FTelegram.Bot := FBot;
    FBot.Channels.Add.Channel := FTelegram;

    if not FTelegram.TestToken(FReport) then
    begin
      WriteLn('Telegram refused the token: ', string(FReport));
      Exit;
    end;
    WriteLn(string(FReport));
    FTelegram.Active := True;
    Log('Talk to the bot in Telegram; press Enter here to stop.');
    ReadLn;
    FTelegram.Active := False;
    FBot.Stop;
  finally
    FTelegram.Free;
    FBot.Free;
    FDemo.Free;
    GLock.Free;
  end;
end.
