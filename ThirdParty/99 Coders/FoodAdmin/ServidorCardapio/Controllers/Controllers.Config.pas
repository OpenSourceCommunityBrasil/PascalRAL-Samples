unit Controllers.Config;

interface

uses
  RALServer, RALRequest, RALResponse, RALTypes, RALConsts,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure ListarConfig(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('configs', ListarConfig).AllowedMethods := [amGET];
end;

procedure ListarConfig(Req: TRALRequest; Res: TRALResponse);
var
  dm: TDm;
begin
  try
    dm := TDm.Create(nil);

    Res.Answer(HTTP_OK, dm.ListarConfig.ToJSON);

  finally
    FreeAndNil(dm);
  end;
end;

end.
