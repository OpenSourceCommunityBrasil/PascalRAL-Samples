unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls,
  ZDataset, RALDBBufDataset, RALDBStorageBIN, RALDBZeosMemTable,
  RALDBConnection, DB, SQLDB, RALIndyClient;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    dsmem: TDataSource;
    DBGrid1: TDBGrid;
    indy_cliente: TRALIndyClientMT;
    conexao: TRALDBConnection;
    zral_mem: TRALDBZMemTable;
    ral_mem: TRALDBBufDataset;
    storage_bin: TRALDBStorageBINLink;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  ral_mem.Close;
  ral_mem.SQL.Clear;
  ral_mem.SQL.Add('select * from clientes');
  ral_mem.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ral_mem.Close;
  ral_mem.SQL.Clear;
  ral_mem.SQL.Add('insert into clientes(codigo, nome)');
  ral_mem.SQL.Add('values(:codigo,:nome)');
  ral_mem.ParamByName('codigo').AsInteger := 4;
  ral_mem.ParamByName('nome').AsString := 'TESTE';
  ral_mem.ExecSQL;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  ral_mem.Close;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  ral_mem.ApplyUpdates;
end;

end.

