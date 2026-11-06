{ An Apache 2.4 module over TRALWebBrokerServer (fcl-web's custapache24).
  httpd.conf:
    LoadModule ral_module /caminho/libralapacheexample.so
    <Location /ral>
      SetHandler ral-handler
    </Location>
  then http://localhost/ral/ping }
library ralapacheexample;

{$MODE OBJFPC}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, httpd24,
  RALTypes, RALConsts, RALMIMETypes, RALRequest, RALResponse, RALWebBrokerServer;

type
  TApp = class
    procedure Ping(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TApp.Ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

var
  ral_module: module; {$IFDEF UNIX}public name 'ral_module';{$ENDIF}
  gApp: TApp;
  gServer: TRALWebBrokerServer;

exports
  ral_module name 'ral_module';

begin
  gApp := TApp.Create;
  gServer := TRALWebBrokerServer.Create(nil);
  gServer.CreateRoute('ping', @gApp.Ping);
  gServer.Active := True;
  RALApacheStart(ral_module, 'ral_module', 'ral-handler');
end.
