unit Controllers.FormaPagto;

interface

uses RALServer, RALTypes, RALRequest, RALResponse, RALConsts, RALMIMETypes,
     System.SysUtils, System.JSON, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarFormaPagto(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('forma_pagto', ListarFormaPagto).AllowedMethods := [amGET];
end;


procedure ListarFormaPagto(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  valor: double;
begin
  Dm := TDm.Create(nil);

  try
    try
      valor := Req.ParamByName('valor').AsDouble / 100;

      Res.Answer(HTTP_OK, Dm.ListarFormaPagto(valor).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;


end.
