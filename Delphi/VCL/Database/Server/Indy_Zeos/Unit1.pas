// by PascalRAL - StandAlone App: 10/09/2024 19:41:40
unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  ZDataset, ZConnection,

  RALCustomObjects, RALServer, RALConsts, RALIndyServer, RALRequest, RALResponse,
  RALMimeTypes, RALDBModule, RALDBStorage, RALDBStorageBIN, RALDBBase, RALDBZeos;

type
  TRALForm1 = class(TForm)
    server: TRALIndyServer;
    RALDBZeosLink1: TRALDBZeosLink;
    RALDBStorageBINLink1: TRALDBStorageBINLink;
    RALDBModule1: TRALDBModule;
    procedure FormCreate(Sender: TObject);
    procedure serverRoutes_pingReply(ARequest: TRALRequest;
                                     AResponse: TRALResponse);
  private
    { Private declarations }
    DBFILE: string;
    procedure StartDB;
  public
    { Public declarations }
  end;

var
  RALForm1: TRALForm1;

implementation

{$R *.dfm}

procedure TRALForm1.FormCreate(Sender: TObject);
begin
  DBFILE := ExtractFileDir(ParamStr(0)) + '\banco.db';
  StartDB;
  RALDBModule1.Database := DBFILE;
  server.Start;
end;

procedure TRALForm1.serverRoutes_pingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

procedure TRALForm1.StartDB;
var
  qryResult: TZQuery;
  conn: TZConnection;
begin
  conn := TZConnection.Create(nil);
  try
    conn.Protocol := 'sqlite';
    conn.Database := DBFILE;
    conn.LibraryLocation := ExtractFileDir(ParamStr(0)) + '\sqlite3.dll';
    qryResult := TZQuery.Create(nil);
    try
      qryResult.Connection := conn;
      qryResult.SQL.Text := 'PRAGMA table_info("clientes")';
      qryResult.Open;
      if qryResult.IsEmpty then
        conn.ExecuteDirect('CREATE TABLE clientes (codigo varchar(200), nome varchar(200))');
    finally
      qryResult.Free;
    end;
  finally
    conn.Free;
  end;
end;

end.
