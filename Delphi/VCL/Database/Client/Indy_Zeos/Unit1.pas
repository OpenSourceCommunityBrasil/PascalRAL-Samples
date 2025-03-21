unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Diagnostics,

  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.DBCtrls,

  RALStorage, RALStorageBIN, RALDBConnection, RALDBZeosMemTable, RALCustomObjects,
  RALClient, RALIndyClient, RALStorageJSON, RALTypes, RALRequest, RALResponse,
  RALAuthentication,

  ZMemTable, ZAbstractRODataset, ZAbstractDataset, ZDataset;

type
  TCustomDBGrid = class(TDBGrid)
  published
    property DefaultColWidth;
    property DefaultRowHeight;
  end;

  TForm1 = class(TForm)
    RALClient: TRALClient;
    RALDBConnection1: TRALDBConnection;
    RALDBStorageBINLink1: TRALStorageBINLink;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    RALDBStorageJSONLink1: TRALStorageJSONLink;
    Button1: TButton;
    Button2: TButton;
    DBNavigator1: TDBNavigator;
    RALDBZMemTable1: TRALDBZMemTable;
    RALClientJWTAuth1: TRALClientJWTAuth;
    Label1: TLabel;
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
var
  Contador: TStopwatch;
begin
  Contador := TStopwatch.Create;
  RALDBZMemTable1.Close;
  RALDBZMemTable1.SQL.Text := 'select * from clientes';
  Contador.Start;
  RALDBZMemTable1.Open;
  Contador.Stop;
  Label1.Caption := Contador.ElapsedMilliseconds.ToString + ' ms';
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
