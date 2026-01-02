unit Services.Lancamento;

interface

uses
  System.SysUtils, System.JSON, Dm.Global;

function Listar(id_usuario, id_categoria: integer;
                dt_de, dt_ate: string): TJsonArray;
function ListarId(id_usuario, id_lancamento: integer): TJsonObject;
function Inserir(id_usuario, id_categoria: integer;
                 descricao, tipo, dt_lancamento: string;
                 valor: double): TJSONObject;
procedure Editar(id_usuario, id_lancamento, id_categoria: integer;
                 descricao, tipo, dt_lancamento: string;
                 valor: double);
procedure Excluir(id_usuario, id_lancamento: integer);

implementation

function Listar(id_usuario, id_categoria: integer;
                dt_de, dt_ate: string): TJsonArray;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.ListarLancamentos(id_usuario, id_categoria, dt_de, dt_ate);

  finally
    FreeAndNil(dm);
  end;
end;

function ListarId(id_usuario, id_lancamento: integer): TJsonObject;
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    Result := dm.ListarLancamentoId(id_usuario, id_lancamento);

  finally
    FreeAndNil(dm);
  end;
end;

function Inserir(id_usuario, id_categoria: integer;
                 descricao, tipo, dt_lancamento: string;
                 valor: double): TJSONObject;
var
  dm: TDmGlobal;
begin
  if descricao = '' then
    raise Exception.Create('Informe a descrição do lançamento');

  if tipo = '' then
    raise Exception.Create('Informe o tipo do lançamento');

  if dt_lancamento = '' then
    dt_lancamento := FormatDateTime('yyyy-mm-dd', date);

  //if id_categoria <= 0 then
  //  raise Exception.Create('Informe a categoria do lançamento');

  try
    dm := TDmGlobal.Create(nil);

    Result := dm.InserirLancamento(id_usuario, id_categoria, descricao,
                                   tipo, dt_lancamento, valor);

  finally
    FreeAndNil(dm);
  end;
end;

procedure Editar(id_usuario, id_lancamento, id_categoria: integer;
                 descricao, tipo, dt_lancamento: string;
                 valor: double);
var
  dm: TDmGlobal;
begin
  if descricao = '' then
    raise Exception.Create('Informe a descrição do lançamento');

  if tipo = '' then
    raise Exception.Create('Informe o tipo do lançamento');

  if dt_lancamento = '' then
    raise Exception.Create('Informe a data do lançamento');

  if id_categoria <= 0 then
    raise Exception.Create('Informe a categoria do lançamento');

  try
    dm := TDmGlobal.Create(nil);

    dm.EditarLancamento(id_usuario, id_lancamento, id_categoria,
                        descricao, tipo, dt_lancamento, valor);

  finally
    FreeAndNil(dm);
  end;
end;

procedure Excluir(id_usuario, id_lancamento: integer);
var
  dm: TDmGlobal;
begin
  try
    dm := TDmGlobal.Create(nil);

    dm.ExcluirLancamento(id_usuario, id_lancamento);

  finally
    FreeAndNil(dm);
  end;
end;

end.

