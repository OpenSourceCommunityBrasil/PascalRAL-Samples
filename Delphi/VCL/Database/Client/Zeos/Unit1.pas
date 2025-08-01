unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Diagnostics,

  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.DBCtrls,

  RALStorage, RALStorageBIN, RALDBConnection, RALDBZeosMemTable, RALCustomObjects,
  RALClient, RALStorageJSON, RALTypes, RALRequest, RALResponse, RALIndyClient,
  RALAuthentication,

  ZMemTable, ZAbstractRODataset, ZAbstractDataset, ZDataset,
  ZAbstractConnection, ZConnection;

type
  TCustomDBGrid = class(TDBGrid)
  published
    property DefaultColWidth;
    property DefaultRowHeight;
  end;

  TForm1 = class(TForm)
    RALDBConnection1: TRALDBConnection;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    Button1: TButton;
    Button2: TButton;
    DBNavigator1: TDBNavigator;
    RALDBZMemTable1: TRALDBZMemTable;
    RALClientJWTAuth1: TRALClientJWTAuth;
    Label1: TLabel;
    DBMemo1: TDBMemo;
    DBMemo2: TDBMemo;
    RALStorageBINLink1: TRALStorageBINLink;
    RALClient1: TRALClient;
    RALStorageJSONLink1: TRALStorageJSONLink;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure RALDBZMemTable1AfterOpen(DataSet: TDataSet);
    procedure FormCreate(Sender: TObject);
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  RALClient1.EngineType := 'Indy';
end;

procedure TForm1.RALDBZMemTable1AfterOpen(DataSet: TDataSet);
begin
  RALDBZMemTable1.Append;
  TCustomDBGrid(DBGrid1).DefaultColWidth := 100;
end;

end.
