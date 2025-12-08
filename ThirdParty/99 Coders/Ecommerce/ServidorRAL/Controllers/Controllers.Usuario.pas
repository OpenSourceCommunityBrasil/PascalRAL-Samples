unit Controllers.Usuario;

interface

uses RALServer, RALTypes, RALRequest, RALResponse, RALConsts, RALMIMETypes,
     System.SysUtils,
     System.JSON,
     DataModule.Global;

procedure RegistrarRotas(AServer: TRALServer);
procedure Login(Req: TRALRequest; Res: TRALResponse);
procedure Registro(Req: TRALRequest; Res: TRALResponse);
procedure InserirFavorito(Req: TRALRequest; Res: TRALResponse);
procedure ExcluirFavorito(Req: TRALRequest; Res: TRALResponse);
procedure ListarUsuarioId(Req: TRALRequest; Res: TRALResponse);
procedure EditarUsuario(Req: TRALRequest; Res: TRALResponse);
procedure EditarSenha(Req: TRALRequest; Res: TRALResponse);
procedure ListarFavoritos(Req: TRALRequest; Res: TRALResponse);

procedure ListarEnderecos(Req: TRALRequest; Res: TRALResponse);
procedure ListarEnderecoId(Req: TRALRequest; Res: TRALResponse);
procedure InserirEndereco(Req: TRALRequest; Res: TRALResponse);
procedure EditarEndereco(Req: TRALRequest; Res: TRALResponse);
procedure ExcluirEndereco(Req: TRALRequest; Res: TRALResponse);

procedure ListarCartoes(Req: TRALRequest; Res: TRALResponse);
procedure InserirCartao(Req: TRALRequest; Res: TRALResponse);
procedure ExcluirCartao(Req: TRALRequest; Res: TRALResponse);

implementation

procedure RegistrarRotas(AServer: TRALServer);
begin
{
  As rotas aqui estão nesse formato para manter semelhança com o exemplo feito pelo
  Héber, repare que é preciso explicitar quais os métodos permitidos, pois normalmente
  todos os métodos são permitidos pelas rotas
}
  AServer.CreateRoute('usuarios/login', Login).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/registro', Registro).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/password', EditarSenha).AllowedMethods := [amPUT];
{
  A configuração de rota abaixo poderia facilmente ser substituída por apenas:
  AServer.CreateRoute('usuarios', metodounico).AllowedMethods := [amGET, amPUT];
  pois essa linha já garante que a rota responderá aos 2 verbos listados como permitidos
  sem a necessidade de separar as funções de resposta
}
  AServer.CreateRoute('usuarios', ListarUsuarioId).AllowedMethods := [amGET];
  AServer.CreateRoute('usuarios', EditarUsuario).AllowedMethods := [amPUT];

  // Favoritos...
  AServer.CreateRoute('usuarios/favoritos', ListarFavoritos).AllowedMethods := [amGET];
  AServer.CreateRoute('usuarios/favoritos', InserirFavorito).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/favoritos/:id_favorito', ExcluirFavorito)
    .AllowedMethods := [amDELETE];

  // Enderecos...
  AServer.CreateRoute('usuarios/enderecos', ListarEnderecos).AllowedMethods := [amGET];
  AServer.CreateRoute('usuarios/enderecos/:id_endereco', ListarEnderecoId)
    .AllowedMethods := [amGET];
  AServer.CreateRoute('usuarios/enderecos', InserirEndereco).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/enderecos/:id_endereco', EditarEndereco)
    .AllowedMethods := [amPUT];
  AServer.CreateRoute('usuarios/enderecos/:id_endereco', ExcluirEndereco)
    .AllowedMethods := [amDELETE];

  // Cartoes
  AServer.CreateRoute('usuarios/cartoes', ListarCartoes).AllowedMethods := [amGET];
  AServer.CreateRoute('usuarios/cartoes', InserirCartao).AllowedMethods := [amPOST];
  AServer.CreateRoute('usuarios/cartoes/:id_cartao', ExcluirCartao)
    .AllowedMethods := [amDELETE];
end;

procedure Login(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  email, senha: string;
  json, body: TJsonObject;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');

      json := Dm.Login(email, senha);

      if json.Count = 0 then
      begin
        // ambas as formas abaixo estão corretas, escolha a que for mais fácil
        //Res.Answer(401, 'E-mail ou senha inválida', rctTEXTPLAIN);
        Res.Answer(HTTP_Unauthorized, 'E-mail ou senha inválida', rctTEXTPLAIN);
        FreeAndNil(json);
      end
      else
      begin
        {
         o motor http não entende objetos, somente tipos primitivos.
         um res.Send<TJSONObject>(json) aqui iria internamente converter o "json"
         para uma string que seria adicionada ao corpo da resposta pra ser devolvida
         para o requerinte. Essa funcionalidade não existe no RAL, o código abaixo
         faz a mesma coisa de forma mais declarativa, sem converter implicitamente

         outro detalhe importante, o content-type padrão do RAL é 'application/json'
         por isso não foi necessário explicitar o content-type nesse método abaixo
        }
        Res.Answer(HTTP_OK, json.ToJSON);
      end;

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure Registro(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  nome, sobrenome, email, senha, cpf: string;
  body: TJsonObject;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      nome := body.GetValue<string>('nome', '');
      email := body.GetValue<string>('email', '');
      senha := body.GetValue<string>('senha', '');

      sobrenome := Copy(nome, Pos(' ', nome) + 1, 100);
      nome := Copy(nome, 1, Pos(' ', nome) - 1);
      cpf := '19119119100';

      Res.Answer(HTTP_Created, Dm.Registro(nome, sobrenome, email, senha, cpf).ToJSON);
    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure InserirFavorito(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario, id_produto: integer;
  body: TJsonObject;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      id_usuario := body.GetValue<integer>('id_usuario', 0);  //<<-- Vem do token JWT
      id_produto := body.GetValue<integer>('id_produto', 0);

      Res.Answer(HTTP_Created, Dm.InserirFavorito(id_usuario, id_produto).ToJSON);
    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ExcluirFavorito(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_favorito: integer;
begin
  Dm := TDm.Create(nil);

  try
    try
      id_favorito := Req.ParamByName('id_favorito').AsInteger;

      Res.Answer(HTTP_OK, Dm.ExcluirFavorito(id_favorito))
    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarUsuarioId(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarUsuarioId(id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure EditarUsuario(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
  body: TJSONObject;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;

      Dm.EditarUsuario(id_usuario,
                       body.GetValue<string>('nome', ''),
                       body.GetValue<string>('email', ''));

      Res.Answer(HTTP_OK, 'Success', rctTEXTPLAIN);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarFavoritos(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarFavoritos(id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure EditarSenha(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
  body, json: TJSONObject;
  email, senha_atual, nova_senha: string;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      senha_atual := body.GetValue<string>('senha_atual', '');
      nova_senha := body.GetValue<string>('nova_senha', '');
      email := body.GetValue<string>('email', '');


      // Valida senha atual...
      json := Dm.Login(email, senha_atual);

      if json.Count = 0 then
        raise Exception.Create('Senha atual incorreta')
      else
        Dm.EditarSenha(id_usuario, nova_senha);

      Res.Answer(HTTP_OK, 'Success', rctTEXTPLAIN);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarEnderecos(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarEnderecos(id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure InserirEndereco(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
  body: TJsonObject;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      id_usuario := body.GetValue<integer>('id_usuario', 0);  //<<-- Vem do token JWT

      Res.Answer(HTTP_OK,
                 Dm.InserirEndereco(id_usuario,
                                    body.GetValue<string>('tipo', ''),
                                    body.GetValue<string>('endereco', ''),
                                    body.GetValue<string>('numero', ''),
                                    body.GetValue<string>('complemento', ''),
                                    body.GetValue<string>('bairro', ''),
                                    body.GetValue<string>('cidade', ''),
                                    body.GetValue<string>('uf', ''),
                                    body.GetValue<string>('cep', '')).ToJSON);


    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure EditarEndereco(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario, id_endereco: integer;
  body: TJsonObject;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      id_usuario := body.GetValue<integer>('id_usuario', 0);  //<<-- Vem do token JWT
      id_endereco := Req.ParamByName('id_endereco').AsInteger;

      Dm.EditarEndereco(id_usuario, id_endereco,
                         body.GetValue<string>('tipo', ''),
                         body.GetValue<string>('endereco', ''),
                         body.GetValue<string>('numero', ''),
                         body.GetValue<string>('complemento', ''),
                         body.GetValue<string>('bairro', ''),
                         body.GetValue<string>('cidade', ''),
                         body.GetValue<string>('uf', ''),
                         body.GetValue<string>('cep', ''));

      Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ExcluirEndereco(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario, id_endereco: integer;
begin
  Dm := TDm.Create(nil);

  try
    try
      id_usuario := Req.ParamByName('id_usuario').AsInteger;  //<<-- Vem do token JWT
      id_endereco := Req.ParamByName('id_endereco').AsInteger;

      Dm.ExcluirEndereco(id_usuario, id_endereco);

      Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarEnderecoId(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario, id_endereco: integer;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger;
      id_endereco := Req.ParamByName('id_endereco').AsInteger;

      Res.Answer(HTTP_OK, Dm.ListarEnderecoId(id_usuario, id_endereco).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ListarCartoes(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
begin
  Dm := TDm.Create(nil);

  try
    try

      id_usuario := Req.ParamByName('id_usuario').AsInteger; // Pegar do token JWT....

      Res.Answer(HTTP_OK, Dm.ListarCartoes(id_usuario).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure InserirCartao(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario: integer;
  body: TJsonObject;
  numero, mes, ano, cod, nome, cpf: string;
begin
  Dm := TDm.Create(nil);

  try
    try
      body := TJSONObject.ParseJSONValue(Req.Body.AsString) as TJSONObject;
      id_usuario := body.GetValue<integer>('id_usuario', 0);  //<<-- Vem do token JWT
      numero := body.GetValue<string>('numero', '');
      mes := body.GetValue<string>('mes', '');
      ano := body.GetValue<string>('ano', '');
      cod := body.GetValue<string>('cod', '');
      nome := body.GetValue<string>('nome', '');
      cpf := '19119119100';

      Res.Answer(HTTP_Created, Dm.InserirCartao(id_usuario, numero, mes, ano,
                                             cod, nome, cpf).ToJSON);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

procedure ExcluirCartao(Req: TRALRequest; Res: TRALResponse);
var
  Dm: TDm;
  id_usuario, id_cartao: integer;
begin
  Dm := TDm.Create(nil);

  try
    try
      id_usuario := Req.ParamByName('id_usuario').AsInteger;  //<<-- Vem do token JWT
      id_cartao := Req.ParamByName('id_cartao').AsInteger;

      Dm.ExcluirCartao(id_usuario, id_cartao);

      Res.Answer(HTTP_OK, 'OK', rctTEXTPLAIN);

    except on ex:exception do
      Res.Answer(HTTP_InternalError, ex.message, rctTEXTPLAIN);
    end;

  finally
    FreeAndNil(Dm);
  end;
end;

end.
