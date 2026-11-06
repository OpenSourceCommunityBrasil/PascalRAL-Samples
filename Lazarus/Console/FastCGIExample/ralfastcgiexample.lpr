program ralfastcgiexample;

// A FastCGI application: nginx (or Apache, or IIS) talks to it on port 9000.
// nginx:
//   location /api/ {
//     include fastcgi_params;
//     fastcgi_param REQUEST_URI $request_uri;
//     fastcgi_pass 127.0.0.1:9000;
//     fastcgi_keep_conn on;
//     fastcgi_buffering off;
//   }
// then http://localhost/api/ping

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse, RALFastCGIServer;

type
  TApp = class
    procedure Ping(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Relogio(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TApp.Ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong de ' + ARequest.ClientInfo.IP, rctTEXTPLAIN);
end;

{ a live stream: nginx sends each line as it comes (fastcgi_buffering off) }
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
  vServer: TRALFastCGIServer;
  vApp: TApp;
begin
  vServer := TRALFastCGIServer.Create(nil);
  vApp := TApp.Create;
  try
    vServer.Port := 9000;
    vServer.CreateRoute('api/ping', vApp.Ping);
    vServer.CreateRoute('api/relogio', vApp.Relogio);
    vServer.Active := True;
    WriteLn('FastCGI na porta 9000; nginx: fastcgi_pass 127.0.0.1:9000');
    WriteLn('Enter para terminar...');
    ReadLn;
    vServer.Shutdown(10000);
  finally
    vApp.Free;
    vServer.Free;
  end;
end.
