unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Data.DB,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,

  RALStorage, RALStorageBIN, RALDBConnection, RALDBFiredacMemTable, RALCustomObjects,
  RALClient, RALIndyClient, RALAuthentication,

  RALRequest, RALResponse, Vcl.ExtCtrls, Vcl.Buttons, Vcl.DBCtrls  ;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    RALClient: TRALClient;
    DataSource1: TDataSource;
    RALDBFDMemTable1: TRALDBFDMemTable;
    RALDBConnection1: TRALDBConnection;
    RALDBStorageBINLink1: TRALStorageBINLink;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    RALClientJWTAuth1: TRALClientJWTAuth;
    DBNavigator1: TDBNavigator;
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
var
  Contador: TStopwatch;
begin
  contador := TStopwatch.Create;
  RALDBFDMemTable1.Close;
  RALDBFDMemTable1.SQL.Clear;
  RALDBFDMemTable1.SQL.Add('select * from clientes');
  Contador.Start;
  RALDBFDMemTable1.Open;
  contador.Stop;
  Label1.Caption := contador.ElapsedMilliseconds.ToString + ' ms';
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  RALDBFDMemTable1.ApplyUpdates;
end;

end.
