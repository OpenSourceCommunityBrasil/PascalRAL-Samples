unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DB,
  ZConnection,
  RALSynopseServer, RALDBModule, RALDBStorageBIN, RALDBBufDataset, RALSwaggerModule,
  RALDBZeos, RALParams;

type

  { TForm1 }

  TForm1 = class(TForm)
    dbmodule: TRALDBModule;
    dbzeos: TRALDBZeosLink;
    server: TRALSynopseServer;
    swagger: TRALSwaggerModule;
    storage_bin: TRALDBStorageBINLink;
    ZConnection1: TZConnection;
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
  dbmodule.Database := DBFILE;
  ZConnection1.Database := DBFILE;
  CreateDefaultDB;
  server.Start;
end;

procedure TForm1.CreateDefaultDB;
var
  rows: integer;
begin
  ZConnection1.Connect;
  ZConnection1.ExecuteDirect('PRAGMA table_info("clientes")', rows);
  if rows = 0 then
    ZConnection1.ExecuteDirect('CREATE TABLE clientes (codigo varchar, nome varchar)');
  ZConnection1.Disconnect;
end;

end.
