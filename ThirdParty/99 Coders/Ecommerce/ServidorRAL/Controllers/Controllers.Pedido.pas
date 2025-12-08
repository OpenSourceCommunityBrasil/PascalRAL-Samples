unit Controllers.Pedido;

interface

uses RALServer, RALTypes, RALRequest, RALResponse, RALConsts, RALMIMETypes,
     System.SysUtils, System.JSON, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure InserirPedido(Req: TRALRequest; Res: TRALResponse);
procedure CalcularFrete(Req: TRALRequest; Res: TRALResponse);
procedure ListarPedidos(Req: TRALRequest; Res: TRALResponse);
procedure ListarPedidoId(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('pedidos', InserirPedido).AllowedMethods := [amPOST];
  AServer.CreateRoute('pedidos/frete', CalcularFrete).AllowedMethods := [amGET];
  AServer.CreateRoute('pedidos/:id_pedido', ListarPedidoId).AllowedMethods := [amGET];
  AServer.CreateRoute('pedidos', ListarPedidos).AllowedMethods := [amGET];
end;

procedure InserirPedido(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  body: TJSONObject;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;

      Res.Answer(HTTP_Created, Dm.InserirPedido(
                            body.GetValue<integer>('id_usuario', 0),
                            body.GetValue<double>('vl_frete', 0),
                            body.GetValue<double>('vl_subtotal', 0),
                            body.GetValue<double>('vl_total', 0),
                            body.GetValue<integer>('id_forma_pagto', 0),
                            body.GetValue<integer>('id_cartao', 0),
                            body.GetValue<integer>('num_parcela', 1),
                            body.GetValue<string>('cvv', ''),
                            body.GetValue<string>('endereco', ''),
                            body.GetValue<string>('numero', ''),
                            body.GetValue<string>('complemento', ''),
                            body.GetValue<string>('bairro', ''),
                            body.GetValue<string>('cidade', ''),
                            body.GetValue<string>('uf', ''),
                            body.GetValue<string>('cep', ''),
                            body.GetValue<TJsonArray>('itens')).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure CalcularFrete(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  qtd_itens: integer;
begin
  Dm := TDm.Create(nil);

  try
    try
      qtd_itens := Req.ParamByName('qtd').AsInteger;

      Res.Answer(HTTP_OK, Dm.CalcularFrete(qtd_itens).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarPedidos(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
begin
  Dm := TDm.Create(nil);

  try
    try
      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarPedidos(id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarPedidoId(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario, id_pedido: integer;
begin
  Dm := TDm.Create(nil);

  try
    try
      id_usuario := Req.ParamByName('id_usuario').AsInteger;
      id_pedido := Req.ParamByName('id_pedido').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarPedidoId(id_usuario, id_pedido).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;


end.
