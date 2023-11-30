unit Principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo, FMX.ListView, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  RALTypes,
  RALServer, RALIndyServer, RALCustomObjects, RALRequest, RALResponse;

type
  TForm1 = class(TForm)
    RALIndyServer1: TRALIndyServer;
    Edit1: TEdit;
    Label1: TLabel;
    Switch1: TSwitch;
    lServerInfo: TLabel;
    ListView1: TListView;
    Memo1: TMemo;
    procedure RALIndyServer1Routes_pingReply(ARequest: TRALRequest;
      AResponse: TRALResponse);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.RALIndyServer1Routes_pingReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'pong');
end;

end.
