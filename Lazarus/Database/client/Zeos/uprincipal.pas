unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls,
  DBCtrls, DB, RALStorageBIN, RALStorageJSON, RALDBConnection,
  RALDBZeosMemTable, RALClient, RALAuthentication, RALfpHTTPClient,
  RALIndyClient, RALSynopseClient;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button4: TButton;
    Button5: TButton;
    DBMemo1: TDBMemo;
    DBMemo2: TDBMemo;
    DBNavigator1: TDBNavigator;
    dsmem: TDataSource;
    DBGrid1: TDBGrid;
    conexao: TRALDBConnection;
    cliente: TRALClient;
    Label1: TLabel;
    RALClientBasicAuth1: TRALClientBasicAuth;
    RALClientJWTAuth1: TRALClientJWTAuth;
    RALStorageJSONLink1: TRALStorageJSONLink;
    zral_mem: TRALDBZMemTable;
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button4Click(Sender: TObject);
begin
  zral_mem.ApplyUpdates;
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  tempo: int64;
begin
  zral_mem.Close;
  zral_mem.SQL.Clear;
  zral_mem.SQL.Add('select * from clientes');
  tempo := GetTickCount64;
  zral_mem.Open;
  tempo := GetTickCount64 - tempo;
  Label1.Caption := tempo.ToString;
end;

end.
