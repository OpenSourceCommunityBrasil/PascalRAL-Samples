program ralDataAPIExample;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  RALfpHTTPServer, RALServer, RALTypes, RALDBBase, RALDBModule, RALDBSQLDB,
  RALDBCrudModule;

const
  cPorta = 8000;

// the DBWare module that holds the SQLite connection (driver, file, pool)
function AbrirBanco(const AArquivo: string): TRALDBModule;
begin
  Result := TRALDBModule.Create(nil);
  Result.DatabaseLink := 'SQLDB';
  {$IFDEF LINUX}
  Result.LibLocation := '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0';
  {$ENDIF}
  Result.DatabaseType := dtSQLite;
  Result.Database := StringRAL(AArquivo);
end;

procedure Executar(AModulo: TRALDBModule; const ASQL: StringRAL);
var
  vBanco: TRALDBBase;
  vLinhas, vUltimo: Int64RAL;
begin
  vBanco := AModulo.AcquireDatabase(nil, nil);
  try
    vLinhas := 0;
    vUltimo := 0;
    vBanco.ExecSQL(ASQL, nil, vLinhas, vUltimo);
  finally
    AModulo.ReleaseDatabase(vBanco);
  end;
end;

// the sample table (with a version column) is created only when the file is new
procedure CriarBanco(AModulo: TRALDBModule);
begin
  Executar(AModulo, 'create table produtos (id integer primary key, nome varchar(60) not null, ' +
    'preco numeric(10,2), estoque integer, versao integer default 1)');
  Executar(AModulo, 'insert into produtos (nome, preco, estoque) values ' +
    '(''Caneta'', 2.50, 100), (''Caderno'', 15.90, 40), (''Borracha'', 1.20, 250), ' +
    '(''Mochila'', 89.00, 12), (''Lapis'', 0.90, 500), (''Agenda'', 32.00, 25)');
end;

var
  FServer: TRALServer;
  FBanco: TRALDBModule;
  FCrud: TRALDBCrudModule;
  FRecurso: TRALDBCrudResource;
  vArquivo, vBase: string;
  vNovo: Boolean;
begin
  FServer := nil;
  FBanco := nil;
  FCrud := nil;
  vArquivo := ExtractFilePath(ParamStr(0)) + 'produtos.db';
  vNovo := not FileExists(vArquivo);
  try
    FServer := TRALfpHttpServer.Create(nil);
    FBanco := AbrirBanco(vArquivo);
    if vNovo then
      CriarBanco(FBanco);

    FCrud := TRALDBCrudModule.Create(nil);
    FCrud.DBModule := FBanco;
    FCrud.TotalCount := True;   // lists answer X-Total-Count

    // all verbs; versao grows on every write and is the ETag
    FRecurso := FCrud.Resources.AddResource('/produtos', 'produtos');
    FRecurso.VersionField := 'versao';
    FRecurso.DefaultSort := 'nome';

    // read only, only the products under 10, only some columns
    FRecurso := FCrud.Resources.AddResource('/baratos', 'produtos');
    FRecurso.Operations := [roList, roGet];
    FRecurso.BaseFilter := 'preco < 10';
    FRecurso.Fields.CommaText := 'id,nome,preco';

    FCrud.Server := FServer;
    FServer.Port := cPorta;
    FServer.Start;

    vBase := 'http://127.0.0.1:' + IntToStr(cPorta);
    WriteLn('RALServer running on Port ', cPorta, ', database ', vArquivo);
    WriteLn;
    WriteLn('  ', vBase, '/produtos');
    WriteLn('  ', vBase, '/produtos/1');
    WriteLn('  ', vBase, '/produtos?preco_gt=10&_sort=-preco');
    WriteLn('  ', vBase, '/produtos?nome_cont=a&_fields=id,nome&_limit=3');
    WriteLn('  ', vBase, '/produtos?rql=and(gt(preco,10),lt(estoque,100))');
    WriteLn('  ', vBase, '/baratos');
    WriteLn;
    WriteLn('See the README.md for curl examples of every verb.');
    WriteLn('Press ENTER to finish');
    ReadLn;
  finally
    if FServer <> nil then
      FServer.Stop;
    FreeAndNil(FCrud);
    FreeAndNil(FBanco);
    FreeAndNil(FServer);
  end;
end.
