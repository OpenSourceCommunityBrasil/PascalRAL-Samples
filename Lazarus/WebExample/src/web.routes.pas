unit Web.Routes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, System.IOUtils,
  RALWebModule, RALRequest, RALResponse, RALTypes;

procedure RegisterWebRoutes(AServer: TRALWebModule);

implementation

var
  DefaultDir: string;

procedure IndexReply(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(TPath.Combine(DefaultDir, 'index.html'));
end;

procedure LoginReply(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  if (ARequest.ParamByName('username').AsString = 'admin')
  and  (ARequest.ParamByName('password').AsString = 'admin') then
    AResponse.Answer(TPath.Combine(DefaultDir, 'main.html'))
  else
    AResponse.Answer(TPath.Combine(DefaultDir, 'index.html'));

end;

procedure RegisterWebRoutes(AServer: TRALWebModule);
begin
  // limiting the routes to GET and POST verbs, you could allow more verbs if needed
  AServer.CreateRoute('/', @IndexReply).AllowedMethods := [amGET, amPOST];
  AServer.CreateRoute('login', @LoginReply).AllowedMethods := [amGET, amPOST];

  DefaultDir := AServer.DocumentRoot + '/';
end;

end.

