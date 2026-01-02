unit Services.Usuario;

interface

uses
  System.SysUtils, System.JSON, Dm.Global, uMD5;

function Login(email, senha: string): TJsonObject;
function InserirUsuario(nome, email, senha: string): TJsonObject;
procedure EditarSenha(id_usuario: integer; senha: string);
function ListarUsuarioId(id_usuario: integer): TJSONObject;
procedure EditarUsuario(id_usuario: integer; nome, email: string);
function ListarUsuarioFone(whatsapp: string): TJSONObject;

implementation

function Login(email, senha: string): TJsonObject;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.Login(email, SaltPassword(senha));

  finally
    FreeAndNil(dm);
  end;
end;

function InserirUsuario(nome, email, senha: string): TJsonObject;
var
  dm: TDmGlobal;
  json_retorno: TJSONObject;
begin
  // Validar campos obrigatorios...
  if (nome = '') or (email = '') or (senha = '') then
    raise Exception.Create('Informe todos os campos: nome, email e senha');

  // Validar tamanho da senha...
  if (Length(senha) < 5) then
    raise Exception.Create('A senha deve ter pelo menos 5 caracteres');


  try
    dm := TDmGlobal.Create(nil);

    // Validar se email ja existe...
    json_retorno := dm.ListarUsuarioByEmail(email);

    if json_retorno.Count > 0 then
      raise Exception.Create('Já existe uma conta criada com esse e-mail');

    Result := dm.InserirUsuario(nome, email, SaltPassword(senha));

  finally
    FreeAndNil(json_retorno);
    FreeAndNil(dm);
  end;
end;

procedure EditarSenha(id_usuario: integer; senha: string);
var
  dm: TDmGlobal;
begin
  // Validar tamanho da senha...
  if (Length(senha) < 5) then
    raise Exception.Create('A senha deve ter pelo menos 5 caracteres');

  try
    dm := TDmGlobal.Create(nil);

    dm.EditarSenha(id_usuario, SaltPassword(senha));

  finally
    FreeAndNil(dm);
  end;
end;

function ListarUsuarioId(id_usuario: integer): TJSONObject;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.ListarUsuarioId(id_usuario);

  finally
    FreeAndNil(dm);
  end;
end;

procedure EditarUsuario(id_usuario: integer; nome, email: string);
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    dm.EditarUsuario(id_usuario, nome, email);

  finally
    FreeAndNil(dm);
  end;
end;

function ListarUsuarioFone(whatsapp: string): TJSONObject;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.ListarUsuarioFone(whatsapp);

  finally
    FreeAndNil(dm);
  end;
end;

end.

