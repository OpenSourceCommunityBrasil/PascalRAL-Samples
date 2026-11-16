program RALGatewayExample;

// SCGI and uwsgi applications: nginx talks to the first on port 4000 and to the
// second on port 3031, a connection per request. The same routes on both.
// nginx:
//   location /scgi/ {
//     include scgi_params;
//     scgi_pass 127.0.0.1:4000;
//     scgi_buffering off;
//   }
//   location /uwsgi/ {
//     include uwsgi_params;
//     uwsgi_pass 127.0.0.1:3031;
//     uwsgi_buffering off;
//   }
// then http://localhost/scgi/ping and http://localhost/uwsgi/ping

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Classes, SysUtils,
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse,
  RALSCGIServer, RALUwsgiServer;

type
  TApp = class
    procedure Ping(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Relogio(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TApp.Ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong de ' + ARequest.ClientInfo.IP, rctTEXTPLAIN);
end;

{ a live stream: nginx sends each line as it comes (scgi_buffering off) }
procedure TApp.Relogio(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vInt: Integer;
begin
  for vInt := 1 to 5 do
  begin
    AResponse.SendEvent(FormatDateTime('hh:nn:ss', Now));
    Sleep(1000);
  end;
end;

var
  vScgi: TRALSCGIServer;
  vUwsgi: TRALUwsgiServer;
  vApp: TApp;
begin
  vScgi := TRALSCGIServer.Create(nil);
  vUwsgi := TRALUwsgiServer.Create(nil);
  vApp := TApp.Create;
  try
    // nginx passes the whole path: /scgi/ping reaches the route ping
    vScgi.PathBase := '/scgi';
    vScgi.Port := 4000;
    vScgi.CreateRoute('ping', vApp.Ping);
    vScgi.CreateRoute('relogio', vApp.Relogio);
    vUwsgi.PathBase := '/uwsgi';
    vUwsgi.Port := 3031;
    vUwsgi.CreateRoute('ping', vApp.Ping);
    vUwsgi.CreateRoute('relogio', vApp.Relogio);
    vScgi.Active := True;
    vUwsgi.Active := True;
    WriteLn('SCGI na porta 4000 (nginx: scgi_pass 127.0.0.1:4000)');
    WriteLn('uwsgi na porta 3031 (nginx: uwsgi_pass 127.0.0.1:3031)');
    WriteLn('Enter para terminar...');
    ReadLn;
    vScgi.Shutdown(10000);
    vUwsgi.Shutdown(10000);
  finally
    vApp.Free;
    vScgi.Free;
    vUwsgi.Free;
  end;
end.
