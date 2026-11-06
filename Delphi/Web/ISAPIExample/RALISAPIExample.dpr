{ An ISAPI extension for IIS over TRALWebBrokerServer: /ping answers pong,
  /echo?x=1 answers x and the body with the X-Test header back in X-Reply.
  In IIS: ISAPI and CGI Restrictions allow the DLL; a Handler Mapping
  (ISAPI-dll) runs it; http://localhost/ral/RALISAPIExample.dll/ping }
library RALISAPIExample;

uses
  Winapi.ActiveX, System.Win.ComObj, Web.WebBroker, Web.Win.ISAPIApp, Web.Win.ISAPIThreadPool,
  RALTypes, RALConsts, RALMIMETypes, RALRequest, RALResponse, RALWebBrokerServer;

type
  TApp = class
    procedure Ping(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Echo(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

procedure TApp.Echo(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.AddHeader('X-Reply', 'r-' + ARequest.GetHeader('X-Test'));
  AResponse.Answer(HTTP_OK, ARequest.GetQuery('x') + ' ' + ARequest.RequestText, rctTEXTPLAIN);
end;

procedure TApp.Ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

var
  gApp: TApp;
  gServer: TRALWebBrokerServer;

exports
  GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;

begin
  CoInitFlags := COINIT_MULTITHREADED;
  Application.Initialize;
  Application.WebModuleClass := TRALWebBrokerModule;
  gApp := TApp.Create;
  gServer := TRALWebBrokerServer.Create(nil);
  gServer.CreateRoute('ping', gApp.Ping);
  gServer.CreateRoute('echo', gApp.Echo);
  gServer.Active := True;
  Application.Run;
end.
