unit udm;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite, FireDAC.Comp.UI, Data.DB,
  FireDAC.Comp.Client;

type
  Tdm = class(TDataModule)
    conexao: TFDConnection;
    wait: TFDGUIxWaitCursor;
    sqlite_link: TFDPhysSQLiteDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    procedure atualizaBD;
  public
    { Public declarations }
  end;

var
  dm: Tdm;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  uglobal_vars, ulib_bancodados;

procedure Tdm.atualizaBD;
var
  q1 : TFDQuery;
begin
  q1 := TFDQuery.Create(nil);
  try
    q1.Connection := conexao;

    if not TabelaExiste(q1, 'usuarios') then begin
      q1.Close;
      q1.SQL.Clear;
      q1.SQL.Add('create table usuarios(');
      q1.SQL.Add('codigo integer not null,');
      q1.SQL.Add('usuario varchar(50),');
      q1.SQL.Add('senha varchar(50),');
      q1.SQL.Add('ativo char(1) default ''S'',');
      q1.SQL.Add('constraint pk_usuarios primary key(codigo))');
      q1.ExecSQL;
    end;
  finally
    q1.Free;
  end;
end;

procedure Tdm.DataModuleCreate(Sender: TObject);
begin
  with conexao do begin
    Close;
    Params.Clear;
    Params.Add('DriverID=SQLite');
    Params.Add('Database='+gb_database);
    Params.Add('Server='+gb_hostname);
    Params.Add('LockingMode=Normal');
    Open;
  end;

  atualizaBD;
end;

end.
