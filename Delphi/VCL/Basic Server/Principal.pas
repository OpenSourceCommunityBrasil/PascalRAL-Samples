unit Principal;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.WinXCtrls,
  RALServer, RALRoutes,  RALIndyServer, RALTypes;

type
  TfPrincipal = class(TForm)
    Server: TRALIndyServer;
    ToggleSwitch1: TToggleSwitch;
    procedure poolerrclientesReply(Sender: TObject; ARequest: TRALRequest;
      var AResponse: TRALResponse);
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure ping(Sender: TObject; ARequest: TRALRequest;
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

procedure TfPrincipal.poolerrclientesReply(Sender: TObject; ARequest: TRALRequest;
  var AResponse: TRALResponse);
var
  nome : string;
  vParam : TRALParam;
begin
  nome := 'erro';
  vParam := ARequest.Params.ParamName['nome'];
  if vParam <> nil then
    nome := vParam.AsString;

  AResponse.ResponseText := nome;
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
end;

end.
