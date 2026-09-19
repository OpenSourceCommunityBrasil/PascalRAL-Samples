library module_sample;

{$mode objfpc}{$H+}

uses
  Classes,
  SysUtils,
  pascalral,
  Dialogs,
  Interfaces,
  RALServer,
  RALRequest,
  RALResponse
  { you can add units after this };

type
  TModuleTeste = class(TRALModuleRoutes)
  public
    constructor Create(AOwner: TComponent); override;
  protected
    procedure ping(ARequest : TRALRequest; AResponse : TRALResponse);
  end;

var
  ral_module : TModuleTeste;

function start_module(server : TRALServer): boolean; cdecl; export;
begin
  if ral_module = nil then
    ral_module := TModuleTeste.Create(nil);

  ral_module.Server := server;
  Result := True;
end;

function desc_module: string; cdecl; export;
begin
  Result := 'Teste de Modulo';
end;

procedure config_module; cdecl; export;
begin
  ShowMessage('Sem configurações');
end;

procedure stop_module; cdecl; export;
begin
  if ral_module = nil then
    Exit;

  ral_module.Server := nil;
  FreeAndNil(ral_module);
end;

exports
  start_module,
  desc_module,
  config_module,
  stop_module;

{ TModuleTeste }

constructor TModuleTeste.Create(AOwner: TComponent);
begin
  inherited;
  CreateRoute('/ping', @ping);
end;

procedure TModuleTeste.ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'pong', 'text/plain');
  AResponse.ContentDispositionInline := True;
end;

begin
  ral_module := nil;
end.
