unit uCGIModule;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, httpdefs, fpHTTP, fpWeb, RALCGIServerDatamodule,
  RALRoutes, RALResponse, RALRequest, RALAuthentication;

type

  { TCGIModule }

  TCGIModule = class(TRALWebModule)
    procedure DataModuleCreate(Sender : TObject);
    procedure hello(Sender : TObject; ARequest : TRALRequest; AResponse : TRALResponse);
  private

  public

  end;

var
  CGIModule : TCGIModule;

implementation

{$R *.lfm}

{ TCGIModule }

procedure TCGIModule.hello(Sender : TObject; ARequest : TRALRequest; AResponse : TRALResponse);
begin
  AResponse.ResponseText := 'RAL Hello';
end;

procedure TCGIModule.DataModuleCreate(Sender : TObject);
begin
  inherited;
  RALServer.CreateRoute('hello',@hello);
end;

initialization
  RegisterHTTPModule('TCGIModule', TCGIModule);

end.

