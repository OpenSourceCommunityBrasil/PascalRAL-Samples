unit Controllers.Usuario;

interface

uses
  RALServer, RALRequest, RALResponse, RALMIMETypes, RALConsts, RALTypes, RALRoutes,
  System.JSON, System.SysUtils, Services.Usuario,
  Controllers.JWT;

procedure RegistrarRotas(AServer: TRALServer);
procedure Login(Req: TRALRequest; Res: TRALResponse);
procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);
procedure EditarSenha(Req: TRALRequest; Res: TRALResponse);
procedure ListarUsuarioId(Req: TRALRequest; Res: TRALResponse);
procedure EditarUsuario(Req: TRALRequest; Res: TRALResponse);
procedure ListarUsuarioFone(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
{
  No exemplo original, a autenticação JWT é feita manualmente dentro das rotas, o
  objeto do servidor não possui uma autenticação anexada. Para manter a semelhança
  com o exemplo original, mantivemos a mesma estrutura aqui para reduzir as diferenças
  entre os exemplos.

  No RAL, normalmente se atribui uma autenticação no objeto do servidor e configura
  a validação da autenticação no método OnValidate desta. Porém, também é possível
  fazer a autenticação manualmente em cada rota independente da autenticação do
  servidor como este exemplo demonstra.
}
  // Rotas abertas
  AServer.CreateRoute('usuarios/login', Login).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/cadastro', InserirUsuario).AllowedMethods := [amPOST];

  // Rotas Protegidas
  AServer.CreateRoute('usuarios/password', EditarSenha).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios', ListarUsuarioId).AllowedMethods := [amGET];
  AServer.CreateRoute('usuarios', EditarUsuario).AllowedMethods := [amPUT];

  // Automação
  AServer.CreateRoute('usuarios/whatsapp/:numero', ListarUsuarioFone)
    .AllowedMethods := [amGET];
end;

procedure Login(Req: TRALRequest; Res: TRALResponse);
var
  email, senha: string;
  body, json_retorno: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    email := body.GetValue<string>('email', '');
    senha := body.GetValue<string>('senha', '');

    json_retorno := Services.Usuario.Login(email, senha);

    if json_retorno.Count = 0 then
    begin
      Res.Answer(HTTP_Unauthorized, 'E-mail ou senha inválida', rctTEXTPLAIN);
      FreeAndNil(json_retorno);
    end
    else
    begin
      // Gerar um token JWT...
      json_retorno.AddPair('token',
                        Criar_Token(json_retorno.GetValue<integer>('id_usuario')));
      Res.Answer(HTTP_OK, json_retorno.ToJSON);
    end;
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure InserirUsuario(Req: TRALRequest; Res: TRALResponse);
var
  nome, email, senha: string;
  body, json_retorno: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    nome := body.GetValue<string>('nome', '');
    email := body.GetValue<string>('email', '');
    senha := body.GetValue<string>('senha', '');

    json_retorno := Services.Usuario.InserirUsuario(nome, email, senha);

    // Gerar um token JWT...
    json_retorno.AddPair('token',
                        Criar_Token(json_retorno.GetValue<integer>('id_usuario')));
    Res.Answer(HTTP_Created, json_retorno.ToJSON);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure EditarSenha(Req: TRALRequest; Res: TRALResponse);
var
  senha: string;
  id_usuario: integer;
  body: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    senha := body.GetValue<string>('senha', '');

    id_usuario := Get_Usuario_Request(Req);

    Services.Usuario.EditarSenha(id_usuario, senha);
    Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure ListarUsuarioId(Req: TRALRequest; Res: TRALResponse);
var
  id_usuario: integer;
begin
  try
    id_usuario := Get_Usuario_Request(Req);
    Res.Answer(HTTP_OK, Services.Usuario.ListarUsuarioId(id_usuario).ToJSON);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure EditarUsuario(Req: TRALRequest; Res: TRALResponse);
var
  nome, email: string;
  id_usuario: integer;
  body: TJsonObject;
begin
  try
    body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
    nome := body.GetValue<string>('nome', '');
    email := body.GetValue<string>('email', '');

    id_usuario := Get_Usuario_Request(Req);

    Services.Usuario.EditarUsuario(id_usuario, nome, email);
    Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

procedure ListarUsuarioFone(Req: TRALRequest; Res: TRALResponse);
var
  whatsapp: string;
  json_retorno: TJsonObject;
begin
  try
    whatsapp := Req.ParamByName('numero').AsString;
    json_retorno := Services.Usuario.ListarUsuarioFone(whatsapp);
    if json_retorno.Count > 0 then
      json_retorno.AddPair('token',
                          Criar_Token(json_retorno.GetValue<integer>('id_usuario'),
                          1));
    Res.Answer(HTTP_OK, json_retorno.ToJSON);
  except on ex:exception do
    res.Answer(HTTP_InternalError, ex.Message, rctTEXTPLAIN);
  end;
end;

end.
