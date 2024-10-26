unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls,
  RALDBStorage, RALDBStorageBIN, RALDBConnection, RALDBZeosMemTable, RALCustomObjects,
  RALClient, RALIndyClient, RALDBStorageJSON, RALTypes,
  ZMemTable, ZAbstractRODataset, ZAbstractDataset, ZDataset, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.DBCtrls;

type
  TCustomDBGrid = class(TDBGrid)
  published
    property DefaultColWidth;
    property DefaultRowHeight;
  end;

  TForm1 = class(TForm)
    RALIndyClientMT1: TRALIndyClientMT;
    RALDBConnection1: TRALDBConnection;
    RALDBStorageBINLink1: TRALDBStorageBINLink;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    RALDBStorageJSONLink1: TRALDBStorageJSONLink;
    Button1: TButton;
    Button2: TButton;
    DBNavigator1: TDBNavigator;
    RALDBZMemTable1: TRALDBZMemTable;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure RALDBZMemTable1AfterOpen(DataSet: TDataSet);
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
  RALDBZMemTable1.Close;
  RALDBZMemTable1.SQL.Text := 'select * from clientes';
  RALDBZMemTable1.Open;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  RALDBZMemTable1.ApplyUpdates;
end;

procedure TForm1.RALDBZMemTable1AfterOpen(DataSet: TDataSet);
begin
  RALDBZMemTable1.Append;
  TCustomDBGrid(DBGrid1).DefaultColWidth := 100;
end;

end.
