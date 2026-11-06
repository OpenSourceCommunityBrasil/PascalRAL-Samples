program ralinproctestexample;

{ An integration test without a port: the application's server runs in memory
  and a TRALClient reaches it through inproc://loja. Every plugin and module
  runs as over the network. The same works inside DUnitX, DUnit or fpcunit. }

{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALConsts, RALMIMETypes, RALServer, RALRequest, RALResponse, RALClient,
  RALInProc, RALAuthentication;

type
  { the application under test }
  TLoja = class
    procedure Produtos(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Validar(ARequest: TRALRequest; AResponse: TRALResponse; var AResult: boolean);
    procedure Montar(AServer: TRALServer);
  end;

procedure TLoja.Produtos(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, '[{"id":1,"nome":"Cafe"}]', rctAPPLICATIONJSON);
end;

procedure TLoja.Validar(ARequest: TRALRequest; AResponse: TRALResponse; var AResult: boolean);
begin
  AResult := (ARequest.Authorization.AsAuthBasic <> nil) and
    (ARequest.Authorization.AsAuthBasic.Password = 'segredo');
end;

procedure TLoja.Montar(AServer: TRALServer);
var
  vAuth: TRALServerBasicAuth;
begin
  AServer.CreateRoute('produtos', Produtos);
  vAuth := TRALServerBasicAuth.Create(AServer);
  vAuth.OnValidate := Validar;
  vAuth.Server := AServer;
end;

var
  gFalhas: Integer;

procedure Confere(ACondicao: boolean; const ANome: string);
begin
  if ACondicao then
    WriteLn('ok    ', ANome)
  else
  begin
    WriteLn('FALHA ', ANome);
    Inc(gFalhas);
  end;
end;

var
  vServer: TRALInProcServer;
  vClient: TRALClient;
  vResp: TRALResponse;
  vLoja: TLoja;
begin
  vServer := TRALInProcServer.Create(nil);
  vClient := TRALClient.Create(nil);
  vLoja := TLoja.Create;
  try
    vServer.ServerName := 'loja';
    vLoja.Montar(vServer);
    vServer.Active := True;
    vClient.EngineType := 'InProc';
    vClient.BaseURL.Text := 'inproc://loja';

    vResp := nil;
    vClient.Get('produtos', vResp);
    try
      Confere(vResp.StatusCode = 401, 'sem senha: 401');
    finally
      FreeAndNil(vResp);
    end;

    vClient.Authentication := TRALClientBasicAuth.Create(vClient);
    TRALClientBasicAuth(vClient.Authentication).UserName := 'ana';
    TRALClientBasicAuth(vClient.Authentication).Password := 'segredo';
    vClient.Get('produtos', vResp);
    try
      Confere(vResp.StatusCode = 200, 'com senha: 200');
      Confere(Pos('Cafe', string(vResp.ResponseText)) > 0, 'a lista veio');
    finally
      FreeAndNil(vResp);
    end;
  finally
    vLoja.Free;
    vClient.Free;
    vServer.Free;
  end;
  if gFalhas > 0 then
    ExitCode := 1;
end.
