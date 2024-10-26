unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DB, SQLite3Conn, SQLDB,
  BufDataset, RALSynopseServer, RALfpHTTPServer, RALIndyServer, RALDBModule,
  RALDBStorageBIN, RALDBBufDataset, RALDBSQLDB, RALSwaggerModule, RALParams;

type

  { TForm1 }

  TForm1 = class(TForm)
    dbmodule: TRALDBModule;
    server: TRALIndyServer;
    sqldb: TRALDBSQLDBLink;
    SQLite3Connection1: TSQLite3Connection;
    SQLTransaction1: TSQLTransaction;
    swagger: TRALSwaggerModule;
    storage_bin: TRALDBStorageBINLink;
    procedure FormCreate(Sender: TObject);
    procedure CreateDefaultDB;
  private

  public

  end;

var
  Form1: TForm1;
  DBFILE: string;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  DBFILE := ExtractFileDir(ParamStr(0)) + '\banco.db';
  server.Database := DBFILE;
  SQLite3Connection1.DatabaseName := DBFILE;
  CreateDefaultDB;
  server.Start;
end;

procedure TForm1.CreateDefaultDB;
var
  rows: integer;
begin
  SQLite3Connection1.Connected := true;
  SQLite3Connection1.ExecuteDirect('PRAGMA table_info("clientes")');
  if SQLite3Connection1.DataSets[0].IsEmpty then
    SQLite3Connection1.ExecuteDirect('CREATE TABLE clientes (codigo varchar, nome varchar)');
  SQLite3Connection1.Connected := false;
end;

end.
