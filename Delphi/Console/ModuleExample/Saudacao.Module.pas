/// Um modulo proprio do RAL 2.0: rotas, pedido e resposta do modulo, eventos
/// em volta de cada rota, erro proprio e o ciclo de vida do servidor.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/criar-modulo
unit Saudacao.Module;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALServer, RALRoutes, RALRequest, RALResponse, RALTypes, RALConsts,
  RALMIMETypes;

type
  /// A resposta do modulo: um Answer que so as rotas dele tem
  TSaudacaoResponse = class(TRALModuleResponse)
  public
    procedure Answer(const ANome: StringRAL; AVezes: Integer); overload;
  end;

  /// O handler das rotas do modulo, com a resposta do modulo
  TSaudacaoOnReply = procedure(ARequest: TRALModuleRequest;
    AResponse: TSaudacaoResponse) of object;

  /// A rota do modulo: um dado por rota e o handler tipado
  TSaudacaoRoute = class(TRALRoute)
  private
    FOnSaudacao: TSaudacaoOnReply;
    FVezes: Integer;
  public
    property OnSaudacao: TSaudacaoOnReply read FOnSaudacao write FOnSaudacao;
    property Vezes: Integer read FVezes write FVezes;
  end;

  /// O modulo: /ola/:nome e /falha com a resposta do modulo, /ping com a do nucleo
  TSaudacaoModule = class(TRALModuleRoutes)
  private
    procedure Falha(ARequest: TRALModuleRequest; AResponse: TSaudacaoResponse);
    procedure Ola(ARequest: TRALModuleRequest; AResponse: TSaudacaoResponse);
    procedure Ping(ARequest: TRALRequest; AResponse: TRALResponse);
  protected
    procedure ExecuteContext(ARoute: TRALRoute; ARequest: TRALModuleRequest;
      AResponse: TRALModuleResponse); override;
    function HandleException(ARequest: TRALRequest; AResponse: TRALResponse;
      AException: Exception): boolean; override;
    class function ResponseClass: TRALModuleResponseClass; override;
    class function RouteClass: TRALRouteClass; override;
    procedure ServerActivating; override;
    procedure ServerDeactivating; override;
  public
    constructor Create(AOwner: TComponent); override;

    procedure BeforeExecute(ARequest: TRALRequest; AResponse: TRALResponse); override;
    function DefaultContentType: StringRAL; override;
  end;

implementation

{ TSaudacaoResponse }

procedure TSaudacaoResponse.Answer(const ANome: StringRAL; AVezes: Integer);
var
  vTexto: StringRAL;
  vInt: Integer;
begin
  vTexto := '';
  for vInt := 1 to AVezes do
    vTexto := vTexto + 'ola ' + ANome + ' ';
  Answer(HTTP_OK, Trim(vTexto), rctTEXTPLAIN); // a sobrecarga herdada
end;

{ TSaudacaoModule }

constructor TSaudacaoModule.Create(AOwner: TComponent);
var
  vRota: TSaudacaoRoute;
begin
  inherited Create(AOwner);
  // NewRoute cria a rota da classe do modulo, sem handler: o modulo poe o dele
  vRota := TSaudacaoRoute(NewRoute('ola/:nome', 'Cumprimenta'));
  vRota.Vezes := 2;
  vRota.OnSaudacao := Ola;
  vRota.AllowedMethods := [amGET];

  vRota := TSaudacaoRoute(NewRoute('falha', 'Mostra o erro proprio do modulo'));
  vRota.OnSaudacao := Falha;

  // uma rota com o handler do nucleo convive com as do modulo
  CreateRoute('ping', Ping, 'Responde pong').AllowedMethods := [amGET];
end;

procedure TSaudacaoModule.BeforeExecute(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  inherited;
  // roda antes de toda rota do modulo, depois dos plugins
  AResponse.AddHeader('X-Modulo', 'saudacao');
end;

function TSaudacaoModule.DefaultContentType: StringRAL;
begin
  // o tipo das respostas que nao dizem outro (405, OPTIONS, Answer sem tipo)
  Result := rctTEXTPLAIN;
end;

procedure TSaudacaoModule.ExecuteContext(ARoute: TRALRoute;
  ARequest: TRALModuleRequest; AResponse: TRALModuleResponse);
begin
  if (ARoute is TSaudacaoRoute) and Assigned(TSaudacaoRoute(ARoute).OnSaudacao) then
    TSaudacaoRoute(ARoute).OnSaudacao(ARequest, TSaudacaoResponse(AResponse))
  else
    inherited; // sem handler: 404
end;

procedure TSaudacaoModule.Falha(ARequest: TRALModuleRequest;
  AResponse: TSaudacaoResponse);
begin
  raise Exception.Create('falha de proposito');
end;

function TSaudacaoModule.HandleException(ARequest: TRALRequest;
  AResponse: TRALResponse; AException: Exception): boolean;
begin
  // True: o modulo respondeu, e o servidor nao responde 500
  Result := True;
  AResponse.Answer(422, '{"erro":"' + StringRAL(AException.Message) + '"}',
    rctAPPLICATIONJSON);
end;

procedure TSaudacaoModule.Ola(ARequest: TRALModuleRequest;
  AResponse: TSaudacaoResponse);
begin
  AResponse.Answer(ARequest.ParamByName('nome').AsString,
    TSaudacaoRoute(ARequest.Route).Vezes);
end;

procedure TSaudacaoModule.Ping(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

class function TSaudacaoModule.ResponseClass: TRALModuleResponseClass;
begin
  Result := TSaudacaoResponse;
end;

class function TSaudacaoModule.RouteClass: TRALRouteClass;
begin
  Result := TSaudacaoRoute;
end;

procedure TSaudacaoModule.ServerActivating;
begin
  inherited;
  WriteLn('modulo: o servidor esta ligando');
end;

procedure TSaudacaoModule.ServerDeactivating;
begin
  inherited;
  WriteLn('modulo: o servidor esta desligando');
end;

end.
