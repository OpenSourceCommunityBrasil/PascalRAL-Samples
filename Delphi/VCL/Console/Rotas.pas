unit Rotas;

interface

uses
  SysUtils,
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts;

Type
  TRotas = class
  private
    procedure Console(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Default(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
  public
    procedure CreateRoute(AServer: TRALServer);
  end;

var
  Rota: TRotas;

implementation

{ TRotas }

procedure TRotas.Console(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'RALServer console mode', rctTEXTPLAIN);
end;

procedure TRotas.CreateRoute(AServer: TRALServer);
begin
  AServer.CreateRoute('console', Console);
  AServer.CreateRoute('teste', Default);
end;

procedure TRotas.Default(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, RALDefaultPage, rctTEXTHTML);
end;

end.
