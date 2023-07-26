unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.WinXCtrls,
  RALServer, RALRoutes, RALRequest, RALResponse, RALParams, RALIndyServer,
  RALTypes, RALAuthentication, RALConsts, Vcl.ComCtrls;

type
  TfPrincipal = class(TForm)
    ToggleSwitch1: TToggleSwitch;
    RALBasicAuth: TRALServerBasicAuth;
    Server: TRALIndyServer;
    Memo2: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    ListView1: TListView;
    lServerPath: TLabel;
    procedure poolerrclientesReply(Sender: TObject; ARequest: TRALRequest;
      var AResponse: TRALResponse);
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure ping(Sender: TObject; ARequest: TRALRequest;
      var AResponse: TRALResponse);
    procedure test(Sender: TObject; ARequest: TRALRequest;
      var AResponse: TRALResponse);
    procedure FormCreate(Sender: TObject);
    procedure Log(Sender: TObject; ARequest: TRALRequest;
      var AResponse: TRALResponse);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$R *.dfm}

procedure TfPrincipal.poolerrclientesReply(Sender: TObject;
  ARequest: TRALRequest; var AResponse: TRALResponse);
var
  nome: string;
  vParam: TRALParam;
begin
  nome := 'erro';
  vParam := ARequest.Params.ParamName['nome'];
  if vParam <> nil then
    nome := vParam.AsString;

  AResponse.ResponseText := nome;
end;

procedure TfPrincipal.test(Sender: TObject; ARequest: TRALRequest;
  var AResponse: TRALResponse);
begin
  AResponse.ContentType := 'text/plain';
  AResponse.ResponseText := 'pong';
  case ARequest.Method of
    amGET, amDELETE:
      AResponse.RespCode := 200;
    amPOST, amPUT, amPATCH:
      AResponse.RespCode := 201;
  end;
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  ListView1.Clear;
  for I := 0 to pred(Server.Routes.Count) do
    ListView1.Items.Add.Caption := TRALRoute(Server.Routes.Items[I]).RouteName;
end;

procedure TfPrincipal.Log(Sender: TObject; ARequest: TRALRequest;
  var AResponse: TRALResponse);
var
  response: string;
begin
  response := AResponse.ResponseText;
  TThread.Queue(nil,
    procedure
    begin
      Memo2.Lines.Append('REQUEST: ' + ARequest.Query);
      Memo2.Lines.Append('RESPONSE: ' + response);
    end);
end;

procedure TfPrincipal.ping(Sender: TObject; ARequest: TRALRequest;
var AResponse: TRALResponse);
begin
  // No http verb is checked here, so it'll answer the same to any incomming
  // This is a simple GET, POST, PUT, PATCH, DELETE request against /ping endpoint
  // which results in a 'pong' response
  AResponse.ResponseText := 'pong';
end;

procedure TfPrincipal.ToggleSwitch1Click(Sender: TObject);
begin
  Server.Active := ToggleSwitch1.State = tssOn;
  if Server.Active then
    lServerPath.Caption := 'http://localhost:' + Server.Port.ToString
  else
    lServerPath.Caption := 'Offline';
end;

end.
