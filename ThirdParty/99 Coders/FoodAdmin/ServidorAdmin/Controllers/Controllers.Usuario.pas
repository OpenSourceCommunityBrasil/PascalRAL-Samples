unit Controllers.Usuario;

interface

uses
  RALRequest, RALResponse, RALServer, RALTypes, RALConsts, RALMIMETypes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure Login(Req: TRALRequest; Res: TRALResponse);
procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
  AServer.CreateRoute('admin/usuarios/login', Login).AllowedMethods := [amPOST];
  AServer.CreateRoute('admin/usuarios', InserirUsuario).AllowedMethods := [amPOST];
end;

procedure Login(Req: TRALRequest; Res: TRALResponse);
var
  body, JSON: TJSONObject;
  email, senha: string;
  DmGlobal: TDmGlobal;
begin
  try
    try
      DmGlobal := TDmGlobal.Create(nil);

      body := TJSONObject.ParseJSONValue(Req.body.AsString) as TJSONObject;
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');

      JSON := DmGlobal.Login(email, senha);

      if (JSON.Size = 0) then
      begin
        Res.Answer(HTTP_Unauthorized, 'E-mail ou senha inválida...', rctTEXTPLAIN);
        FreeAndNil(JSON);
      end
      else
        Res.Answer(HTTP_OK, JSON.ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);
var
  body: TJSONObject;
  nome, email, senha: string;
  DmGlobal: TDmGlobal;
begin
  try
    try
      DmGlobal := TDmGlobal.Create(nil);

      body := TJSONObject.ParseJSONValue(Req.body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');

      Res.Answer(HTTP_Created, DmGlobal.InserirUsuario(nome, email, senha).ToJSON);

    except
      on ex: exception do
        Res.Answer(HTTP_InternalError, 'Erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(DmGlobal);
  end;
end;

end.
