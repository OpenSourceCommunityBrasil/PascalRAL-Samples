unit Controllers.Usuario;

interface

uses
  RALServer, RALRequest, RALResponse, RALTypes, RALConsts,
  System.JSON, System.SysUtils, DataModule.Global, uFunctions;

procedure RegistrarRotas(AServer: TRALServer);
procedure Login(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('usuarios/login', Login).AllowedMethods := [amPOST];
end;

procedure Login(Req: TRALRequest; Res: TRALResponse);
var
  dm: TDm;
  body: TJSONObject;
  fone: string;
begin
  try
    dm := TDm.Create(nil);
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    fone := body.getvalue<string>('fone', '');

    Res.Answer(HTTP_OK, dm.Login(SomenteNumero(fone)).ToJSON);

  finally
    FreeAndNil(dm);
  end;
end;

end.
