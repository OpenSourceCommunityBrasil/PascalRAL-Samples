unit Controllers.Pedido;

interface

uses
  RALRequest, RALResponse, RALServer, RALTypes, RALConsts, RALMIMETypes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarPedidos(Req: TRALRequest; Res: TRALResponse);
procedure ListarPedidoById(Req: TRALRequest; Res: TRALResponse);
procedure EditarStatusPedido(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('admin/pedidos', ListarPedidos).AllowedMethods := [amGET];
  AServer.CreateRoute('admin/pedidos/:id_pedido', ListarPedidoById)
    .AllowedMethods:= [amGET];
  AServer.CreateRoute('admin/pedidos/:id_pedido/status', EditarStatusPedido)
    .AllowedMethods := [amPUT];
end;

procedure ListarPedidos(Req: TRALRequest; Res: TRALResponse);
var
  dt_de, dt_ate, status: string;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // Query Params...
      // http://localhost:3000/admin/pedidos?dt_de=2024-05-10&dt_ate=2024-05-10&status=A

      DmGlobal := TDmGlobal.Create(nil);

  {
  Não é necessário try .. except aqui, pois o RAL retorna o valor padrão do tipo
  se o parâmetro não existir, porém, se for necessário determinar se o parâmetro
  é nulo ou vazio, utilize a função isNilOrEmpty
  }
      dt_de := Req.ParamByName('dt_de').AsString;
      dt_ate := Req.ParamByName('dt_ate').AsString;
      status := Req.ParamByName('status').AsString;

      Res.Answer(HTTP_OK, DmGlobal.ListarPedidos(dt_de, dt_ate, status).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure ListarPedidoById(Req: TRALRequest; Res: TRALResponse);
var
  id_pedido: integer;
  DmGlobal: TDmGlobal;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/pedidos/123

      DmGlobal := TDmGlobal.Create(nil);

      id_pedido := Req.ParamByName('id_pedido').AsInteger;

      Res.Answer(HTTP_OK, DmGlobal.ListarPedidoById(id_pedido).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure EditarStatusPedido(Req: TRALRequest; Res: TRALResponse);
var
  id_pedido: integer;
  DmGlobal: TDmGlobal;
  body: TJSONObject;
  status: string;
begin
  try
    try
      // URL Params (URI Params)...
      // http://localhost:3000/admin/pedidos/123/status
      // Status: Corpoda requisicao
      // Body = {"status": "F"}

      DmGlobal := TDmGlobal.Create(nil);

      id_pedido := Req.ParamByName('id_pedido').AsInteger;

      // Ler dados do corpo da requisicao...
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      status := body.GetValue<string>('status', '');

      Res.Answer(HTTP_OK, DmGlobal.EditarStatusPedido(id_pedido, status).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

end.
