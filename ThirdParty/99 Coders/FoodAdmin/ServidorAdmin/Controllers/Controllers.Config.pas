unit Controllers.Config;

interface

uses
  RALRequest, RALResponse, RALServer, RALTypes, RALConsts, RALMIMETypes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure Listar(Req: TRALRequest; Res: TRALResponse);
procedure Editar(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('admin/config', Listar).AllowedMethods := [amGET];
  AServer.CreateRoute('admin/config', Editar).AllowedMethods := [amPUT];
end;

procedure Listar(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
begin
  try
    try
      DmGlobal := TDmGlobal.Create(nil);

      Res.Answer(HTTP_OK, DmGlobal.ListarConfig.ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure Editar(Req: TRALRequest; Res: TRALResponse);
var
  DmGlobal: TDmGlobal;
  body: TJSONObject;
  vl_entrega: double;
begin
  try
    try
      // PUT -> http://localhost:3000/admin/config
      // Body = {"vl_entrega": 10}

      DmGlobal := TDmGlobal.Create(nil);

      // Ler dados do corpo da requisicao...
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      vl_entrega := body.GetValue<double>('vl_entrega', 0);

      Res.Answer(HTTP_OK, DmGlobal.EditarConfig(vl_entrega).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

end.
