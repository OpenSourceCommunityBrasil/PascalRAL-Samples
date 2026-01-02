unit Services.Categoria;

interface

uses
  System.SysUtils, System.JSON, Dm.Global;

function Listar(id_usuario: integer): TJsonArray;
function ListarId(id_usuario, id_categoria: integer): TJsonObject;
function Inserir(id_usuario: integer; descricao: string): TJSONObject;
procedure Editar(id_usuario, id_categoria: integer; descricao: string);
procedure Excluir(id_usuario, id_categoria: integer);

implementation

function Listar(id_usuario: integer): TJsonArray;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.ListarCategorias(id_usuario);

  finally
    FreeAndNil(dm);
  end;
end;

function ListarId(id_usuario, id_categoria: integer): TJsonObject;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.ListarCategoriaId(id_usuario, id_categoria);

  finally
    FreeAndNil(dm);
  end;
end;

function Inserir(id_usuario: integer; descricao: string): TJSONObject;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.InserirCategoria(id_usuario, descricao);

  finally
    FreeAndNil(dm);
  end;
end;

procedure Editar(id_usuario, id_categoria: integer; descricao: string);
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    dm.EditarCategoria(id_usuario, id_categoria, descricao);

  finally
    FreeAndNil(dm);
  end;
end;

procedure Excluir(id_usuario, id_categoria: integer);
var
  dm: TDmGlobal;
  json_retorno: TJSONArray;
begin
  try
    dm := TDmGlobal.Create(nil);

    // Consultar se existe lancamentos antes de remover
    json_retorno := dm.ListarLancamentos(id_usuario, id_categoria, '', '');

    if json_retorno.Count > 0 then
      raise Exception.Create('A categoria não pode ser excluída porque possui lançamentos');

    dm.ExcluirCategoria(id_usuario, id_categoria);

  finally
    FreeAndNil(json_retorno);
    FreeAndNil(dm);
  end;
end;

end.

