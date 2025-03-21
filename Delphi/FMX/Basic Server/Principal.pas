unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.ListView, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,

  RALTypes, RALConsts,
  RALServer, RALIndyServer, RALCustomObjects, RALRequest, RALResponse;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Switch1: TSwitch;
    lServerInfo: TLabel;
    Memo1: TMemo;
    RALIndyServer1: TRALIndyServer;
    Label2: TLabel;
    Memo2: TMemo;
    procedure RALIndyServer1Routes_pingReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
    procedure Switch1Switch(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // stop the server before killing the application to prevent socket errors
  RALIndyServer1.Stop;
end;

procedure TForm1.RALIndyServer1Routes_pingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  // HTTP_OK is a constant on RALConsts
  // This is a minimal example on how to reply a request with a simple text/plain
  AResponse.Answer(HTTP_OK, 'pong');
end;

procedure TForm1.Switch1Switch(Sender: TObject);
begin
  // Change activation state of the server based on the TSwitch state
  RALIndyServer1.Active := Switch1.IsChecked;
  // you can also use RALServer.Start; or RALServer.Stop; methods to start/stop
  // the server.

  // List all routes of the server on Memo2
  if Switch1.IsChecked then
    Memo2.Lines.Text := RALIndyServer1.Routes.AsString;
end;

end.
