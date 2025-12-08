unit Controllers.Usuario;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes,
  System.SysUtils, System.JSON, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure Login(Req: TRALRequest; Res: TRALResponse);
procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
{
  Por padrão, o RAL permite todos os verbos na rota, para limitar a rota a responder
  apenas um ou alguns deles, utiliza-se a forma abaixo ou captura a rota antes e altera
  os AllowedMethods dela, por exemplo:
  var Rota: TRALRoute := AServer.CreateRoute(endpoint, método_resposta);
  Rota.AllowedMethods := [amGET, amPOST, amPUT...];

  O caminho da rota ou endpoint não precisa começar com '/', mas se criar rotas
  começando com '/', internamente o RAL corrige pro formato correto.
}
  AServer.CreateRoute('usuarios/login', Login).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/registro', InserirUsuario).AllowedMethods := [amPOST];
end;

procedure Login(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  body, json: TJSONObject;
  email, senha: string;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;

      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');

      json := Dm.Login(email, senha);

      if json.Size = 0 then
      begin
      {
        é uma boa prática definir o content-type como TextPlain se o resultado não for
        um texto JSON. Nesse exemplo aqui, ao invés de usar a constante, poderia usar
        diretamente a string 'text/plain' no Content-Type. Da mesma forma, ao invés de
        usar a constante HTTP_Unauthorized, poderia usar o inteiro 401.
      }
        Res.Answer(HTTP_Unauthorized, 'E-mail ou senha inválida', rctTEXTPLAIN);
        FreeAndNil(json);
      end
      else
      {
        O content-type padrão do RAL é 'application/json', por isso não foi
        explicitado aqui
      }
        Res.Answer(HTTP_OK, json.ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;

procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDmGlobal;
  body: TJSONObject;
  nome, email, senha, cidade: string;
begin
  Dm := TDmGlobal.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;

      nome := body.GetValue<string>('nome', '');
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');
      cidade := body.GetValue<string>('cidade', '');

      Res.Answer(HTTP_OK, Dm.InserirUsuario(nome, email, senha, cidade).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, 'Ocorreu um erro: ' + ex.Message, rctTEXTPLAIN);
    end;
  finally
    FreeAndNil(Dm);
  end;
end;


end.
