/// Rotas do RAL 2.0: parametro tipado e com restricoes, opcional, curinga, grupo
/// com prefixo e eventos, versoes da API, o metodo QUERY e, onde o compilador
/// tem, rota com procedimento anonimo.
/// Guia: https://github.com/OpenSourceCommunityBrasil/PascalRAL/wiki/rotas-avancadas
unit Rotas.Exemplo;

{$IFDEF FPC}
  {$MODE DELPHI}
  {$IFNDEF VER3_2}{$IFNDEF VER3_0}
    {$MODESWITCH FUNCTIONREFERENCES}
    {$MODESWITCH ANONYMOUSFUNCTIONS}
  {$ENDIF}{$ENDIF}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  RALServer, RALRoutes, RALRequest, RALResponse, RALTypes, RALConsts,
  RALMIMETypes, RALParams, RALRoutesAnon;

type
  /// Cria as rotas do exemplo num servidor e responde a elas.
  TRotasExemplo = class
  private
    procedure Arquivo(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Busca(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ChecarChave(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ClientesV1(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ClientesV2(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Pedidos(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Produto(ARequest: TRALRequest; AResponse: TRALResponse);
  public
    /// Cria as rotas em AServer.
    procedure Montar(AServer: TRALServer);
  end;

implementation

procedure TRotasExemplo.Montar(AServer: TRALServer);
var
  vGrupo: TRALRouteGroup;
begin
  // o id tem de ser inteiro entre 1 e 9999: /produtos/abc nem chega aqui (404)
  AServer.CreateRoute('produtos/:id<int:range(1,9999)>', Produto).Allow([amGET]);

  // o status e opcional: /pedidos e /pedidos/abertos
  AServer.CreateRoute('pedidos/:status?', Pedidos).Allow([amGET]);

  // o curinga pega o resto do caminho: /arquivos/docs/manual.txt
  AServer.CreateRoute('arquivos/*caminho', Arquivo).Allow([amGET]);

  // um grupo: prefixo /admin e um evento antes de toda rota dele
  vGrupo := AServer.RouteGroups.AddGroup('admin', '/admin');
  vGrupo.Description.Text := 'Rotas administrativas';
  vGrupo.OnBeforeExecute := ChecarChave;
  AServer.CreateRoute('relatorio', Produto).InGroup('admin');

  // versoes: /v1/clientes e /v2/clientes, cada uma na sua rota
  AServer.ApiVersioning.Enabled := True;
  AServer.ApiVersioning.Default := '1';
  AServer.ApiVersioning.Deprecated.Text := '1';
  AServer.CreateRoute('clientes', ClientesV1).Versions := '1';
  AServer.CreateRoute('clientes', ClientesV2).Versions := '2';

  // QUERY: uma busca com corpo
  AServer.CreateRoute('busca', Busca).Allow([amQUERY]);

{$IF DECLARED(TRALOnReplyRef)}
  // o compilador tem metodos anonimos (Delphi, FPC 3.3.1)
  AServer.Get('/ping',
    procedure(ARequest: TRALRequest; AResponse: TRALResponse)
    begin
      AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
    end);
{$IFEND}
end;

procedure TRotasExemplo.Arquivo(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'arquivo: ' + ARequest.ParamByName('caminho').AsString,
    rctTEXTPLAIN);
end;

procedure TRotasExemplo.Busca(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'busca por: ' + ARequest.RequestText, rctTEXTPLAIN);
end;

procedure TRotasExemplo.ChecarChave(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vChave: TRALParam;
begin
  // um status 400 ou maior aqui encerra o pedido: a rota nao roda
  vChave := ARequest.Params.GetKind['X-Chave', rpkHEADER];
  if (vChave = nil) or (vChave.AsString <> 'segredo') then
    AResponse.Answer(403, 'chave errada', rctTEXTPLAIN);
end;

procedure TRotasExemplo.ClientesV1(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, '[{"nome":"Ana"}]', rctAPPLICATIONJSON);
end;

procedure TRotasExemplo.ClientesV2(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, '{"itens":[{"nome":"Ana"}],"total":1}', rctAPPLICATIONJSON);
end;

procedure TRotasExemplo.Pedidos(ARequest: TRALRequest; AResponse: TRALResponse);
var
  vStatus: TRALParam;
begin
  vStatus := ARequest.ParamByName('status');
  if vStatus = nil then
    AResponse.Answer(HTTP_OK, 'todos os pedidos', rctTEXTPLAIN)
  else
    AResponse.Answer(HTTP_OK, 'pedidos ' + vStatus.AsString, rctTEXTPLAIN);
end;

procedure TRotasExemplo.Produto(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'rota ' + ARequest.Query, rctTEXTPLAIN);
end;

end.
