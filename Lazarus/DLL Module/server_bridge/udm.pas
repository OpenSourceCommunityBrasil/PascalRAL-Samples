unit udm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset;

type

  { Tdm }

  Tdm = class(TDataModule)
    conexao: TZConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    procedure atualizaBD;
  public

  end;

var
  dm: Tdm;

implementation

{$R *.lfm}

uses
  uglobal_vars;

{ Tdm }

procedure Tdm.DataModuleCreate(Sender: TObject);
begin
  with conexao do begin
    Disconnect;
    Protocol := 'SQLite';
    Database := gb_database;
    HostName := 'localhost';
    Connect;
  end;

  atualizaBD;
end;

procedure Tdm.atualizaBD;
var
  q1 : TZQuery;
  lst : TStringList;
begin
  lst := TStringList.Create;
  try
    conexao.GetTableNames('', lst);

    if lst.IndexOf('usuarios') < 0 then begin
      q1 := TZQuery.Create(nil);
      try
        q1.Connection := conexao;
        q1.Close;
        q1.SQL.Clear;
        q1.SQL.Add('create table usuarios(');
        q1.SQL.Add('codigo integer not null,');
        q1.SQL.Add('usuario varchar(50),');
        q1.SQL.Add('senha varchar(50),');
        q1.SQL.Add('ativo char(1) default ''S'',');
        q1.SQL.Add('constraint pk_usuarios primary key(codigo))');
        q1.ExecSQL;
      finally
        q1.Free;
      end;
    end;
  finally
    FreeAndNil(lst);
  end;
end;

end.

