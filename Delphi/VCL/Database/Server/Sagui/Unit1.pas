// by PascalRAL - StandAlone App: 10/09/2024 19:41:40
unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  FireDAC.Comp.Client,

  // Server and API Units
  RALServer, RALSaguiServer, RALRequest, RALResponse, RALAuthentication, RALToken,
  RALCustomObjects, RALStorageJSON, RALStorage, RALStorageBIN,

  // DBWare units
  RALDBModule, RALDBFireDAC,

  // General use units
  RALConsts, RALMimeTypes, RALTypes;

type
  TRALForm1 = class(TForm)
    JWTAuth: TRALServerJWTAuth;
    DBModule: TRALDBModule;
    StorageBIN: TRALStorageBINLink;
    StorageJSON: TRALStorageJSONLink;
    Server: TRALSaguiServer;
    procedure FormCreate(Sender: TObject);
    procedure serverRoutes_pingReply(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure RALServerJWTAuth1GetToken(ARequest: TRALRequest;
      AResponse: TRALResponse; AParams: TRALJWTParams; var AResult: Boolean);
  private
    { Private declarations }
    procedure StartDB;
  public
    { Public declarations }
  end;

var
  RALForm1: TRALForm1;
  DBFILE: string;

implementation

{$R *.dfm}

procedure TRALForm1.FormCreate(Sender: TObject);
begin
  DBFILE := ExtractFileDir(ParamStr(0)) + '\banco.db';
  StartDB;
  DBModule.Database := DBFILE;
  server.Start;
end;

procedure TRALForm1.RALServerJWTAuth1GetToken(ARequest: TRALRequest;
  AResponse: TRALResponse; AParams: TRALJWTParams; var AResult: Boolean);
begin
  AResult := true;
end;

procedure TRALForm1.serverRoutes_pingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, 'pong', rctTEXTPLAIN);
end;

procedure TRALForm1.StartDB;
var
  qryResult: TFDQuery;
  conn: TFDConnection;
begin
  conn := TFDConnection.Create(nil);
  try
    conn.DriverName := 'SQLite';
    conn.Params.Database := DBFILE;
    qryResult := TFDQuery.Create(nil);
    try
      qryResult.ResourceOptions.SilentMode := true;
      qryResult.Connection := conn;
      qryResult.sql.Text := 'PRAGMA table_info("clientes")';
      qryResult.OpenOrExecute;
      if qryResult.IsEmpty then
        qryResult.ExecSQL('CREATE TABLE clientes (codigo varchar, nome varchar, teste varchar, teste2 varchar)');
//
    finally
      qryResult.Free;
    end;
  finally
    conn.Free;
  end;
end;

end.
