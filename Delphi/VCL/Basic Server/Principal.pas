unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,

  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.WinXCtrls,
  Vcl.ComCtrls, Vcl.Mask, Vcl.ExtCtrls,

  RALServer, RALRoutes, RALRequest, RALResponse, RALParams, RALIndyServer, RALTypes,
  RALConsts, RALMIMETypes

    ;

type
  TfPrincipal = class(TForm)
    ToggleSwitch1: TToggleSwitch;
    Memo2: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    ListView1: TListView;
    lServerPath: TLabel;
    Server: TRALIndyServer;
    lePort: TLabeledEdit;
    procedure Clientes(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure ping(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
    procedure test(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
    procedure multiroute(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
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
  vParam := ARequest.Params.ParamByName['nome'];
  if vParam <> nil then
    nome := vParam.AsString;

  AResponse.ResponseText := nome;
end;

procedure TfPrincipal.test(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // This is one way to answer, where you can set individually the data on the parameters
  // or you can use AResponse.Answer(statuscode, text, contenttype) to do the same thing
  AResponse.ContentType := 'text/plain';
  AResponse.ResponseText := 'pong';
  case ARequest.Method of
    amGET, amDELETE:
      AResponse.StatusCode := 200;
    amPOST, amPUT, amPATCH:
      AResponse.StatusCode := 201;
  end;
end;

procedure TfPrincipal.CreateRoutes;
begin
  // short way of creating routes
  Server.CreateRoute('test', test);
  Server.CreateRoute('clientes', Clientes);
  Server.CreateRoute('ping', ping);

  // example of a complex route
  Server.CreateRoute('this/is/a/very/long/route/example', multiroute);
end;

procedure TfPrincipal.FormCreate(Sender: TObject);
begin
  //
end;

procedure TfPrincipal.multiroute(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'hello long route name', rctTEXTPLAIN);
end;

procedure TfPrincipal.ping(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // No http verb is checked here, so it'll answer the same to any incomming
  // This is a simple GET, POST, PUT, PATCH, DELETE request against /ping endpoint
  // which results in a plain 'pong' response
  AResponse.Answer(200, 'pong', rctTEXTPLAIN);
end;

procedure TfPrincipal.ServerRequest(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // Memo2.Lines.Append('REQUEST: ' + ARequest.Query);
end;

procedure TfPrincipal.ServerResponse(Sender: TObject; ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // Memo2.Lines.Append('RESPONSE: ' + AResponse.ResponseText);
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

  // Simple way to have a list of available routes in runtime GUI
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
