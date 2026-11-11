program RALWebSocketExample;

{$APPTYPE CONSOLE}

{$I PascalRAL.inc}

uses
  System.Classes, System.SysUtils,

  // Choose here the engine of the server
  RALIndyServer,

  RALServer, RALRequest, RALResponse, RALTypes, RALConsts, RALJson, RALMIMETypes,
  RALWebSocket, RALWebSocketServer, RALWebSocketHub, RALWebSocketClient, RALWebSocketHubClient;

type
  TApp = class
  public
    // handlers run on server threads
    procedure Echo(AConnection: TRALWebSocketConnection; AMessage: TRALWebSocketMessage);
    procedure HubConnect(AHub: TRALHubModule; AConnection: TRALWebSocketConnection);
    procedure HubDisconnect(AHub: TRALHubModule; AConnection: TRALWebSocketConnection);
    procedure ChatSend(ACall: TRALHubCall);
    procedure Page(ARequest: TRALRequest; AResponse: TRALResponse);
    // of the embedded clients
    procedure HubEvent(ASender: TRALHubClient; const ATarget: StringRAL; AArgs: TRALJSONArray);
    procedure ClientMessage(ASender: TRALWebSocketClient; AMessage: TRALWebSocketMessage);
  end;

const
  PAGE_HTML =
    '<!DOCTYPE html><html><head><meta charset="utf-8"><title>RAL WebSocket</title></head><body>' +
    '<h3>RAL hub chat (room: lobby)</h3><div id="log"></div>' +
    '<input id="t" size="40" placeholder="type and press Enter">' +
    '<script src="/ralhub.js"></script><script>' +
    'var hub = new RalHub(''/chat'');' +
    'hub.on(''Chat.Message'', function(t){' +
    ' var d = document.createElement(''div''); d.textContent = t;' +
    ' document.getElementById(''log'').appendChild(d); });' +
    'hub.start().then(function(){ return hub.join(''lobby''); });' +
    'document.getElementById(''t'').addEventListener(''keydown'', function(e){' +
    ' if (e.key === ''Enter'' && this.value) {' +
    '  hub.invoke(''Chat.Send'', ''lobby'', this.value); this.value = ''''; } });' +
    '</script></body></html>';

procedure TApp.Echo(AConnection: TRALWebSocketConnection; AMessage: TRALWebSocketMessage);
begin
  AConnection.Send('echo: ' + AMessage.Text);
end;

procedure TApp.HubConnect(AHub: TRALHubModule; AConnection: TRALWebSocketConnection);
begin
  WriteLn('hub: connected ', string(AConnection.ID));
end;

procedure TApp.HubDisconnect(AHub: TRALHubModule; AConnection: TRALWebSocketConnection);
begin
  WriteLn('hub: disconnected ', string(AConnection.ID));
end;

procedure TApp.ChatSend(ACall: TRALHubCall);
begin
  // args: [room, text]
  ACall.Hub.EmitToGroup(ACall.ArgAsString(0), 'Chat.Message',
    '[' + RALHubQuote(ACall.ArgAsString(1)) + ']');
  ACall.ReturnJSON('true');
end;

procedure TApp.Page(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, PAGE_HTML, rctTEXTHTML);
end;

procedure TApp.HubEvent(ASender: TRALHubClient; const ATarget: StringRAL; AArgs: TRALJSONArray);
begin
  if AArgs <> nil then
    WriteLn('hub event: ', string(ATarget), ' ', string(AArgs.ToJSON))
  else
    WriteLn('hub event: ', string(ATarget));
end;

procedure TApp.ClientMessage(ASender: TRALWebSocketClient; AMessage: TRALWebSocketMessage);
begin
  WriteLn('echo client received: ', string(AMessage.Text));
end;

procedure RunDemo(AApp: TApp);
var
  vHub: TRALHubClient;
  vEcho: TRALWebSocketClient;
begin
  vHub := TRALHubClient.Create(nil);
  vEcho := TRALWebSocketClient.Create(nil);
  try
    vHub.URL := 'ws://127.0.0.1:8090/chat';
    vHub.OnHubEvent := {$IFDEF FPC}@{$ENDIF}AApp.HubEvent;
    vHub.Connect;
    vHub.JoinGroup('lobby');
    vHub.Invoke('Chat.Send', '["lobby","hello from Pascal"]');
    Sleep(500);

    vEcho.URL := 'ws://127.0.0.1:8090/ws/echo';
    vEcho.OnMessage := {$IFDEF FPC}@{$ENDIF}AApp.ClientMessage;
    vEcho.Connect;
    vEcho.Send('ping');
    Sleep(500);
    vEcho.Disconnect;
    vHub.Disconnect;
  finally
    FreeAndNil(vEcho);
    FreeAndNil(vHub);
  end;
end;

var
  FApp: TApp;
  FServer: TRALServer;
  FSockets: TRALWebSocketModule;
  FHub: TRALHubModule;
  FRoute: TRALWebSocketRoute;
begin
  FApp := TApp.Create;
  FServer := TRALIndyServer.Create(nil);
  FSockets := TRALWebSocketModule.Create(nil);
  FHub := TRALHubModule.Create(nil);
  try
    FSockets.Server := FServer;
    FSockets.Domain := '/ws';
    FRoute := FSockets.CreateWebSocketRoute('/echo', {$IFDEF FPC}@{$ENDIF}FApp.Echo);
    FRoute.Deflate := True;

    FHub.Server := FServer;
    FHub.Path := '/chat';
    FHub.ClientGroups := True;
    FHub.Methods.AddMethod('Chat.Send', {$IFDEF FPC}@{$ENDIF}FApp.ChatSend);
    FHub.OnConnect := {$IFDEF FPC}@{$ENDIF}FApp.HubConnect;
    FHub.OnDisconnect := {$IFDEF FPC}@{$ENDIF}FApp.HubDisconnect;

    FServer.CreateRoute('/', {$IFDEF FPC}@{$ENDIF}FApp.Page);
    FServer.Port := 8090;
    FServer.Start;
    WriteLn('RALServer running on Port ', FServer.Port, ', open http://localhost:8090/');

    if ParamStr(1) = '--demo' then
      RunDemo(FApp)
    else
    begin
      WriteLn('Press ENTER to finish');
      ReadLn;
    end;
  finally
    FServer.Stop;
    FreeAndNil(FHub);
    FreeAndNil(FSockets);
    FreeAndNil(FServer);
    FreeAndNil(FApp);
  end;
end.
