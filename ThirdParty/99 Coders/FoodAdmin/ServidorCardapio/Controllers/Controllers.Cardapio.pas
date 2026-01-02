unit Controllers.Cardapio;

interface

uses
  RALServer, RALRequest, RALResponse, RALTypes, RALConsts,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarCardapios(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('cardapios', ListarCardapios).AllowedMethods := [amGET];
end;

procedure ListarCardapios(Req: TRALRequest; Res: TRALResponse);
var
  dm: TDm;
begin
  try
    dm := TDm.Create(nil);

    Res.Answer(HTTP_OK, dm.ListarCardapios.ToJSON);

  finally
    FreeAndNil(dm);
  end;
end;

end.
