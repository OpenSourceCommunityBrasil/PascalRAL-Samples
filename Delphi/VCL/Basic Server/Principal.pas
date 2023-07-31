unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.WinXCtrls, RALServer, RALRoutes, RALRequest, RALResponse,
  RALParams, RALIndyServer, RALTypes, RALAuthentication, RALConsts,
  Vcl.ComCtrls, Vcl.Mask, Vcl.ExtCtrls;

type
  TfPrincipal = class(TForm)
    ToggleSwitch1: TToggleSwitch;
    RALBasicAuth: TRALServerBasicAuth;
    Memo2: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    ListView1: TListView;
    lServerPath: TLabel;
    Server: TRALIndyServer;
    lePort: TLabeledEdit;
    procedure Clientes(Sender: TObject; ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure ping(Sender: TObject; ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure test(Sender: TObject; ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure FormCreate(Sender: TObject);
    procedure ServerRequest(Sender: TObject; ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure ServerResponse(Sender: TObject; ARequest: TRALRequest;
      AResponse: TRALResponse);
  private
    { Private declarations }
    procedure CreateRoutes;
    procedure SetupServer;
  public
    { Public declarations }
  end;

var
  fPrincipal: TfPrincipal;

implementation

{$R *.dfm}

procedure TfPrincipal.Clientes(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
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
  AResponse: TRALResponse);
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

procedure TfPrincipal.CreateRoutes;
begin
  Server.CreateRoute('test', test);
  Server.CreateRoute('clientes', Clientes);
  Server.CreateRoute('ping', ping);
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  //
end;

procedure TfPrincipal.ping(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // No http verb is checked here, so it'll answer the same to any incomming
  // This is a simple GET, POST, PUT, PATCH, DELETE request against /ping endpoint
  // which results in a 'pong' response
  AResponse.ResponseText := 'pong';
end;

procedure TfPrincipal.ServerRequest(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // TThread.Queue(nil,
  // procedure
  // begin
  // Memo2.Lines.Append('REQUEST: ' + ARequest.Query);
  // end);
end;

procedure TfPrincipal.ServerResponse(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // Memo2.Lines.Append('RESPONSE: ' + AResponse.ResponseText);
  // TThread.Queue(nil,
  // procedure
  // begin
  // Memo2.Lines.Append('RESPONSE: ' + AResponse.ResponseText);
  // end);
end;

procedure TfPrincipal.SetupServer;
var
  I: Integer;
begin
  // setting the events here via code to allow quick update of the examples
  Server.Port := StrToIntDef(lePort.Text, 0);
  Server.OnRequest := ServerRequest;
  Server.OnResponse := ServerResponse;
  CreateRoutes;

  ListView1.Clear;
  for I := 0 to pred(Server.Routes.Count) do
    ListView1.Items.Add.Caption := TRALRoute(Server.Routes.Items[I]).RouteName;

  Server.Active := true;
end;

procedure TfPrincipal.ToggleSwitch1Click(Sender: TObject);
begin
  if ToggleSwitch1.State = tssOn then
  begin
    SetupServer;
    lServerPath.Caption := 'http://localhost:' + Server.Port.ToString
  end
  else
  begin
    Server.Active := False;
    lServerPath.Caption := 'Offline';
  end;
end;

end.
