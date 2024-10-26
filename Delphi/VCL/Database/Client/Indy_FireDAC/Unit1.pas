unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Data.DB,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,

  RALDBStorage, RALDBStorageBIN, RALDBConnection, RALDBFiredacMemTable, RALCustomObjects,
  RALClient, RALIndyClient;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    RALIndyClientMT1: TRALIndyClientMT;
    DataSource1: TDataSource;
    RALDBFDMemTable1: TRALDBFDMemTable;
    RALDBConnection1: TRALDBConnection;
    RALDBStorageBINLink1: TRALDBStorageBINLink;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  RALDBFDMemTable1.Close;
  RALDBFDMemTable1.SQL.Clear;
  RALDBFDMemTable1.SQL.Add('select * from clientes');
  RALDBFDMemTable1.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  RALDBFDMemTable1.ApplyUpdates;
end;

end.
