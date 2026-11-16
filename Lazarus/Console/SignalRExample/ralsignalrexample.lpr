program ralsignalrexample;

// A SignalR hub on RAL: the official clients (@microsoft/signalr in the browser
// or in Node, Microsoft.AspNetCore.SignalR.Client in .NET) connect to
// http://localhost:8095/chat. Open http://localhost:8095/ for a chat page that
// loads the official JavaScript client from a CDN.

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  {$IFDEF FPC}RALfpHTTPServer,{$ELSE}RALIndyServer,{$ENDIF}
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse, RALJson,
  RALWebSocketServer, RALWebSocketHub, RALSignalR;

const
  PAGE_HTML =
    '<!DOCTYPE html><html><head><meta charset="utf-8"><title>RAL SignalR</title></head><body>' +
    '<h3>Chat on a RAL SignalR hub</h3><div id="log"></div>' +
    '<input id="t" size="40" placeholder="type and press Enter">' +
    '<script src="https://cdn.jsdelivr.net/npm/@microsoft/signalr@8/dist/browser/signalr.min.js"></script>' +
    '<script>' +
    'const c = new signalR.HubConnectionBuilder().withUrl("/chat").withAutomaticReconnect().build();' +
    'c.on("ReceiveMessage", (u, m) => {' +
    ' const d = document.createElement("div"); d.textContent = u + ": " + m;' +
    ' document.getElementById("log").appendChild(d); });' +
    'c.start().then(() => c.invoke("Echo", "connected")).then(r => console.log(r));' +
    'document.getElementById("t").addEventListener("keydown", function (e) {' +
    ' if (e.key === "Enter" && this.value) { c.invoke("SendMessage", "web", this.value); this.value = ""; } });' +
    '</script></body></html>';

type
  TApp = class
  public
    Hub: TRALSignalRModule;
    procedure Page(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure SendMessage(ACall: TRALSignalRCall);
    procedure Echo(ACall: TRALSignalRCall);
    procedure Counter(ACall: TRALSignalRCall);
    procedure Connected(AModule: TRALSignalRModule; AConnection: TRALWebSocketConnection);
    procedure Disconnected(AModule: TRALSignalRModule; AConnection: TRALWebSocketConnection);
  end;

procedure TApp.Page(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, PAGE_HTML, rctTEXTHTML);
end;

{ connection.invoke("SendMessage", user, text): every client gets ReceiveMessage }
procedure TApp.SendMessage(ACall: TRALSignalRCall);
begin
  Hub.Send('ReceiveMessage', '[' + RALHubQuote(ACall.ArgAsString(0)) + ',' +
    RALHubQuote(ACall.ArgAsString(1)) + ']');
end;

{ connection.invoke("Echo", text) returns the text }
procedure TApp.Echo(ACall: TRALSignalRCall);
begin
  ACall.ReturnText('echo: ' + ACall.ArgAsString(0));
end;

{ connection.stream("Counter", n): n numbers, one every 200 ms }
procedure TApp.Counter(ACall: TRALSignalRCall);
var
  vInt: Integer;
begin
  for vInt := 1 to ACall.Arg(0).AsInteger do
  begin
    if not ACall.SendItem(StringRAL(IntToStr(vInt))) then
      Break;
    Sleep(200);
  end;
end;

procedure TApp.Connected(AModule: TRALSignalRModule; AConnection: TRALWebSocketConnection);
begin
  WriteLn('connected ', string(AConnection.ID));
end;

procedure TApp.Disconnected(AModule: TRALSignalRModule; AConnection: TRALWebSocketConnection);
begin
  WriteLn('disconnected ', string(AConnection.ID));
end;

var
  vApp: TApp;
  vServer: TRALServer;
begin
  vApp := TApp.Create;
  vServer := {$IFDEF FPC}TRALfpHttpServer{$ELSE}TRALIndyServer{$ENDIF}.Create(nil);
  vApp.Hub := TRALSignalRModule.Create(nil);
  try
    vApp.Hub.Path := '/chat';
    vApp.Hub.Methods.AddMethod('SendMessage', vApp.SendMessage);
    vApp.Hub.Methods.AddMethod('Echo', vApp.Echo);
    vApp.Hub.Methods.AddMethod('Counter', vApp.Counter);
    vApp.Hub.OnConnect := vApp.Connected;
    vApp.Hub.OnDisconnect := vApp.Disconnected;
    vApp.Hub.Server := vServer;
    vServer.CreateRoute('/', vApp.Page);
    vServer.Port := 8095;
    vServer.Active := True;
    WriteLn('SignalR hub at http://localhost:8095/chat; page at http://localhost:8095/');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Active := False;
  finally
    vApp.Hub.Free;
    vServer.Free;
    vApp.Free;
  end;
end.
