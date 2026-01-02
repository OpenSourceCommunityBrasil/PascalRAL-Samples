unit Controllers.Pedido;

interface

uses
  RALServer, RALRequest, RALResponse, RALTypes, RALConsts, RALMIMETypes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarPedidos(Req: TRALRequest; Res: TRALResponse);
procedure InserirPedido(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('pedidos', ListarPedidos).AllowedMethods := [amGET];
  AServer.CreateRoute('pedidos', InserirPedido).AllowedMethods := [amPOST];
end;

procedure ListarPedidos(Req: TRALRequest; Res: TRALResponse);
var
  dm: TDm;
  id_usuario: integer;
begin
  try
    dm := TDm.Create(nil);
    id_usuario := Req.ParamByName('id_usuario').AsInteger;

    Res.Answer(HTTP_OK, dm.ListarPedidos(id_usuario).ToJSON);
  finally
    FreeAndNil(dm);
  end;
end;

procedure InserirPedido(Req: TRALRequest; Res: TRALResponse);
var
  dm: TDm;
  body: TJSONObject;
  id_usuario: integer;
  endereco, fone: string;
  vl_subtotal, vl_entrega, vl_total: double;
  itens: TJSONArray;
begin
  try
    try
      dm := TDm.Create(nil);

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      id_usuario := body.GetValue<integer>('id_usuario', 0);
      endereco := body.GetValue<string>('endereco', '');
      fone := body.GetValue<string>('fone', '');
      vl_subtotal := body.GetValue<double>('vl_subtotal', 0);
      vl_entrega := body.GetValue<double>('vl_entrega', 0);
      vl_total := body.GetValue<double>('vl_total', 0);
      itens := body.GetValue<TJSONArray>('itens');

      Res.Answer(HTTP_Created, dm.InserirPedido(id_usuario, endereco, fone,
                                                vl_subtotal, vl_entrega,
                                                vl_total, itens).ToJSON);
    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

end.
