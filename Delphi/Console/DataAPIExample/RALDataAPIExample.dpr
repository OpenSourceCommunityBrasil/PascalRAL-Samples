program RALDataAPIExample;

{$APPTYPE CONSOLE}

{$I PascalRAL.inc}

uses
  System.Classes, System.SysUtils,

  // Choose here the engine of the server
  RALIndyServer,
  //RALSynopseServer,

  // FireDAC, linked statically for SQLite
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Stan.Def,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.ConsoleUI.Wait,

  RALServer, RALTypes, RALDBBase, RALDBModule, RALDBFireDAC, RALDBCrudModule, RALSwaggerModule;

const
  cPorta = 8000;

// the DBWare module that holds the SQLite connection (driver, file, pool)
function AbrirBanco(const AArquivo: string): TRALDBModule;
begin
  Result := TRALDBModule.Create(nil);
  Result.DatabaseLink := 'FireDAC';
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
  FSwagger: TRALSwaggerModule;
  vCols: Integer;
  vI: Integer;
  vArquivo, vBase: string;
  vNovo: Boolean;
begin
  FServer := nil;
  FBanco := nil;
  FCrud := nil;
  FSwagger := nil;
  vArquivo := ExtractFilePath(ParamStr(0)) + 'produtos.db';
  vNovo := not FileExists(vArquivo);
  try
    FServer := TRALIndyServer.Create(nil);
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

    // code equivalent of the IDE verb "Read columns": fills Fields from the catalog
    vCols := FCrud.ReadColumns(FRecurso);
    WriteLn('Columns read of ', FRecurso.Route, ' (', vCols, '):');
    for vI := 0 to FRecurso.Fields.Count - 1 do
      WriteLn('  ', FRecurso.Fields[vI]);

    // read only, only the products under 10, only some columns
    FRecurso := FCrud.Resources.AddResource('/baratos', 'produtos');
    FRecurso.Operations := [roList, roGet];
    FRecurso.BaseFilter := 'preco < 10';
    FRecurso.Fields.CommaText := 'id,nome,preco';

    // Swagger UI and swagger.json, with the schemas of the resources
    FSwagger := TRALSwaggerModule.Create(nil);
    FSwagger.Server := FServer;

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
    WriteLn('  ', vBase, '/swagger/   (Swagger UI)');
    WriteLn;
    WriteLn('See the README.md for curl examples of every verb.');
    WriteLn('Press ENTER to finish');
    ReadLn;
  finally
    if FServer <> nil then
      FServer.Stop;
    FreeAndNil(FSwagger);
    FreeAndNil(FCrud);
    FreeAndNil(FBanco);
    FreeAndNil(FServer);
  end;
end.
