unit Controllers.UsuarioMotorista;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes, RALRoutes,
  System.JSON, System.SysUtils, DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure LoginMotorista(Req: TRALRequest; Res: TRALResponse);
procedure InserirMotorista(Req: TRALRequest; Res: TRALResponse);
procedure StatusMotorista(Req: TRALRequest; Res: TRALResponse);
procedure ListarUsuario(Req: TRALRequest; Res: TRALResponse);
procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);


implementation

uses
  Controllers.JWT;

procedure RegistrarRotas(AServer: TRALServer);
var
  Rota: TRALRoute;
begin
{
  O código original atribui JWT nas rotas manualmente com o objeto do servidor
  sem nenhuma autenticação atribuída. No RAL, normalmente se atribui a autenticação
  no objeto do servidor e, se necessário, determina uma rota para ignorar
  autenticação com o SkipAuthMethods. Para não modificar muito o exemplo inicial,
  a mesma ideia foi preservada, por isso as rotas que não requerem autenticação,
  não possuem o SkipAuth. Mas entenda que se for utilizar autenticação no objeto
  do servidor, precisa definir o SkipAuth para os verbos que não deseja validar
  autenticação!

  Foi mantido comentado o SkipAuth abaixo para facilitar o entendimento de como
  seria a implementação.
}
  // Forma 1: Utilizando uma variável para modificar o conteúdo da rota
  Rota := AServer.CreateRoute('motoristas/login', LoginMotorista);
  Rota.AllowedMethods := [amPOST];
//  Rota.SkipAuthMethods := [amPOST]; // ignorar autenticação no verbo POST

  // Forma 2: Utilizando a estrutura with para escrever menos
  with AServer.CreateRoute('motoristas/cadastro', InserirMotorista) do
  begin
    AllowedMethods := [amPOST];
//    SkipAuthMethods := [amPOST];
  end;

  // Essa rota é a única do exemplo que recebe autenticação
  AServer.CreateRoute('motoristas/status', StatusMotorista).AllowedMethods := [amPUT];

{
  Aqui estamos usando a mesma variável da primeira rota, se caso precisássemos
  fazer algo com a primeira rota após esse ponto não tem como aproveitar a mesma
  variável por causa do ponteiro que mudou, como nesse caso específico desse exemplo
  não será necessário fazer nada com a primera rota "motoristas/login" após a
  definição inicial, estamos aproveitando a variável aqui. Tenha cuidado com essa
  forma de usar.
}
  Rota := AServer.CreateRoute('usuarios', ListarUsuario);
  Rota.AllowedMethods := [amGET];
//  Rota.SkipAuthMethods := [amGET];

  Rota := AServer.CreateRoute('usuarios', InserirUsuario);
  Rota.AllowedMethods := [amPOST];
//  Rota.SkipAuthMethods := [amPOST];
end;

procedure LoginMotorista(Req: TRALRequest; Res: TRALResponse);
var
  body, json: TJSONObject;
  email, senha: string;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');

      // Validar login...
      json := Dm.LoginMotorista(email, senha);

      if json.Count = 0 then
      begin
        Res.Answer(HTTP_Unauthorized, 'E-mail ou senha inválida', rctTEXTPLAIN);
        FreeAndNil(json);
      end
      else
      begin
        json.AddPair('token', Criar_Token(json.GetValue<integer>('id_motorista', 0)));
        Res.Answer(HTTP_OK, json.ToJSON);
      end;


    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure InserirMotorista(Req: TRALRequest; Res: TRALResponse);
var
  nome, email, senha, placa: string;
  body, json_retorno: TJsonObject;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');
      placa := body.GetValue<string>('placa', '');

      json_retorno := dm.InserirMotorista(nome, email, senha, placa);

      // Gerar um token JWT...
      json_retorno.AddPair('token',
                          Criar_Token(json_retorno.GetValue<integer>('id_motorista')));
      Res.Answer(HTTP_Created, json_retorno.ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure StatusMotorista(Req: TRALRequest; Res: TRALResponse);
var
  status: string;
  lat, long: double;
  id_motorista: integer;
  body: TJsonObject;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      id_motorista := Get_Usuario_Request(Req);

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      status := body.GetValue<string>('status', '');
      lat := body.GetValue<double>('latitude', 0);
      long := body.GetValue<double>('longitude', 0);

      Res.Answer(HTTP_OK, dm.StatusMotorista(id_motorista, status, lat, long).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure ListarUsuario(Req: TRALRequest; Res: TRALResponse);
var
  whatsapp: string;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      whatsapp := Req.ParamByName('whatsapp').AsString;

      Res.Answer(HTTP_OK, dm.ListarUsuario(whatsapp).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);
var
  nome, whatsapp: string;
  body: TJsonObject;
  dm: TDm;
begin
  dm := TDm.Create(nil);
  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      whatsapp := body.GetValue<string>('whatsapp', '');

      Res.Answer(HTTP_Created, dm.InserirUsuario(nome, whatsapp).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(dm);
  end;
end;

end.
