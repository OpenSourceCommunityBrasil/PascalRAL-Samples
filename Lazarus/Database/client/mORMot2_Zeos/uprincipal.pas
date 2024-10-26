unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls,
  DBCtrls, DB, ZDataset, RALDBStorageBIN, RALDBZeosMemTable, RALDBConnection,
  RALSynopseClient;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button4: TButton;
    Button5: TButton;
    DBNavigator1: TDBNavigator;
    dsmem: TDataSource;
    DBGrid1: TDBGrid;
    conexao: TRALDBConnection;
    cliente: TRALSynopseClientMT;
    zral_mem: TRALDBZMemTable;
    storage_bin: TRALDBStorageBINLink;
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
  ral_mem.ApplyUpdates;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  ral_mem.Close;
  ral_mem.SQL.Clear;
  ral_mem.SQL.Add('select * from clientes');
  ral_mem.Open;
end;

end.
